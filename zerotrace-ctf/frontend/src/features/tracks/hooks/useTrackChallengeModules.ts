import type { TrackRequestError } from "../services/track.errors"
import { groupTrackChallengesByModule } from "../mappers/track-modules.mapper"
import type { TrackChallengeModuleGroup, TrackChallengeSummary } from "../types/track.types"
import { useTrackChallenges } from "./useTrackChallenges"

type UseTrackChallengeModulesResult = {
  moduleGroups: TrackChallengeModuleGroup[]
  challenges: TrackChallengeSummary[]
  isLoading: boolean
  error: TrackRequestError | null
}

export const useTrackChallengeModules = (slug: string | undefined): UseTrackChallengeModulesResult => {
  const { data, isLoading, error } = useTrackChallenges(slug)
  const challenges = data ?? []
  const moduleGroups = groupTrackChallengesByModule(challenges)

  return {
    moduleGroups,
    challenges,
    isLoading,
    error: error ?? null,
  }
}
