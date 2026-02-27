import { useQuery } from "@tanstack/react-query"

import { ChallengeRequestError } from "../services/challenge.errors"
import { getChallengeDetail } from "../services/challenge.service"
import type { ChallengeDetail } from "../types/challenge.types"

export const useChallengeDetail = (slug: string | undefined) => {
  return useQuery<ChallengeDetail, ChallengeRequestError>({
    queryKey: ["challenge", slug],
    queryFn: () => getChallengeDetail(slug as string),
    enabled: Boolean(slug),
  })
}
