import { configSchema as StaConfigSchema } from "@/librelane/config.ts";
import {
  parseMetricsJson,
  PostPnRMetricsOutputOnlySchema,
  PostPnRMetricsSchema,
  PrePnRMetricsOutputOnlySchema,
  PrePnRMetricsSchema,
} from "@/librelane/metric.ts";
import { createPrePnRSTAtool, createSTA, STA_DIR } from "@/librelane/mod.ts";
import { CoWCopy, ensureEmptyDir } from "@/utils/fs.ts";
import { sha } from "@/utils/hash.ts";
import { logger } from "@/utils/logger.ts";
import { createEqy } from "@/verif/eqy.ts";
import { createIverilog } from "@/verif/iverilog.ts";
import {
  createEqyTool,
  createIverilogTool,
  createVerilatorTool,
} from "@/verif/mod.ts";
import { webSearch } from "@exalabs/ai-sdk";
import { exists } from "@std/fs";
import { join, resolve } from "@std/path";
import {
  type ModelMessage,
  OnStepFinishEvent,
  stepCountIs,
  Tool,
  tool,
  ToolLoopAgent,
  UserModelMessage,
} from "ai";
import {
  createBashTool,
  experimental_createSkillTool as createSkillTool,
} from "bash-tool";
import { Bash, InMemoryFs, MountableFs, ReadWriteFs } from "just-bash";
import z from "zod";
import { models, providers } from "./model.ts";
import bashPrompt from "./templates/BASH.md" with { type: "text" };
import taskPrompt from "./templates/TASK.md" with { type: "text" };

export const ExpConfigSchema = z.object({
  task: z.string(),
  model: z.enum(models),
  enableWebSearch: z.boolean().optional(),
  enableSkill: z.boolean().optional(),
});
export type ExpConfig = z.infer<typeof ExpConfigSchema>;

export const StageMetricsSchema = z.object({
  pre: PrePnRMetricsOutputOnlySchema,
  post: PostPnRMetricsOutputOnlySchema,
});
export type StageMetrics = z.infer<typeof StageMetricsSchema>;

export const ExpResultSchema = z.object({
  expConfig: ExpConfigSchema,
  success: z.boolean(),
  reason: z.string().nullable(),
  elapsedSeconds: z.number().nonnegative().default(0),
  suboptimal: StageMetricsSchema,
  optimized: StageMetricsSchema,
  staConfig: StaConfigSchema,
});
export type ExpResult = z.infer<typeof ExpResultSchema>;

export type RunConfig = Readonly<{
  tasksDir: string;
  runsDir: string;
  skillsDir?: string;
  override?: boolean;
}>;

const MAX_TURN = 3;
const MAX_STEPS = 256;
const MAX_STA_CALL = 10;
const MAX_RETRIES = 3;
const AGENT_TIMEOUT_MS = 2 * 60 * 60 * 1000;
const SANDBOX_WORKDIR = "/home/user/project";
const SUBOPTIMAL_EXTENSIONS = [".v", ".sv"] as const;
const DEFAULT_SKILLS_DIR = join(Deno.cwd(), "skills");

const extractStep = ({
  stepNumber,
  content,
  reasoning,
  usage,
}: // deno-lint-ignore no-explicit-any
  OnStepFinishEvent<any>) => ({
    stepNumber,
    content,
    reasoning,
    usage,
  });
export type Step = ReturnType<typeof extractStep>;

const detectSuboptimalFile = async (taskDir: string): Promise<string> => {
  for (const ext of SUBOPTIMAL_EXTENSIONS) {
    const file = `suboptimal${ext}`;
    if (await exists(resolve(taskDir, file))) {
      return file;
    }
  }

  throw new Error(
    `Expected one of ${
      SUBOPTIMAL_EXTENSIONS.map((ext) => `suboptimal${ext}`).join(", ")
    } in task directory: ${taskDir}`,
  );
};

class RunState {
  public turn = 0;
  public finishReason: string | null = null;

  get maxTurnExceeded() {
    return this.turn >= MAX_TURN;
  }

  get shouldStop() {
    return this.finishReason || this.maxTurnExceeded;
  }
}

export const run = async ({
  expConfig,
  runConfig: { tasksDir, runsDir, skillsDir, override = true },
}: {
  expConfig: ExpConfig;
  runConfig: RunConfig;
}): Promise<ExpResult> => {
  const startTime = performance.now();
  const { task, model, enableWebSearch = false, enableSkill = false } =
    expConfig;
  const taskDir = resolve(tasksDir, task);
  const suboptimalFile = await detectSuboptimalFile(taskDir);

  const expConfigJson = JSON.stringify(expConfig);
  const expHash = await sha(expConfigJson);

  const log = logger.child({ task, model, expHash });

  const wsDir = resolve(runsDir, expHash);
  const resultFile = resolve(wsDir, "result.json");
  const resultExists = await exists(resultFile);

  log.info({ wsDir }, "Experiment workspace directory");

  if (!override && resultExists) {
    log.info(
      "Completed experiment already exists and override is false. Skipping experiment run.",
    );
    const json = await Deno.readTextFile(resultFile);
    return ExpResultSchema.parse(JSON.parse(json));
  }

  if (resultExists) {
    log.info(
      "Experiment result already exists but override is true. The existing result will be overwritten.",
    );
  }

  await ensureEmptyDir({ dir: wsDir, force: true });

  await Promise.all([
    CoWCopy({
      source: resolve(taskDir, "sta"),
      target: resolve(wsDir, "sta"),
    }),
    CoWCopy({
      source: resolve(taskDir, suboptimalFile),
      target: resolve(wsDir, suboptimalFile),
    }),
  ]);

  const hostFs = new ReadWriteFs({ root: wsDir });
  const sandboxFs = new MountableFs({
    base: new InMemoryFs(),
    mounts: [{ mountPoint: SANDBOX_WORKDIR, filesystem: hostFs }],
  });
  const sandbox = new Bash({
    fs: sandboxFs,
    cwd: SANDBOX_WORKDIR,
    python: false,
    javascript: true,
    // just-bash's defense-in-depth monkey patches assume a patchable Node runtime.
    // Under Deno's npm compatibility layer, critical patches like Module._load fail
    // and abort startup, so we disable that secondary layer here.
    defenseInDepth: false,
  });

  const trajectoryPath = resolve(wsDir, "trajectory.jsonl");

  if (!skillsDir) {
    if (enableSkill) {
      throw new Error(
        "Skills directory must be provided when enableSkill is true. Please provide a valid skillsDir in the runConfig.",
      );
    } else {
      // necessary basic skills
      skillsDir = DEFAULT_SKILLS_DIR;
    }
  }
  const {
    skill: skillTool,
    files,
    instructions: skillsInstructions,
  } = await createSkillTool({
    skillsDirectory: resolve(skillsDir),
    destination: join(".agents", "skills"),
  });
  const {
    tools: {
      bash: bashTool,
      writeFile,
      // DO NOT use it since it always read full content and may blow up context
      // readFile,
    },
  } = await createBashTool({
    sandbox,
    destination: SANDBOX_WORKDIR,
    files,
    promptOptions: {
      toolPrompt: bashPrompt,
    },
    extraInstructions: skillsInstructions,
  });

  const iverilogTool = createIverilogTool({ sandboxDir: wsDir });
  const verilatorTool = createVerilatorTool({ sandboxDir: wsDir });
  const runIverilog = createIverilog({ cwd: wsDir });

  const eqyTool = createEqyTool({
    sandboxDir: wsDir,
    eqyDir: resolve(taskDir, "verif"),
  });
  const runEqy = createEqy({
    cwd: wsDir,
    eqyDir: resolve(taskDir, "verif"),
  });

  const preSTATool = createPrePnRSTAtool({
    sandboxDir: wsDir,
    staDir: resolve(taskDir, "sta"),
    maxCall: MAX_STA_CALL,
  });
  const runPreSTA = createSTA({
    cwd: wsDir,
    staDir: resolve(taskDir, "sta"),
    stage: "Pre",
  });
  const runPostSTA = createSTA({
    cwd: wsDir,
    staDir: resolve(taskDir, "sta"),
    stage: "Post",
  });

  const state = new RunState();

  const finishTool = tool({
    description:
      "Call this tool when the task is complete and you are ready to stop. Do not end with a normal assistant message alone: you must call `finish` exactly once after writing the final `optimized.v`. The message should be a concise summary of the results and findings from the experiment.",
    inputSchema: z.object({
      reason: z.string().describe(
        "A concise summary of the experiment results and findings.",
      ),
    }),
    outputSchema: z.object({
      message: z
        .string()
        .describe(
          "A message explaining the acceptance or rejection of the finish request.",
        ),
    }),
    execute: async ({ reason }) => {
      const [compile, equiv] = await Promise.all([
        runIverilog({
          verilogFiles: ["optimized.v"],
          top: `${task}_optimized`,
          extraArgs: ["-g2012"],
        }),
        runEqy({
          subOptimalFile: suboptimalFile,
          optimizedFile: "optimized.v",
        }),
      ]);

      if (compile.success && equiv.equivalent) {
        state.finishReason = reason;
        log.info({ reason }, "Experiment marked finished");
        return {
          message:
            "Finish accepted. Compile and equivalence checks both passed.",
        };
      }

      throw new Error(
        `Finish rejected. Compile success: ${compile.success}, Equivalence: ${equiv.equivalent}. Please ensure that optimized.v compiles successfully and is functionally equivalent to ${suboptimalFile} before calling finish.`,
      );
    },
  });

  const tools: Record<string, Tool> = {
    bash: bashTool,
    write: writeFile,
    iverilog: iverilogTool,
    verilator: verilatorTool,
    equiv: eqyTool,
    sta: preSTATool,
    skill: skillTool,
    finish: finishTool,
  };

  if (enableWebSearch) {
    tools.web = webSearch();
  }

  const agent = new ToolLoopAgent({
    model: providers[model],
    tools,
    maxRetries: MAX_RETRIES,
    stopWhen: stepCountIs(MAX_STEPS),
    providerOptions: {
      openai: {
        reasoningEffort: "high",
      },
    },
  });

  const encoder = new TextEncoder();

  let prompt = taskPrompt;
  const extraTaskFile = resolve(taskDir, "TASK.md");
  if (await exists(extraTaskFile)) {
    const extraPrompt = await Deno.readTextFile(extraTaskFile);
    prompt += `\n\n## Extra Task Requirements\n\n${extraPrompt}`;
  }

  const messages: ModelMessage[] = [
    {
      role: "user",
      content: prompt,
    } satisfies UserModelMessage,
  ];
  log.info(
    { maxTurn: MAX_TURN, staMaxCall: MAX_STA_CALL },
    "Agent loop starting",
  );
  while (!state.shouldStop) {
    log.info({ turn: state.turn + 1 }, "Agent turn starting");
    const result = await agent.generate({
      messages,
      timeout: AGENT_TIMEOUT_MS,
      onStepFinish: (event) => {
        const step = extractStep(event);
        Deno.writeFileSync(
          trajectoryPath,
          encoder.encode(JSON.stringify(step) + "\n"),
          { append: true },
        );
      },
    });
    messages.push(...result.response.messages);
    state.turn += 1;

    log.info(
      {
        turn: state.turn,
        finished: !!state.finishReason,
      },
      "Agent turn completed",
    );
  }

  if (state.finishReason) {
    log.info(
      { reason: state.finishReason },
      "Experiment finished after tool acceptance checks",
    );
  } else {
    log.warn("Experiment reached max turns without passing acceptance");
  }

  if (!(await exists(resolve(wsDir, "optimized.v")))) {
    log.error(
      "optimized.v not found in workspace. Cannot proceed with metrics parsing.",
    );
    throw new Error("optimized.v not found");
  }

  const [suboptimalPreMetrics, suboptimalPostMetrics] = await Promise.all([
    parseMetricsJson(
      resolve(wsDir, "sta", STA_DIR, task, "Pre", "final", "metrics.json"),
    ),
    parseMetricsJson(
      resolve(wsDir, "sta", STA_DIR, task, "Post", "final", "metrics.json"),
    ),
  ]);
  const [suboptimalPre, suboptimalPost] = await Promise.all([
    PrePnRMetricsSchema.parseAsync(suboptimalPreMetrics),
    PostPnRMetricsSchema.parseAsync(suboptimalPostMetrics),
  ]);

  const optTop = `${task}_optimized`;
  await Promise.all([
    runPreSTA({ verilogFiles: ["optimized.v"], top: optTop }),
    runPostSTA({ verilogFiles: ["optimized.v"], top: optTop }),
  ]);
  const [optimizedPreMetrics, optimizedPostMetrics] = await Promise.all([
    parseMetricsJson(
      resolve(wsDir, STA_DIR, optTop, "Pre", "final", "metrics.json"),
    ),
    parseMetricsJson(
      resolve(wsDir, STA_DIR, optTop, "Post", "final", "metrics.json"),
    ),
  ]);
  const [optimizedPre, optimizedPost] = await Promise.all([
    PrePnRMetricsSchema.parseAsync(optimizedPreMetrics),
    PostPnRMetricsSchema.parseAsync(optimizedPostMetrics),
  ]);

  const staConfig = StaConfigSchema.parse(
    JSON.parse(
      await Deno.readTextFile(resolve(taskDir, "sta", "config.default.json")),
    ),
  );

  const result = {
    expConfig,
    success: !!state.finishReason,
    reason: state.finishReason,
    elapsedSeconds: (performance.now() - startTime) / 1000,
    staConfig,
    suboptimal: {
      pre: suboptimalPre,
      post: suboptimalPost,
    },
    optimized: {
      pre: optimizedPre,
      post: optimizedPost,
    },
  } satisfies ExpResult;

  const resultJson = JSON.stringify(result, null, 2);
  await Deno.writeTextFile(resultFile, resultJson);

  log.info({ wsDir, result }, "Experiment run finished");
  return result;
};
