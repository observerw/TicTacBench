import { CoWCopy, useWorkDir } from "@/utils/fs.ts";
import { RelPath } from "@/utils/zod.ts";
import { resolve } from "@std/path";
import { tool } from "ai";
import { z } from "zod";
import { $ } from "zx";

const EQY_TIMEOUT_S = 60;

export const eqyInputSchema = z.object({
  subOptimalFile: RelPath.describe(
    "Path to the sub-optimal design file relative to cwd.",
  ),
  optimizedFile: RelPath.describe(
    "Path to the optimized design file relative to cwd.",
  ),
});
export type EqyInput = z.infer<typeof eqyInputSchema>;

export const eqyOutputSchema = z.object({
  equivalent: z.boolean().describe(
    "Whether the given design passed the equivalence check.",
  ),
  stdout: z.string().describe("Standard output from the eqy run."),
  stderr: z.string().describe("Standard error from the eqy run."),
});
export type EqyOutput = z.infer<typeof eqyOutputSchema>;

export const createEqy = ({ cwd, eqyDir }: {
  cwd: string;
  eqyDir: string;
}) =>
async ({
  subOptimalFile,
  optimizedFile,
}: EqyInput): Promise<EqyOutput> => {
  await using workDirResource = await useWorkDir({ dir: eqyDir });
  const workDir = workDirResource.path;

  await Promise.all([
    CoWCopy({
      source: resolve(cwd, subOptimalFile),
      target: resolve(workDir, "suboptimal.v"),
    }),
    CoWCopy({
      source: resolve(cwd, optimizedFile),
      target: resolve(workDir, "optimized.v"),
    }),
  ]);

  const { stdout, stderr, exitCode } = await $({
    cwd: workDir,
    timeout: `${EQY_TIMEOUT_S}s`,
  })`sby -f config.sby`.nothrow();

  return {
    equivalent: exitCode === 0,
    stdout,
    stderr,
  };
};

export const createEqyTool = (
  { eqyDir, sandboxDir }: { eqyDir: string; sandboxDir: string },
) =>
  tool({
    description:
      `Runs equivalence checking for the given suboptimal and optimized Verilog file paths, and returns whether they are equivalent along with the standard output and error from the run. 
      
      Note that the working directory will be cleaned up after execution. DO NOT try to read from /tmp.`,
    inputSchema: eqyInputSchema,
    outputSchema: eqyOutputSchema,
    execute: createEqy({ eqyDir, cwd: sandboxDir }),
  });
