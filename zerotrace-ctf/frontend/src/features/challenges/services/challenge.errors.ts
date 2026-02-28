import axios from "axios"

export type ChallengeErrorCode =
  | "NOT_FOUND"
  | "UNAVAILABLE"
  | "INVALID_SUBMISSION"
  | "RATE_LIMITED"
  | "NETWORK_ERROR"
  | "UNKNOWN_ERROR"

export class ChallengeRequestError extends Error {
  readonly code: ChallengeErrorCode
  readonly status: number | null
  readonly retryAfterSeconds: number | null

  constructor(
    code: ChallengeErrorCode,
    message: string,
    status: number | null = null,
    retryAfterSeconds: number | null = null,
  ) {
    super(message)
    this.name = "ChallengeRequestError"
    this.code = code
    this.status = status
    this.retryAfterSeconds = retryAfterSeconds
  }
}

const parseRetryAfter = (value: unknown): number | null => {
  if (typeof value !== "string") {
    return null
  }

  const parsed = Number.parseInt(value, 10)
  if (Number.isNaN(parsed) || parsed < 0) {
    return null
  }
  return parsed
}

export const normalizeChallengeReadError = (error: unknown): ChallengeRequestError => {
  if (error instanceof ChallengeRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (status === 404) {
      return new ChallengeRequestError("NOT_FOUND", "Challenge not found.", status)
    }
    if (status === 400) {
      return new ChallengeRequestError("UNAVAILABLE", "Challenge unavailable.", status)
    }
    if (typeof status === "number") {
      return new ChallengeRequestError("UNKNOWN_ERROR", "Unable to load challenge.", status)
    }

    return new ChallengeRequestError("NETWORK_ERROR", "Network error. Please try again.", null)
  }

  return new ChallengeRequestError("UNKNOWN_ERROR", "Unable to load challenge.", null)
}

export const normalizeChallengeSubmitError = (error: unknown): ChallengeRequestError => {
  if (error instanceof ChallengeRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (status === 429) {
      const retryAfter = parseRetryAfter(error.response?.headers?.["retry-after"])
      return new ChallengeRequestError(
        "RATE_LIMITED",
        "Too many submissions. Try again later.",
        status,
        retryAfter,
      )
    }
    if (status === 404) {
      return new ChallengeRequestError("NOT_FOUND", "Challenge not found.", status)
    }
    if (status === 400) {
      const detail = error.response?.data?.detail
      if (typeof detail === "string" && detail === "Invalid flag submission.") {
        return new ChallengeRequestError("INVALID_SUBMISSION", "Invalid flag submission.", status)
      }
      return new ChallengeRequestError("UNAVAILABLE", "Challenge unavailable.", status)
    }
    if (typeof status === "number") {
      return new ChallengeRequestError("UNKNOWN_ERROR", "Flag submission failed.", status)
    }

    return new ChallengeRequestError("NETWORK_ERROR", "Network error. Please try again.", null)
  }

  return new ChallengeRequestError("UNKNOWN_ERROR", "Flag submission failed.", null)
}

export const normalizeChallengeLabError = (error: unknown): ChallengeRequestError => {
  if (error instanceof ChallengeRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (status === 404) {
      return new ChallengeRequestError("NOT_FOUND", "Lab unavailable for this challenge.", status)
    }
    if (status === 400) {
      return new ChallengeRequestError("UNAVAILABLE", "Challenge unavailable.", status)
    }
    if (typeof status === "number") {
      return new ChallengeRequestError("UNKNOWN_ERROR", "Lab command failed.", status)
    }

    return new ChallengeRequestError("NETWORK_ERROR", "Network error. Please try again.", null)
  }

  return new ChallengeRequestError("UNKNOWN_ERROR", "Lab command failed.", null)
}
