import { useMutation, useQueryClient } from "@tanstack/react-query"

import type { SubmitFlagInput } from "../schemas/challenge.schemas"
import { ChallengeRequestError } from "../services/challenge.errors"
import { submitFlag } from "../services/challenge.service"
import type { SubmitFlagResponse } from "../types/challenge.types"

export const useSubmitFlag = (slug: string | undefined) => {
  const queryClient = useQueryClient()

  return useMutation<SubmitFlagResponse, ChallengeRequestError, SubmitFlagInput>({
    mutationFn: (payload) => submitFlag(slug as string, payload),
    onSuccess: async (response) => {
      const invalidations = [queryClient.invalidateQueries({ queryKey: ["challenge", slug] })]

      if (response.correct && response.xp_awarded > 0) {
        invalidations.push(queryClient.invalidateQueries({ queryKey: ["leaderboard"] }))
        invalidations.push(queryClient.invalidateQueries({ queryKey: ["current-user-xp"] }))
      }

      await Promise.all(invalidations)
    },
  })
}
