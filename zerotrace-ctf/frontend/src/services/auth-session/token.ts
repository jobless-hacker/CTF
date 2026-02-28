const ACCESS_TOKEN_STORAGE_KEY = "zerotrace.access_token"

const readPersistedToken = (): string | null => {
  if (typeof window === "undefined") {
    return null
  }

  try {
    const storedToken = window.localStorage.getItem(ACCESS_TOKEN_STORAGE_KEY)
    if (!storedToken) {
      return null
    }

    const normalizedToken = storedToken.trim()
    return normalizedToken.length > 0 ? normalizedToken : null
  } catch {
    return null
  }
}

const persistToken = (token: string | null) => {
  if (typeof window === "undefined") {
    return
  }

  try {
    if (token) {
      window.localStorage.setItem(ACCESS_TOKEN_STORAGE_KEY, token)
      return
    }

    window.localStorage.removeItem(ACCESS_TOKEN_STORAGE_KEY)
  } catch {
    return
  }
}

let accessToken: string | null = readPersistedToken()

export const setAccessToken = (token: string | null) => {
  const normalizedToken = token?.trim() || null
  accessToken = normalizedToken
  persistToken(normalizedToken)
}

export const getAccessToken = () => {
  if (accessToken) {
    return accessToken
  }

  accessToken = readPersistedToken()
  return accessToken
}

export const clearAccessToken = () => {
  setAccessToken(null)
}
