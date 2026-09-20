import { Config } from "@/librelane/config.ts";
import { parseMetricsJson, STAMetricsSchema } from "@/librelane/metric.ts";
import { CoWCopy, ensureEmptyDir, remove, useWorkDir } from "@/utils/fs.ts";
import { RelPath } from "@/utils/zod.ts";
import { ensureDir, exists, move } from "@std/fs";
import { dirname, resolve } from "@std/path";
import { tool } from "ai";
import z from "zod";
import { $ } from "zx";

export type STAStage = "Pre" | "Post";
export const STA_DIR = "librelane-sta";

export const STAInputSchema = z.object({
  verilogFiles: z
    .array(RelPath)
    .nonempty("At least one Verilog source file is required.")
    .describe(
      "List of Verilog source file paths for the design, relative to cwd.",
    ),
  top: z.string().describe("Name of the top-level module in the design."),
  clockPeriod: z.number().positive().optional().describe(
    "Clock period constraint in nanoseconds for the STA. Will override `CLOCK_PERIOD` in config.default.json if provided.",
  ),
  runDir: RelPath.optional().describe(
    "Path to the directory where the STA run outputs will be stored, relative to cwd. Defaults to `librelane-sta/` if not provided.",
  ),
});
export type STAInput = z.infer<typeof STAInputSchema>;

export const STAOutputSchema = z.object({
  runDir: RelPath.describe(
    "Path to the directory where the STA run outputs are stored, relative to cwd.",
  ),
  metrics: STAMetricsSchema.describe("STA metrics."),
});
export type STAOutput = z.infer<typeof STAOutputSchema>;

export const createSTA = (
  { cwd, staDir, stage }: {
    cwd: string;
    staDir: string;
    stage: STAStage;
  },
) =>
async ({
  verilogFiles,
  top,
  clockPeriod,
  runDir = STA_DIR,
}: STAInput): Promise<STAOutput> => {
  await using workDirResource = await useWorkDir({ dir: staDir });
  const workDir = workDirResource.path;

  await Promise.all(
    verilogFiles.map((file) =>
      CoWCopy({
        source: resolve(cwd, file),
        target: resolve(workDir, file),
      })
    ),
  );

  const defaultConfig = JSON.parse(
    await Deno.readTextFile(resolve(workDir, "config.default.json")),
  ) as Partial<Config>;
  const config: Config = {
    ...defaultConfig,
    DESIGN_NAME: top,
    VERILOG_FILES: verilogFiles.map((file) => `dir::${file}`),
  };

  if (clockPeriod) {
    // override default clock period
    config.CLOCK_PERIOD = clockPeriod;
  }

  if (stage === "Pre") {
    // over constrain clock uncertainty for pre
    config.CLOCK_UNCERTAINTY_CONSTRAINT = 0.25;
  }
  if (stage === "Post") {
    config.CLOCK_UNCERTAINTY_CONSTRAINT = 0;
    // speedup post-PnR STA by restrict the number of DRT iterations
    config.DRT_OPT_ITERS = 8;
    // use pnr sdc as signoff sdc
    config.SIGNOFF_SDC_FILE = config.PNR_SDC_FILE;
  }

  await Deno.writeTextFile(
    resolve(workDir, "config.json"),
    JSON.stringify(config),
  );

  const stageRunDir = resolve(workDir, STA_DIR, top, stage);
  await ensureEmptyDir({ dir: stageRunDir, force: true });
  const output = await $({ cwd: workDir })`
    uvx librelane \
      --container-no-tty \
      --containerized \
      --to OpenROAD.STA${stage}PNR \
      --design-dir . \
      --force-run-dir ${stageRunDir} \
      config.json
  `.nothrow();

  const stageMetricsFile = resolve(stageRunDir, "final", "metrics.json");
  if (output.exitCode !== 0 && !(await exists(stageMetricsFile))) {
    throw output;
  }

  const cwdStageRunDir = resolve(cwd, runDir, top, stage);
  await ensureDir(dirname(cwdStageRunDir));
  await remove(cwdStageRunDir);
  await move(stageRunDir, cwdStageRunDir);

  const metrics = STAMetricsSchema.parse(
    await parseMetricsJson(
      resolve(cwdStageRunDir, "final", "metrics.json"),
    ),
  );
  await Deno.writeTextFile(
    resolve(cwdStageRunDir, "metrics.json"),
    JSON.stringify(metrics),
  );

  return { runDir: stageRunDir, metrics };
};

export const createPrePnRSTAtool = (
  {
    sandboxDir,
    staDir,
    maxCall,
  }: { sandboxDir: string; staDir: string; maxCall?: number },
) => {
  let callCount = 0;

  let description =
    `Runs the pre-PnR STA on given design files and outputs the STA metrics. Note that this is NOT post-PnR STA (you can't do it by yourself).
    
    - You MUST clear all verilator lint warnings before running this tool.
    - Pre-PnR STA is more optimistic and may require over-constraining to reflect the post-PnR STA metrics.`;

  if (maxCall) {
    description +=
      ` This tool may be called AT MOST ${maxCall} TIMES. Exceeding calls will not execute.`;
  }

  const runSTA = createSTA({ cwd: sandboxDir, staDir, stage: "Pre" });

  return tool({
    inputSchema: STAInputSchema,
    outputSchema: STAOutputSchema,
    description,
    execute: async (input) => {
      if (maxCall && callCount >= maxCall) {
        throw new Error(
          `pre-PnR STA tool call limit exceeded. No more STA runs are allowed. (maxCall: ${maxCall})`,
        );
      }

      callCount += 1;
      return await runSTA(input);
    },
  });
};
