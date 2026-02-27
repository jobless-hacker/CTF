import { useQuery } from "@tanstack/react-query"

import { AdminRequestError } from "../services/admin.errors"
import { getAdminTrackChallenges, getAdminTracks } from "../services/admin.service"
import type { AdminChallengeSummary } from "../types/admin.types"

export interface AdminChallengeCatalogItem extends AdminChallengeSummary {
  track_name: string
  track_slug: string
}

export const useAdminChallengeCatalog = () => {
  return useQuery<AdminChallengeCatalogItem[], AdminRequestError>({
    queryKey: ["admin", "challenge-catalog"],
    queryFn: async () => {
      const tracks = await getAdminTracks()
      const challengesByTrack = await Promise.all(
        tracks.map(async (track) => {
          const challenges = await getAdminTrackChallenges(track.slug)
          return challenges.map((challenge) => ({
            ...challenge,
            track_name: track.name,
            track_slug: track.slug,
          }))
        }),
      )
      return challengesByTrack.flat()
    },
  })
}
