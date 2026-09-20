import env from "@/env.ts";
import pino from "pino";
import pretty from "pino-pretty";

const transport = pino.multistream([
  {
    stream: pretty({
      colorize: true,
      translateTime: "SYS:standard",
      ignore: "pid,hostname",
    }),
    level: env.LOG_LEVEL,
  },
  {
    stream: pino.destination({
      dest: "logs/timing-bench.log",
      mkdir: true,
      sync: false,
    }),
    level: env.LOG_LEVEL,
  },
]);

export const logger = pino({ level: env.LOG_LEVEL }, transport);
export type Logger = pino.Logger;
