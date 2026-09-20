import { ensureDir, exists } from "@std/fs";
import { basename } from "@std/path";
import { $ } from "zx";

const randomWorkDirPrefix = (base: string) =>
  `${base}.${crypto.randomUUID().replaceAll("-", "")}.`;

export const ensureEmptyDir = async (
  { dir, force }: { dir: string; force?: boolean },
) => {
  if (await exists(dir)) {
    if (force) {
      await remove(dir);
    } else {
      throw new Error(`Directory already exists: ${dir}`);
    }
  }
  await ensureDir(dir);
};

export type PathResource = {
  path: string;
} & AsyncDisposable;

export const CoWCopy = ({
  source,
  target,
}: {
  source: string;
  target: string;
}) => $`cp -a --reflink=auto ${source} ${target}`;

export const useCoWCopy = async ({
  source,
  target,
}: {
  source: string;
  target: string;
}): Promise<PathResource> => {
  await CoWCopy({ source, target });

  return {
    path: target,
    [Symbol.asyncDispose]: async () => {
      await remove(target);
    },
  };
};

export const useWorkDir = async ({
  dir,
}: {
  dir?: string;
} = {}): Promise<PathResource> => {
  if (!dir) {
    const workDir = await Deno.makeTempDir({
      prefix: randomWorkDirPrefix("timing-bench"),
    });
    return {
      path: workDir,
      [Symbol.asyncDispose]: async () => {
        await remove(workDir);
      },
    };
  }

  const workDir = await Deno.makeTempDir({
    prefix: randomWorkDirPrefix(basename(dir)),
  });
  for await (const entry of Deno.readDir(dir)) {
    await CoWCopy({
      source: `${dir}/${entry.name}`,
      target: `${workDir}/${entry.name}`,
    });
  }

  return {
    path: workDir,
    [Symbol.asyncDispose]: async () => {
      await remove(workDir);
    },
  };
};

/**
 * Removes the file/directory at the given path. Silently ignores if path does not exist.
 */
export const remove = async (path: string) => {
  try {
    await Deno.remove(path, { recursive: true });
  } catch (err) {
    if (!(err instanceof Deno.errors.NotFound)) {
      throw err;
    }
  }
};
