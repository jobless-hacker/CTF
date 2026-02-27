import axios from "axios"

export type TrackErrorCode = "TRACK_NOT_FOUND" | "NETWORK_ERROR" | "UNKNOWN_ERROR"

export class TrackRequestError extends Error {
  readonly code: TrackErrorCode
  readonly status: number | null

  constructor(code: TrackErrorCode, message: string, status: number | null = null) {
    super(message)
    this.name = "TrackRequestError"
    this.code = code
    this.status = status
  }
}

export const normalizeTrackError = (error: unknown, fallbackMessage: string): TrackRequestError => {
  if (error instanceof TrackRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (status === 404) {
      return new TrackRequestError("TRACK_NOT_FOUND", "Track not found.", status)
    }

    if (typeof status === "number") {
      return new TrackRequestError("UNKNOWN_ERROR", fallbackMessage, status)
    }

    return new TrackRequestError("NETWORK_ERROR", "Network error. Please try again.", null)
  }

  return new TrackRequestError("UNKNOWN_ERROR", fallbackMessage, null)
}
