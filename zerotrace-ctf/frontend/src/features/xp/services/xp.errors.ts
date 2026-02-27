import axios from "axios"

export class XPRequestError extends Error {
  readonly status: number | null

  constructor(message: string, status: number | null = null) {
    super(message)
    this.name = "XPRequestError"
    this.status = status
  }
}

export const toXPRequestError = (error: unknown): XPRequestError => {
  if (error instanceof XPRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (status === 401 || status === 403) {
      return new XPRequestError("Unauthorized.", status)
    }
    if (typeof status === "number") {
      return new XPRequestError("Failed to load XP.", status)
    }
    return new XPRequestError("Network error. Please try again.", null)
  }

  return new XPRequestError("Failed to load XP.", null)
}
