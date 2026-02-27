import { useEffect, useState, type ReactNode } from "react"

import { getCurrentUser } from "../features/auth/services/auth.service"
import type { User } from "../features/auth/types/auth.types"
import { clearAccessToken, getAccessToken, setAccessToken } from "../services/auth-session/token"
import { AuthContext } from "./auth-state"

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null)
  const [isBootstrapping, setIsBootstrapping] = useState(true)

  useEffect(() => {
    let mounted = true

    const hydrate = async () => {
      const token = getAccessToken()
      if (!token) {
        if (mounted) {
          setIsBootstrapping(false)
        }
        return
      }

      try {
        const currentUser = await getCurrentUser()
        if (mounted) {
          setUser(currentUser)
        }
      } catch {
        clearAccessToken()
        if (mounted) {
          setUser(null)
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
  }

  const logout = () => {
    clearAccessToken()
    setUser(null)
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
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
