import { apiClient } from "../../../services/api/client"
import type { UserXPResponse } from "../types/xp.types"
import { toXPRequestError } from "./xp.errors"

const normalizeXPResponse = (payload: UserXPResponse): UserXPResponse => ({
  total_xp: payload.total_xp,
})

export const getCurrentUserXP = async (): Promise<UserXPResponse> => {
  try {
    const { data } = await apiClient.get<UserXPResponse>("/users/me/xp")
    return normalizeXPResponse(data)
  } catch (error) {
    throw toXPRequestError(error)
  }
}
