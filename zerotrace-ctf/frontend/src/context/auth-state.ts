import { createContext } from "react"

import type { User } from "../features/auth/types/auth.types"

export interface AuthState {
  user: User | null
  isAuthenticated: boolean
  isBootstrapping: boolean
  setUser: (user: User | null) => void
  login: (token: string) => void
  logout: () => void
}

export const AuthContext = createContext<AuthState | undefined>(undefined)
