import type { ChallengeLabCommandInput, SubmitFlagInput } from "../schemas/challenge.schemas"
import { apiClient } from "../../../services/api/client"
import type {
  ChallengeDetail,
  ChallengeLabCommandResponse,
  SubmitFlagResponse,
} from "../types/challenge.types"
import {
  normalizeChallengeLabError,
  normalizeChallengeReadError,
  normalizeChallengeSubmitError,
} from "./challenge.errors"

const normalizeChallengeDetail = (payload: ChallengeDetail): ChallengeDetail => ({
  id: payload.id,
  track_id: payload.track_id,
  title: payload.title,
  slug: payload.slug,
  description: payload.description,
  difficulty: payload.difficulty,
  points: payload.points,
  is_published: payload.is_published,
  lab_available: payload.lab_available,
  created_at: payload.created_at,
  updated_at: payload.updated_at,
})

const normalizeSubmitResponse = (payload: SubmitFlagResponse): SubmitFlagResponse => ({
  correct: payload.correct,
  xp_awarded: payload.xp_awarded,
  first_blood: payload.first_blood,
})

const normalizeLabCommandResponse = (
  payload: ChallengeLabCommandResponse,
): ChallengeLabCommandResponse => ({
  output: payload.output,
  cwd: payload.cwd,
  exit_code: payload.exit_code,
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

export const executeChallengeLabCommand = async (
  slug: string,
  payload: ChallengeLabCommandInput,
): Promise<ChallengeLabCommandResponse> => {
  try {
    const { data } = await apiClient.post<ChallengeLabCommandResponse>(
      `/challenges/${slug}/lab/execute`,
      payload,
    )
    return normalizeLabCommandResponse(data)
  } catch (error) {
    throw normalizeChallengeLabError(error)
  }
}
