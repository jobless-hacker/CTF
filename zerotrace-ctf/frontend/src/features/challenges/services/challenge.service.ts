import type { SubmitFlagInput } from "../schemas/challenge.schemas"
import { apiClient } from "../../../services/api/client"
import type { ChallengeDetail, SubmitFlagResponse } from "../types/challenge.types"
import { normalizeChallengeReadError, normalizeChallengeSubmitError } from "./challenge.errors"

const normalizeChallengeDetail = (payload: ChallengeDetail): ChallengeDetail => ({
  id: payload.id,
  track_id: payload.track_id,
  title: payload.title,
  slug: payload.slug,
  description: payload.description,
  difficulty: payload.difficulty,
  points: payload.points,
  is_published: payload.is_published,
  created_at: payload.created_at,
  updated_at: payload.updated_at,
})

const normalizeSubmitResponse = (payload: SubmitFlagResponse): SubmitFlagResponse => ({
  correct: payload.correct,
  xp_awarded: payload.xp_awarded,
  first_blood: payload.first_blood,
})

export const getChallengeDetail = async (slug: string): Promise<ChallengeDetail> => {
  try {
    const { data } = await apiClient.get<ChallengeDetail>(`/challenges/${slug}`)
    return normalizeChallengeDetail(data)
  } catch (error) {
    throw normalizeChallengeReadError(error)
  }
}

export const submitFlag = async (
  slug: string,
  payload: SubmitFlagInput,
): Promise<SubmitFlagResponse> => {
  try {
    const { data } = await apiClient.post<SubmitFlagResponse>(`/challenges/${slug}/submit`, payload)
    return normalizeSubmitResponse(data)
  } catch (error) {
    throw normalizeChallengeSubmitError(error)
  }
}
