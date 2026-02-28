import { z } from "zod"

export const submitFlagSchema = z.object({
  flag: z.string().trim().min(1, "Flag is required"),
})

export type SubmitFlagInput = z.infer<typeof submitFlagSchema>

export const challengeLabCommandSchema = z.object({
  command: z.string().trim().min(1, "Command is required").max(256, "Command is too long"),
  cwd: z.string().trim().min(1).max(256).default("/"),
})

export type ChallengeLabCommandInput = z.infer<typeof challengeLabCommandSchema>
