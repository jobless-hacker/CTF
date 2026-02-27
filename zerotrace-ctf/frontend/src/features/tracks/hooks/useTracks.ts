import { useQuery } from "@tanstack/react-query"

import { TrackRequestError } from "../services/track.errors"
import { getTracks } from "../services/track.service"
import type { TrackSummary } from "../types/track.types"

export const useTracks = () => {
  return useQuery<TrackSummary[], TrackRequestError>({
    queryKey: ["tracks"],
    queryFn: getTracks,
  })
}
