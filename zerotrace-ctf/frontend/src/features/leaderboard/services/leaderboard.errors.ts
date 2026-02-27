import axios from "axios"

export class LeaderboardRequestError extends Error {
  readonly status: number | null

  constructor(message: string, status: number | null = null) {
    super(message)
    this.name = "LeaderboardRequestError"
    this.status = status
  }
}

export const toLeaderboardRequestError = (error: unknown): LeaderboardRequestError => {
  if (error instanceof LeaderboardRequestError) {
    return error
  }

  if (axios.isAxiosError(error)) {
    const status = error.response?.status
    if (status === 400) {
      return new LeaderboardRequestError("Invalid pagination parameters.", status)
    }
    if (status === 404) {
      return new LeaderboardRequestError("Leaderboard not found.", status)
    }
    if (typeof status === "number") {
      return new LeaderboardRequestError("Failed to load leaderboard.", status)
    }

    return new LeaderboardRequestError("Network error. Please try again.", null)
  }

  return new LeaderboardRequestError("Failed to load leaderboard.", null)
}

export const normalizeLeaderboardError = (error: unknown): string => {
  return toLeaderboardRequestError(error).message
}
