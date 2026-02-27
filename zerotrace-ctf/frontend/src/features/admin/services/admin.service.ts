import { apiClient } from "../../../services/api/client"
import type {
  AdminActionMessageResponse,
  AdminChallengeSummary,
  AdminLogListResponse,
  AdminTrackSummary,
  CreateAdminChallengeInput,
  CreateAdminChallengeResponse,
} from "../types/admin.types"
import { toAdminRequestError } from "./admin.errors"

const normalizeTracks = (payload: AdminTrackSummary[]): AdminTrackSummary[] => {
  return payload.map((track) => ({
    id: track.id,
    name: track.name,
    slug: track.slug,
    description: track.description,
    is_active: track.is_active,
  }))
}

const normalizeChallenges = (payload: AdminChallengeSummary[]): AdminChallengeSummary[] => {
  return payload.map((challenge) => ({
    id: challenge.id,
    track_id: challenge.track_id,
    title: challenge.title,
    slug: challenge.slug,
    difficulty: challenge.difficulty,
    points: challenge.points,
    is_published: challenge.is_published,
  }))
}

export const getAdminTracks = async (): Promise<AdminTrackSummary[]> => {
  try {
    const { data } = await apiClient.get<AdminTrackSummary[]>("/tracks")
    return normalizeTracks(data)
  } catch (error) {
    throw toAdminRequestError(error, "Failed to load tracks.")
  }
}

export const getAdminTrackChallenges = async (trackSlug: string): Promise<AdminChallengeSummary[]> => {
  try {
    const { data } = await apiClient.get<AdminChallengeSummary[]>(`/tracks/${trackSlug}/challenges`)
    return normalizeChallenges(data)
  } catch (error) {
    throw toAdminRequestError(error, "Failed to load challenges.")
  }
}

export const createAdminChallenge = async (
  payload: CreateAdminChallengeInput,
): Promise<CreateAdminChallengeResponse> => {
  try {
    const { data } = await apiClient.post<CreateAdminChallengeResponse>("/admin/challenges", payload)
    return data
  } catch (error) {
    throw toAdminRequestError(error, "Failed to create challenge.")
  }
}

export const setAdminChallengeFlag = async (
  challengeId: string,
  flag: string,
): Promise<AdminActionMessageResponse> => {
  try {
    const { data } = await apiClient.post<AdminActionMessageResponse>(`/admin/challenges/${challengeId}/flag`, {
      flag,
    })
    return data
  } catch (error) {
    throw toAdminRequestError(error, "Failed to set challenge flag.")
  }
}

export const publishAdminChallenge = async (
  challengeId: string,
): Promise<AdminActionMessageResponse> => {
  try {
    const { data } = await apiClient.post<AdminActionMessageResponse>(
      `/admin/challenges/${challengeId}/publish`,
    )
    return data
  } catch (error) {
    throw toAdminRequestError(error, "Failed to publish challenge.")
  }
}

export const unpublishAdminChallenge = async (
  challengeId: string,
): Promise<AdminActionMessageResponse> => {
  try {
    const { data } = await apiClient.post<AdminActionMessageResponse>(
      `/admin/challenges/${challengeId}/unpublish`,
    )
    return data
  } catch (error) {
    throw toAdminRequestError(error, "Failed to unpublish challenge.")
  }
}

export const getAdminLogs = async (limit: number, offset: number): Promise<AdminLogListResponse> => {
  try {
    const { data } = await apiClient.get<AdminLogListResponse>("/admin/logs", {
      params: { limit, offset },
    })
    return data
  } catch (error) {
    throw toAdminRequestError(error, "Failed to load admin logs.")
  }
}
