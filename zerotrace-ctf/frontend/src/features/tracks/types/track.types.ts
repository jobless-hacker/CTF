export type ChallengeDifficulty = "easy" | "medium" | "hard"

export interface TrackSummary {
  id: string
  name: string
  slug: string
  description: string | null
  is_active: boolean
}

export interface TrackChallengeSummary {
  id: string
  track_id: string
  title: string
  slug: string
  difficulty: ChallengeDifficulty
  points: number
  is_published: boolean
}

export interface TrackChallengeModuleGroup {
  moduleKey: string
  moduleCode: string
  moduleName: string
  moduleOrder: number
  challengeCount: number
  totalXP: number
  challenges: TrackChallengeSummary[]
}
