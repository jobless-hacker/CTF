import axios from "axios"

export class AdminRequestError extends Error {
  readonly status: number | null

  constructor(message: string, status: number | null = null) {
    super(message)
    this.name = "AdminRequestError"
    this.status = status
  }
}

const messageForStatus = (status: number, fallbackMessage: string): string => {
  if (status === 400) {
    return "Invalid admin request."
  }
  if (status === 401) {
    return "Authentication required."
  }
  if (status === 403) {
    return "Insufficient permissions."
  }
  if (status === 404) {
    return "Requested resource was not found."
  }
  return fallbackMessage
}

export const toAdminRequestError = (error: unknown, fallbackMessage: string): AdminRequestError => {
  if (error instanceof AdminRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (typeof status === "number") {
      return new AdminRequestError(messageForStatus(status, fallbackMessage), status)
    }
    return new AdminRequestError("Network error. Please try again.", null)
  }

  return new AdminRequestError(fallbackMessage, null)
}
