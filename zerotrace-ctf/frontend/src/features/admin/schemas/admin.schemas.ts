import { z } from "zod"

export const createAdminChallengeSchema = z.object({
  track_id: z.string().uuid("Track is required"),
  title: z.string().trim().min(1, "Title is required").max(150, "Title is too long"),
  slug: z
    .string()
    .trim()
    .min(1, "Slug is required")
    .max(100, "Slug is too long")
    .regex(/^[a-z0-9-]+$/, "Slug must be lowercase and use hyphens only"),
  description: z.string().trim().min(1, "Description is required"),
  difficulty: z.enum(["easy", "medium", "hard"]),
  points: z.number().int().positive("Points must be greater than zero"),
})

export const setChallengeFlagSchema = z.object({
  challenge_id: z.string().uuid("Challenge ID is required"),
  flag: z.string().trim().min(1, "Flag is required"),
})

export const challengeIdSchema = z.object({
  challenge_id: z.string().uuid("Challenge ID is required"),
})

export type CreateAdminChallengeSchemaInput = z.infer<typeof createAdminChallengeSchema>
export type SetChallengeFlagSchemaInput = z.infer<typeof setChallengeFlagSchema>
export type ChallengeIdSchemaInput = z.infer<typeof challengeIdSchema>
