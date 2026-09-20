import { run } from "@/experiment/mod.ts";
import { pooledMap } from "@std/async";

const tasksDir = "dataset";
const concurrency = 10;

const entries = await Array.fromAsync(Deno.readDir(tasksDir));
const tasks = entries.filter((entry) => entry.isDirectory).map((entry) =>
  entry.name
);

const models = [
  "gpt-5.4",
  // TODO add your models here
] as const;

await Promise.all(
  models.map((model) => {
    return Array.fromAsync(
      pooledMap(concurrency, tasks, (task) =>
        run({
          expConfig: { task, model, enableSkill: true },
          runConfig: {
            tasksDir,
            runsDir: "runs",
            skillsDir: "skills",
            override: false,
          },
        }).catch((err) => {
          console.error(`Error running task ${task} with model ${model}:`, err);
        })),
    );
  }),
);
