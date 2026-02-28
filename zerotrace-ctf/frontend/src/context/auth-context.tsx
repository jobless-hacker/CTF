import { useEffect, useState, type ReactNode } from "react"

import { AuthRequestError } from "../features/auth/services/auth.errors"
import { getCurrentUser } from "../features/auth/services/auth.service"
import type { User } from "../features/auth/types/auth.types"
import { clearAccessToken, getAccessToken, setAccessToken } from "../services/auth-session/token"
import { AuthContext } from "./auth-state"

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null)
  const [hasSessionToken, setHasSessionToken] = useState(() => Boolean(getAccessToken()))
  const [isBootstrapping, setIsBootstrapping] = useState(true)

  useEffect(() => {
    let mounted = true

    const hydrate = async () => {
      const token = getAccessToken()
      if (!token) {
        if (mounted) {
          setHasSessionToken(false)
          setIsBootstrapping(false)
        }
        return
      }

      if (mounted) {
        setHasSessionToken(true)
      }

      try {
        const currentUser = await getCurrentUser()
        if (mounted) {
          setUser(currentUser)
        }
      } catch (error) {
        if (error instanceof AuthRequestError && error.code === "UNAUTHORIZED") {
          clearAccessToken()
          if (mounted) {
            setUser(null)
            setHasSessionToken(false)
          }
        }
      } finally {
        if (mounted) {
          setIsBootstrapping(false)
        }
      }
    }

    void hydrate()

    return () => {
      mounted = false
    }
  }, [])

  const login = (token: string) => {
    setAccessToken(token)
    setHasSessionToken(Boolean(token.trim()))
  }

  const logout = () => {
    clearAccessToken()
    setUser(null)
    setHasSessionToken(false)
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: hasSessionToken,
        isBootstrapping,
        setUser,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
