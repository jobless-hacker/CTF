import { useMutation, useQueryClient } from "@tanstack/react-query"

import { AdminRequestError } from "../services/admin.errors"
import {
  createAdminChallenge,
  publishAdminChallenge,
  setAdminChallengeFlag,
  unpublishAdminChallenge,
} from "../services/admin.service"
import type {
  AdminActionMessageResponse,
  CreateAdminChallengeInput,
  CreateAdminChallengeResponse,
} from "../types/admin.types"

export const useAdminCreateChallenge = () => {
  const queryClient = useQueryClient()
  return useMutation<CreateAdminChallengeResponse, AdminRequestError, CreateAdminChallengeInput>({
    mutationFn: createAdminChallenge,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["admin", "challenge-catalog"] })
    },
  })
}

export const useAdminSetFlag = () => {
  return useMutation<AdminActionMessageResponse, AdminRequestError, { challengeId: string; flag: string }>({
    mutationFn: ({ challengeId, flag }) => setAdminChallengeFlag(challengeId, flag),
  })
}

export const useAdminPublishChallenge = () => {
  const queryClient = useQueryClient()
  return useMutation<AdminActionMessageResponse, AdminRequestError, { challengeId: string }>({
    mutationFn: ({ challengeId }) => publishAdminChallenge(challengeId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["admin", "challenge-catalog"] })
    },
  })
}

export const useAdminUnpublishChallenge = () => {
  const queryClient = useQueryClient()
  return useMutation<AdminActionMessageResponse, AdminRequestError, { challengeId: string }>({
    mutationFn: ({ challengeId }) => unpublishAdminChallenge(challengeId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["admin", "challenge-catalog"] })
    },
  })
}
