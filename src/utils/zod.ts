import { isAbsolute } from "@std/path";
import { z } from "zod";

export const RelPath = z.string().refine((path) => !isAbsolute(path), {
  message: "Expected a relative POSIX path",
});
export type RelPath = z.infer<typeof RelPath>;
