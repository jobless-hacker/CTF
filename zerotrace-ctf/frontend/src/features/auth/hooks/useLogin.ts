import { useMutation } from "@tanstack/react-query"

import { useAuth } from "../../../context/use-auth"
import type { LoginInput } from "../schemas/auth.schemas"
import { AuthRequestError } from "../services/auth.errors"
import { getCurrentUser, loginRequest } from "../services/auth.service"

export const useLogin = () => {
  const { login, logout, setUser } = useAuth()

  return useMutation<void, AuthRequestError, LoginInput>({
    mutationFn: async (credentials) => {
      const token = await loginRequest(credentials)
      login(token.access_token)

      try {
        const user = await getCurrentUser()
        setUser(user)
      } catch (error) {
        if (error instanceof AuthRequestError) {
          if (error.code === "UNAUTHORIZED") {
            logout()
            throw error
          }
          return
        }
        return
      }
    },
  })
}
