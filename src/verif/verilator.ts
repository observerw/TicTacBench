import { useWorkDir } from "@/utils/fs.ts";
import { RelPath } from "@/utils/zod.ts";
import { copy } from "@std/fs";
import { resolve } from "@std/path";
import { tool } from "ai";
import { z } from "zod";
import { $ } from "zx";

export const verilatorInputSchema = z.object({
  verilogFiles: z.array(RelPath).describe(
    "Verilog source file path list relative to cwd.",
  ),
  top: z.string().describe("Name of the top-level module to lint."),
  extraArgs: z
    .array(z.string())
    .optional()
    .default(["--Wall"])
    .describe(
      "Additional verilator arguments passed through as-is, for example ['-Wno-UNUSEDSIGNAL'].",
    ),
});
export type VerilatorInput = z.infer<typeof verilatorInputSchema>;

export const verilatorOutputSchema = z.object({
  success: z.boolean().describe("Whether verilator lint succeeded."),
  stdout: z.string().describe("Standard output from the verilator invocation."),
  stderr: z.string().describe("Standard error from the verilator invocation."),
});
export type VerilatorOutput = z.infer<typeof verilatorOutputSchema>;

export const createVerilator = ({ cwd }: { cwd: string }) =>
async (
  { top, verilogFiles, extraArgs }: VerilatorInput,
): Promise<VerilatorOutput> => {
  await using workDirResource = await useWorkDir();
  const workDir = workDirResource.path;

  await Promise.all(
    verilogFiles.map((filePath) =>
      copy(resolve(cwd, filePath), resolve(workDir, filePath))
    ),
  );

  const output = await $({ cwd: workDir })`
    verilator --lint-only ${extraArgs} --top-module ${top} ${verilogFiles}
  `.nothrow();

  return {
    success: output.exitCode === 0,
    stdout: output.stdout.trim(),
    stderr: output.stderr.trim(),
  };
};

export const createVerilatorTool = ({ sandboxDir }: { sandboxDir: string }) =>
  tool({
    description:
      `Run \`verilator --lint-only\` on given Verilog files, return pass/fail plus lint output.

      Note that the working directory will be cleaned up after execution. DO NOT try to read run logs in /tmp.`,
    inputSchema: verilatorInputSchema,
    outputSchema: verilatorOutputSchema,
    execute: createVerilator({ cwd: sandboxDir }),
  });
