import { encodeHex } from "@std/encoding/hex";

export const sha = async (text: string) => {
  const digest = await crypto.subtle.digest(
    "SHA-1",
    new TextEncoder().encode(text),
  );
  return encodeHex(new Uint8Array(digest));
};
