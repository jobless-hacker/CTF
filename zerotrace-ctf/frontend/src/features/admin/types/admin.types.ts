export type ChallengeDifficulty = "easy" | "medium" | "hard"

export interface AdminTrackSummary {
  id: string
  name: string
  slug: string
  description: string | null
  is_active: boolean
}

export interface AdminChallengeSummary {
  id: string
  track_id: string
  title: string
  slug: string
  difficulty: ChallengeDifficulty
  points: number
  is_published: boolean
}

export interface CreateAdminChallengeInput {
  track_id: string
  title: string
  slug: string
  description: string
  difficulty: ChallengeDifficulty
  points: number
}

export interface CreateAdminChallengeResponse {
  id: string
  slug: string
  is_published: boolean
}

export interface AdminActionMessageResponse {
  message: string
}

export interface AdminLogEntry {
  id: string
  event_type: string
  severity: string
  message: string
  created_at: string
  user_id: string | null
  challenge_id: string | null
}

export interface AdminLogListResponse {
  results: AdminLogEntry[]
  limit: number
  offset: number
}
