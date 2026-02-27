import { z } from "zod"

const emailSchema = z.string().trim().min(1, "Email is required").email("Invalid email")
const passwordSchema = z
  .string()
  .min(6, "Password must be at least 6 characters")
  .max(255, "Password must be 255 characters or fewer")

export const loginSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
})

export const registerSchema = loginSchema

export type LoginInput = z.infer<typeof loginSchema>
export type RegisterInput = z.infer<typeof registerSchema>
