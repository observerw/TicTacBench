import { useWorkDir } from "@/utils/fs.ts";
import { RelPath } from "@/utils/zod.ts";
import { copy } from "@std/fs";
import { resolve } from "@std/path";
import { tool } from "ai";
import { z } from "zod";
import { $ } from "zx";

export const iverilogInputSchema = z.object({
  verilogFiles: z.array(RelPath).describe(
    "Verilog source file path list relative to cwd.",
  ),
  top: z.string().describe("Name of the top-level module to compile."),
  extraArgs: z
    .array(z.string())
    .optional()
    .default(["-g2012"])
    .describe(
      "Additional iverilog arguments passed through as-is, for example ['-Wall'].",
    ),
});
export type IverilogInput = z.infer<typeof iverilogInputSchema>;

export const iverilogOutputSchema = z.object({
  success: z.boolean().describe("Whether iverilog compilation succeeded."),
  stdout: z.string().describe("Standard output from the iverilog invocation."),
  stderr: z.string().describe("Standard error from the iverilog invocation."),
});
export type IverilogOutput = z.infer<typeof iverilogOutputSchema>;

export const createIverilog = ({ cwd }: { cwd: string }) =>
async (
  { top, verilogFiles, extraArgs }: IverilogInput,
): Promise<IverilogOutput> => {
  await using workDirResource = await useWorkDir();
  const workDir = workDirResource.path;

  await Promise.all(
    verilogFiles.map((filePath) =>
      copy(resolve(cwd, filePath), resolve(workDir, filePath))
    ),
  );

  const output = await $({ cwd: workDir })`
    iverilog ${extraArgs} -s ${top} -o a.out ${verilogFiles}
  `.nothrow();

  return {
    success: output.exitCode === 0,
    stdout: output.stdout.trim(),
    stderr: output.stderr.trim(),
  };
};

export const createIverilogTool = ({ sandboxDir }: { sandboxDir: string }) =>
  tool({
    description:
      `Run iverilog on given Verilog files, return pass/fail plus compiler output.

      Note that the working directory will be cleaned up after execution. DO NOT try to read run logs or run vvp in /tmp.`,
    inputSchema: iverilogInputSchema,
    outputSchema: iverilogOutputSchema,
    execute: createIverilog({ cwd: sandboxDir }),
  });
