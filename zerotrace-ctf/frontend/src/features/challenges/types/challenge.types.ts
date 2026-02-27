export type ChallengeDifficulty = "easy" | "medium" | "hard"

export interface ChallengeDetail {
  id: string
  track_id: string
  title: string
  slug: string
  description: string
  difficulty: ChallengeDifficulty
  points: number
  is_published: boolean
  created_at: string
  updated_at: string
}

export interface SubmitFlagResponse {
  correct: boolean
  xp_awarded: number
  first_blood: boolean
}
