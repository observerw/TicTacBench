import z from "zod";

const infinityStringSchema = z.union([
  z.literal("Infinity"),
  z.literal("-Infinity"),
]);
const slackSchema = z.union([
  z.number(),
  infinityStringSchema,
]);
const optionalSlackSchema = z.union([slackSchema, z.null()]);

const STAMetricsOutputSchema = z.object({
  setupWns: slackSchema.describe("Worst negative setup slack"),
  setupTns: slackSchema.describe("Total negative setup slack"),
  setupWs: slackSchema.describe("Worst setup slack"),
  setupViolations: z.number().int().nonnegative().describe(
    "Setup violation count",
  ),
  setupR2RWs: optionalSlackSchema.describe(
    "Worst register-to-register setup slack",
  ),
  setupR2RViolations: z
    .number()
    .int()
    .nonnegative()
    .describe("Register-to-register setup violation count"),
  holdWns: slackSchema.describe("Worst negative hold slack"),
  holdTns: slackSchema.describe("Total negative hold slack"),
  holdWs: slackSchema.describe("Worst hold slack"),
  holdViolations: z.number().int().nonnegative().describe(
    "Hold violation count",
  ),
  holdR2RWs: optionalSlackSchema.describe(
    "Worst register-to-register hold slack",
  ),
  holdR2RViolations: z
    .number()
    .int()
    .nonnegative()
    .describe("Register-to-register hold violation count"),
});

const STAMetricsRawJsonSchema = z.object({
  timing__setup__wns: slackSchema,
  timing__setup__tns: slackSchema,
  timing__setup__ws: slackSchema,
  timing__setup_vio__count: z.number().int().nonnegative(),
  timing__setup_r2r__ws: optionalSlackSchema,
  timing__setup_r2r_vio__count: z.number().int().nonnegative(),
  timing__hold__wns: slackSchema,
  timing__hold__tns: slackSchema,
  timing__hold__ws: slackSchema,
  timing__hold_vio__count: z.number().int().nonnegative(),
  timing__hold_r2r__ws: optionalSlackSchema,
  timing__hold_r2r_vio__count: z.number().int().nonnegative(),
});
type STAMetricsRawJson = z.infer<typeof STAMetricsRawJsonSchema>;

const toSTAMetrics = (raw: STAMetricsRawJson) => ({
  setupWns: raw.timing__setup__wns,
  setupTns: raw.timing__setup__tns,
  setupWs: raw.timing__setup__ws,
  setupViolations: raw.timing__setup_vio__count,
  setupR2RWs: raw.timing__setup_r2r__ws,
  setupR2RViolations: raw.timing__setup_r2r_vio__count,
  holdWns: raw.timing__hold__wns,
  holdTns: raw.timing__hold__tns,
  holdWs: raw.timing__hold__ws,
  holdViolations: raw.timing__hold_vio__count,
  holdR2RWs: raw.timing__hold_r2r__ws,
  holdR2RViolations: raw.timing__hold_r2r_vio__count,
});

export const STAMetricsSchema = STAMetricsRawJsonSchema
  .transform(toSTAMetrics)
  .pipe(STAMetricsOutputSchema);
export type STAMetrics = z.infer<typeof STAMetricsSchema>;
export const STAMetricsOutputOnlySchema = STAMetricsOutputSchema;

const PnRMetricsOutputSchema = z.object({
  rWL: z.number().nonnegative().describe("Routed wirelength"),
  totalPower: z.number().nonnegative().describe("Total power"),
  DRC: z.number().int().nonnegative().describe(
    "Detailed-routing DRC error count",
  ),
});

const PnRMetricsRawJsonSchema = z.object({
  route__wirelength: z.number().nonnegative(),
  power__total: z.number().nonnegative(),
  route__drc_errors: z.number().int().nonnegative(),
});
type PnRMetricsRawJson = z.infer<typeof PnRMetricsRawJsonSchema>;

const toPnRMetrics = (raw: PnRMetricsRawJson) => ({
  rWL: raw.route__wirelength,
  totalPower: raw.power__total,
  DRC: raw.route__drc_errors,
});

export const PnRMetricsSchema = PnRMetricsRawJsonSchema
  .transform(toPnRMetrics)
  .pipe(PnRMetricsOutputSchema);
export type PnRMetrics = z.infer<typeof PnRMetricsSchema>;
export const PnRMetricsOutputOnlySchema = PnRMetricsOutputSchema;

const QoRMetricsOutputSchema = z.object({
  cells: z.number().int().nonnegative().describe("Instance count"),
  area: z.number().nonnegative().describe("Instance area"),
  power: z.number().nonnegative().describe("Total power"),
  wns: slackSchema.describe("Worst setup negative slack"),
  tns: slackSchema.describe("Total setup negative slack"),
});

const QoRMetricsRawJsonSchema = z.object({
  design__instance__count: z.number().int().nonnegative(),
  design__instance__area: z.number().nonnegative(),
  power__total: z.number().nonnegative(),
  timing__setup__wns: slackSchema,
  timing__setup__tns: slackSchema,
});
type QoRMetricsRawJson = z.infer<typeof QoRMetricsRawJsonSchema>;

const toQoRMetrics = (raw: QoRMetricsRawJson) => ({
  cells: raw.design__instance__count,
  area: raw.design__instance__area,
  power: raw.power__total,
  wns: raw.timing__setup__wns,
  tns: raw.timing__setup__tns,
});

export const QoRMetricsSchema = QoRMetricsRawJsonSchema
  .transform(toQoRMetrics)
  .pipe(QoRMetricsOutputSchema);
export type QoRMetrics = z.infer<typeof QoRMetricsSchema>;
export const QoRMetricsOutputOnlySchema = QoRMetricsOutputSchema;

const PrePnRMetricsOutputSchema = z.object({
  STA: STAMetricsOutputSchema,
  QoR: QoRMetricsOutputSchema,
});

export const PrePnRMetricsSchema = z
  .intersection(STAMetricsRawJsonSchema, QoRMetricsRawJsonSchema)
  .transform((raw) => ({
    STA: toSTAMetrics(raw),
    QoR: toQoRMetrics(raw),
  }))
  .pipe(PrePnRMetricsOutputSchema);
export type PrePnRMetrics = z.infer<typeof PrePnRMetricsSchema>;
export const PrePnRMetricsOutputOnlySchema = PrePnRMetricsOutputSchema;

const PostPnRMetricsOutputSchema = z.object({
  STA: STAMetricsOutputSchema,
  QoR: QoRMetricsOutputSchema,
  PnR: PnRMetricsOutputSchema,
});

export const PostPnRMetricsSchema = z
  .intersection(
    z.intersection(STAMetricsRawJsonSchema, QoRMetricsRawJsonSchema),
    PnRMetricsRawJsonSchema,
  )
  .transform((raw) => ({
    STA: toSTAMetrics(raw),
    QoR: toQoRMetrics(raw),
    PnR: toPnRMetrics(raw),
  }))
  .pipe(PostPnRMetricsOutputSchema);
export type PostPnRMetrics = z.infer<typeof PostPnRMetricsSchema>;
export const PostPnRMetricsOutputOnlySchema = PostPnRMetricsOutputSchema;

export const parseMetricsJson = async (jsonFile: string) => {
  const text = await Deno.readTextFile(jsonFile);
  // HACK libreLane may emit non-standard JSON numeric literals like Infinity.
  const normalizedText = text
    .replace(/:\s*-Infinity\b/g, ': "-Infinity"')
    .replace(/:\s*Infinity\b/g, ': "Infinity"');

  return JSON.parse(normalizedText) as unknown;
};
