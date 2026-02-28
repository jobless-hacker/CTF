import { useMutation } from "@tanstack/react-query"

import type { ChallengeLabCommandInput } from "../schemas/challenge.schemas"
import { ChallengeRequestError } from "../services/challenge.errors"
import { executeChallengeLabCommand } from "../services/challenge.service"
import type { ChallengeLabCommandResponse } from "../types/challenge.types"

export const useChallengeLabCommand = (slug: string | undefined) => {
  return useMutation<ChallengeLabCommandResponse, ChallengeRequestError, ChallengeLabCommandInput>({
    mutationFn: (payload) => executeChallengeLabCommand(slug as string, payload),
  })
}
