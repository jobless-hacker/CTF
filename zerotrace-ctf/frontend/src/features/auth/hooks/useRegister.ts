import { useMutation } from "@tanstack/react-query"

import type { RegisterInput } from "../schemas/auth.schemas"
import { AuthRequestError } from "../services/auth.errors"
import { registerRequest } from "../services/auth.service"

export const useRegister = () => {
  return useMutation<void, AuthRequestError, RegisterInput>({
    mutationFn: (credentials) => registerRequest(credentials),
  })
}
