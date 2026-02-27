import { useQuery } from "@tanstack/react-query"

import { getAdminTracks } from "../services/admin.service"
import { AdminRequestError } from "../services/admin.errors"
import type { AdminTrackSummary } from "../types/admin.types"

export const useAdminTracks = () => {
  return useQuery<AdminTrackSummary[], AdminRequestError>({
    queryKey: ["admin", "tracks"],
    queryFn: getAdminTracks,
  })
}
