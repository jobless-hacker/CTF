import { z } from "zod"

export const submitFlagSchema = z.object({
  flag: z.string().trim().min(1, "Flag is required"),
  lab_session_nonce: z
    .string()
    .trim()
    .min(1)
    .max(128)
    .regex(/^[A-Za-z0-9_-]+$/, "Invalid lab session nonce")
    .optional(),
})

export type SubmitFlagInput = z.infer<typeof submitFlagSchema>

export const challengeLabCommandSchema = z.object({
  command: z.string().trim().min(1, "Command is required").max(256, "Command is too long"),
  cwd: z.string().trim().min(1).max(256).default("/"),
  lab_session_nonce: z
    .string()
    .trim()
    .min(1)
    .max(128)
    .regex(/^[A-Za-z0-9_-]+$/, "Invalid lab session nonce")
    .optional(),
})

export type ChallengeLabCommandInput = z.infer<typeof challengeLabCommandSchema>
