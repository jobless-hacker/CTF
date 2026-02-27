import { apiClient } from "../../../services/api/client"
import type { LeaderboardResponse } from "../types/leaderboard.types"
import { toLeaderboardRequestError } from "./leaderboard.errors"

const normalizeResponse = (payload: LeaderboardResponse): LeaderboardResponse => ({
  results: payload.results.map((entry) => ({
    user_id: entry.user_id,
    total_xp: entry.total_xp,
    first_solve_at: entry.first_solve_at,
    rank: entry.rank,
  })),
  limit: payload.limit,
  offset: payload.offset,
})

export const getGlobalLeaderboard = async (
  limit: number,
  offset: number,
): Promise<LeaderboardResponse> => {
  try {
    const { data } = await apiClient.get<LeaderboardResponse>("/leaderboard", {
      params: { limit, offset },
    })
    return normalizeResponse(data)
  } catch (error) {
    throw toLeaderboardRequestError(error)
  }
}

export const getTrackLeaderboard = async (
  trackId: string,
  limit: number,
  offset: number,
): Promise<LeaderboardResponse> => {
  try {
    const { data } = await apiClient.get<LeaderboardResponse>(`/tracks/${trackId}/leaderboard`, {
      params: { limit, offset },
    })
    return normalizeResponse(data)
  } catch (error) {
    throw toLeaderboardRequestError(error)
  }
}
