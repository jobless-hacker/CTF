import { useQuery } from "@tanstack/react-query"

import { XPRequestError } from "../services/xp.errors"
import { getCurrentUserXP } from "../services/xp.service"
import type { UserXPResponse } from "../types/xp.types"

export const useCurrentUserXP = () => {
  return useQuery<UserXPResponse, XPRequestError>({
    queryKey: ["current-user-xp"],
    queryFn: getCurrentUserXP,
    staleTime: 30_000,
  })
}
