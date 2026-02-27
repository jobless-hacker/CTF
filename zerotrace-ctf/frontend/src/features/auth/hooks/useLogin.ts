import { useMutation } from "@tanstack/react-query"

import { useAuth } from "../../../context/use-auth"
import type { LoginInput } from "../schemas/auth.schemas"
import { AuthRequestError } from "../services/auth.errors"
import { getCurrentUser, loginRequest } from "../services/auth.service"
import type { User } from "../types/auth.types"

export const useLogin = () => {
  const { login, logout, setUser } = useAuth()

  return useMutation<User, AuthRequestError, LoginInput>({
    mutationFn: async (credentials) => {
      const token = await loginRequest(credentials)
      login(token.access_token)

      try {
        const user = await getCurrentUser()
        setUser(user)
        return user
      } catch (error) {
        logout()
        if (error instanceof AuthRequestError) {
          throw error
        }
        throw new AuthRequestError("UNKNOWN_ERROR", "Authentication failed.")
      }
    },
  })
}
