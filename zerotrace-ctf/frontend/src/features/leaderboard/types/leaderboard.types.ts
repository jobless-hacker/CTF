export interface LeaderboardEntry {
  user_id: string
  total_xp: number
  first_solve_at: string
  rank: number
}

export interface LeaderboardResponse {
  results: LeaderboardEntry[]
  limit: number
  offset: number
}
