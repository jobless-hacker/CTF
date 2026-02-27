import { z } from "zod"

export const submitFlagSchema = z.object({
  flag: z.string().trim().min(1, "Flag is required"),
})

export type SubmitFlagInput = z.infer<typeof submitFlagSchema>
