import { z } from "zod";

const filePathSchema = z.string().trim().min(1);
const identifierSchema = z
  .string()
  .trim()
  .regex(/^[_a-zA-Z][_a-zA-Z0-9]*$/);

const example = {
  DESIGN_NAME: "pm32",
  PDK: "sky130A",
  VERILOG_FILES: ["dir::pm32.v", "dir::spm.v"],
  CLOCK_PORT: "clk",
  CLOCK_PERIOD: 25,
  PNR_SDC_FILE: "dir::src/pnr.sdc",
  SIGNOFF_SDC_FILE: "dir::src/signoff.sdc",
} as const;

export const configSchema = z
  .object({
    DESIGN_NAME: identifierSchema.optional().describe(
      `Top module name. Example: ${example.DESIGN_NAME}`,
    ),
    VERILOG_FILES: z
      .array(filePathSchema)
      .optional()
      .describe(
        `RTL source file list. Use dir:: for paths relative to the provided designDir. Example: ${
          JSON.stringify(example.VERILOG_FILES)
        }`,
      ),
    PDK: identifierSchema.optional().describe(
      `PDK name. Example: ${example.PDK}`,
    ),
    CLOCK_PORT: z
      .string()
      .nullable()
      .optional()
      .describe(
        `Clock port name for LibreLane flow timing setup. Usually does not need to be repeated in the custom PNR SDC. Example: ${example.CLOCK_PORT}`,
      ),
    CLOCK_PERIOD: z
      .number()
      .positive()
      .optional()
      .describe(
        `Clock period in nanoseconds for LibreLane flow timing setup. Usually does not need to be repeated in the custom PNR SDC. Example: ${example.CLOCK_PERIOD}`,
      ),
    PNR_SDC_FILE: filePathSchema
      .optional()
      .describe(
        `Custom PNR SDC file for additional design-specific timing constraints. Use dir:: for paths relative to the provided designDir. Example: ${example.PNR_SDC_FILE}`,
      ),
  }).passthrough();

export type Config = z.infer<typeof configSchema>;
