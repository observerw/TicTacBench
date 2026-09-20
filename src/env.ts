import { z } from "zod";

const envValue = z.string().trim().min(1);

export const envSchema = z.object({
  OPENAI_API_KEY: envValue,
  OPENAI_BASE_URL: envValue,
  OPENAI_CHAT_API_KEY: envValue,
  OPENAI_CHAT_BASE_URL: envValue,
  ANTHROPIC_API_KEY: envValue,
  ANTHROPIC_BASE_URL: envValue,
  DEEPSEEK_API_KEY: envValue,
  DEEPSEEK_BASE_URL: envValue,
  LOG_LEVEL: z.string().trim().default("info"),
});
export type Env = z.infer<typeof envSchema>;

const env = envSchema.parse(Deno.env.toObject());

export default env;
