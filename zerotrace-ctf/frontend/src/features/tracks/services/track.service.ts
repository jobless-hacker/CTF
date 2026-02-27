import { apiClient } from "../../../services/api/client"
import type { TrackChallengeSummary, TrackSummary } from "../types/track.types"
import { normalizeTrackError } from "./track.errors"

const normalizeTracks = (payload: TrackSummary[]): TrackSummary[] => {
  return payload.map((track) => ({
    id: track.id,
    name: track.name,
    slug: track.slug,
    description: track.description,
    is_active: track.is_active,
  }))
}

const normalizeTrackChallenges = (payload: TrackChallengeSummary[]): TrackChallengeSummary[] => {
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

export const getTracks = async (): Promise<TrackSummary[]> => {
  try {
    const { data } = await apiClient.get<TrackSummary[]>("/tracks")
    return normalizeTracks(data)
  } catch (error) {
    throw normalizeTrackError(error, "Unable to load tracks.")
  }
}

export const getTrackChallenges = async (slug: string): Promise<TrackChallengeSummary[]> => {
  try {
    const { data } = await apiClient.get<TrackChallengeSummary[]>(`/tracks/${slug}/challenges`)
    return normalizeTrackChallenges(data)
  } catch (error) {
    throw normalizeTrackError(error, "Unable to load track challenges.")
  }
}
