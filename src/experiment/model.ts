import env from "@/env.ts";
import { createAnthropic } from "@ai-sdk/anthropic";
import { createDeepSeek } from "@ai-sdk/deepseek";
import { createOpenAI } from "@ai-sdk/openai";
import { LanguageModelV3 } from "@ai-sdk/provider";

const openai = createOpenAI({
  name: "OpenAI",
  apiKey: env.OPENAI_API_KEY,
  baseURL: env.OPENAI_BASE_URL,
});

const openaiChat = createOpenAI({
  apiKey: env.OPENAI_CHAT_API_KEY,
  baseURL: env.OPENAI_CHAT_BASE_URL,
});

const anthropic = createAnthropic({
  apiKey: env.ANTHROPIC_API_KEY,
  baseURL: env.ANTHROPIC_BASE_URL,
});

const deepseek = createDeepSeek({
  apiKey: env.DEEPSEEK_API_KEY,
  baseURL: env.DEEPSEEK_BASE_URL,
});

export const models = [
  "gpt-5.4",
  "claude-sonnet-4-6",
  "deepseek-v4-pro",
  "deepseek-v4-flash",
  "kimi-k2-6",
  "minimax-m2-7",
  "qwen3-5-122b-a10b",
  "glm-5-1-fp8",
] as const;
export type Model = (typeof models)[number];

export const providers: Record<Model, LanguageModelV3> = {
  "gpt-5.4": openai.chat("gpt-5.4"),
  // "gpt-5.4": codexCli("gpt-5.4"),
  "claude-sonnet-4-6": anthropic("claude-sonnet-4-6"),
  "deepseek-v4-pro": deepseek("deepseek-v4-pro"),
  "deepseek-v4-flash": deepseek("deepseek-v4-flash"),
  "kimi-k2-6": openaiChat.chat("kimi-k2-6"),
  "minimax-m2-7": openaiChat.chat("minimax-m2-7"),
  "qwen3-5-122b-a10b": openaiChat.chat("qwen3-5-122b-a10b"),
  "glm-5-1-fp8": openaiChat.chat("glm-5-1-fp8"),
} as const;
