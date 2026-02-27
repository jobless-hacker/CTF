import { keepPreviousData, useQuery } from "@tanstack/react-query"

import { LeaderboardRequestError } from "../services/leaderboard.errors"
import { getGlobalLeaderboard, getTrackLeaderboard } from "../services/leaderboard.service"
import type { LeaderboardResponse } from "../types/leaderboard.types"

interface UseLeaderboardOptions {
  trackId?: string
  limit: number
  offset: number
}

export const useLeaderboard = (options: UseLeaderboardOptions) => {
  const { trackId, limit, offset } = options

  return useQuery<LeaderboardResponse, LeaderboardRequestError>({
    queryKey: ["leaderboard", trackId ?? "global", limit, offset],
    queryFn: () =>
      trackId ? getTrackLeaderboard(trackId, limit, offset) : getGlobalLeaderboard(limit, offset),
    placeholderData: keepPreviousData,
  })
}
