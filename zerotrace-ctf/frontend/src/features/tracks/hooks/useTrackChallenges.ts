import { useQuery } from "@tanstack/react-query"

import { getTrackChallenges } from "../services/track.service"
import { TrackRequestError } from "../services/track.errors"
import type { TrackChallengeSummary } from "../types/track.types"

export const useTrackChallenges = (slug: string | undefined) => {
  return useQuery<TrackChallengeSummary[], TrackRequestError>({
    queryKey: ["track", slug, "challenges"],
    queryFn: () => getTrackChallenges(slug as string),
    enabled: Boolean(slug),
  })
}
