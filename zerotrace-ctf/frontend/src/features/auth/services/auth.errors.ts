import axios from "axios"

export type AuthErrorContext = "login" | "register" | "profile"

export type AuthErrorCode =
  | "INVALID_CREDENTIALS"
  | "ACCESS_DENIED"
  | "UNAUTHORIZED"
  | "REGISTRATION_FAILED"
  | "NETWORK_ERROR"
  | "UNKNOWN_ERROR"

export class AuthRequestError extends Error {
  readonly code: AuthErrorCode
  readonly status: number | null

  constructor(code: AuthErrorCode, message: string, status: number | null = null) {
    super(message)
    this.name = "AuthRequestError"
    this.code = code
    this.status = status
  }
}

const resolveKnownError = (context: AuthErrorContext, status: number): AuthRequestError => {
  if (context === "login") {
    if (status === 401) {
      return new AuthRequestError("INVALID_CREDENTIALS", "Invalid credentials.", status)
    }
    if (status === 403) {
      return new AuthRequestError("ACCESS_DENIED", "Access denied.", status)
    }
    return new AuthRequestError("UNKNOWN_ERROR", "Authentication failed.", status)
  }

  if (context === "register") {
    return new AuthRequestError("REGISTRATION_FAILED", "Registration failed.", status)
  }

  if (status === 401 || status === 403) {
    return new AuthRequestError("UNAUTHORIZED", "Session expired. Please log in again.", status)
  }

  return new AuthRequestError("UNKNOWN_ERROR", "Unable to load user profile.", status)
}

export const normalizeAuthError = (
  error: unknown,
  context: AuthErrorContext,
): AuthRequestError => {
  if (error instanceof AuthRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (typeof status === "number") {
      return resolveKnownError(context, status)
    }
    return new AuthRequestError("NETWORK_ERROR", "Network error. Please try again.", null)
  }

  if (context === "register") {
    return new AuthRequestError("REGISTRATION_FAILED", "Registration failed.", null)
  }

  if (context === "profile") {
    return new AuthRequestError("UNKNOWN_ERROR", "Unable to load user profile.", null)
  }

  return new AuthRequestError("UNKNOWN_ERROR", "Authentication failed.", null)
}
