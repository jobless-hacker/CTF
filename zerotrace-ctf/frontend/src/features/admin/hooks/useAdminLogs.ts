import { keepPreviousData, useQuery } from "@tanstack/react-query"

import { AdminRequestError } from "../services/admin.errors"
import { getAdminLogs } from "../services/admin.service"
import type { AdminLogListResponse } from "../types/admin.types"

export const useAdminLogs = (limit: number, offset: number) => {
  return useQuery<AdminLogListResponse, AdminRequestError>({
    queryKey: ["admin", "logs", limit, offset],
    queryFn: () => getAdminLogs(limit, offset),
    placeholderData: keepPreviousData,
  })
}
