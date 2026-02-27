import { apiClient } from "../../../services/api/client"
import type { LoginInput, RegisterInput } from "../schemas/auth.schemas"
import type { LoginResponse, User } from "../types/auth.types"
import { normalizeAuthError } from "./auth.errors"

const sanitizeRoles = (roles: unknown): string[] => {
  if (!Array.isArray(roles)) {
    return []
  }

  return Array.from(
    new Set(
      roles.filter((role): role is string => typeof role === "string" && role.length > 0),
    ),
  )
}

const sanitizeUser = (user: User): User => ({
  id: user.id,
  email: user.email,
  roles: sanitizeRoles(user.roles),
  created_at: user.created_at,
})

export const loginRequest = async ({ email, password }: LoginInput): Promise<LoginResponse> => {
  try {
    const { data } = await apiClient.post<LoginResponse>("/auth/login", {
      email: email.trim(),
      password,
    })
    return data
  } catch (error) {
    throw normalizeAuthError(error, "login")
  }
}

export const registerRequest = async ({ email, password }: RegisterInput): Promise<void> => {
  try {
    await apiClient.post("/auth/register", {
      email: email.trim(),
      password,
    })
  } catch (error) {
    throw normalizeAuthError(error, "register")
  }
}

export const getCurrentUser = async (): Promise<User> => {
  try {
    const { data } = await apiClient.get<User>("/auth/me")
    return sanitizeUser(data)
  } catch (error) {
    throw normalizeAuthError(error, "profile")
  }
}
