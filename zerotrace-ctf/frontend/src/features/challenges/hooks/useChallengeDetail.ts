import { useQuery } from "@tanstack/react-query"

import { useAuth } from "../../../context/use-auth"
import { getAccessToken } from "../../../services/auth-session/token"
import { ChallengeRequestError } from "../services/challenge.errors"
import { getChallengeDetail } from "../services/challenge.service"
import type { ChallengeDetail } from "../types/challenge.types"

const getJwtSub = () => {
  if (typeof window === "undefined") {
    return null
  }

  const token = getAccessToken()
  if (!token) {
    return null
  }

  const parts = token.split(".")
  if (parts.length < 2) {
    return null
  }

  try {
    const encodedPayload = parts[1].replace(/-/g, "+").replace(/_/g, "/")
    const paddingLength = (4 - (encodedPayload.length % 4)) % 4
    const paddedPayload = `${encodedPayload}${"=".repeat(paddingLength)}`
    const payload = JSON.parse(window.atob(paddedPayload)) as { sub?: unknown }
    if (typeof payload.sub !== "string") {
      return null
    }
    const normalized = payload.sub.trim()
    return normalized.length > 0 ? normalized : null
  } catch {
    return null
  }
}

export const useChallengeDetail = (slug: string | undefined) => {
  const { user } = useAuth()
  const authIdentity = user?.id?.trim() || getJwtSub() || "anon"

  return useQuery<ChallengeDetail, ChallengeRequestError>({
    queryKey: ["challenge", slug, authIdentity],
    queryFn: () => getChallengeDetail(slug as string),
    enabled: Boolean(slug),
  })
}
