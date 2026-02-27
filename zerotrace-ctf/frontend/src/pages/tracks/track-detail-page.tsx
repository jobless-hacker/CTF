import { Link, useParams } from "react-router-dom"

import { useTrackChallengeModules } from "../../features/tracks/hooks/useTrackChallengeModules"
import { useTracks } from "../../features/tracks/hooks/useTracks"

export const TrackDetailPage = () => {
  const { slug } = useParams<{ slug: string }>()
  const { moduleGroups, challenges, isLoading, error } = useTrackChallengeModules(slug)
  const { data: tracks } = useTracks()

  if (!slug) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">Invalid track.</div>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading challenges...</div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">{error.message}</div>
      </div>
    )
  }

  const currentTrack = tracks?.find((track) => track.slug === slug)

  return (
    <div className="zt-page">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="zt-kicker">Track Operations</p>
          <h1 className="zt-heading mt-1">{currentTrack?.name ?? "Challenges"}</h1>
        </div>
        {currentTrack ? (
          <Link to={`/tracks/${currentTrack.id}/leaderboard`} className="zt-button zt-button--ghost">
            View Track Leaderboard
          </Link>
        ) : null}
      </div>

      {challenges.length > 0 ? (
        <div className="space-y-5">
          {moduleGroups.map((moduleGroup) => (
            <section key={moduleGroup.moduleKey} className="zt-panel">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="zt-kicker">{moduleGroup.moduleCode}</p>
                  <h2 className="zt-panel-title mt-1">{moduleGroup.moduleName}</h2>
                </div>
                <div className="flex flex-wrap gap-2">
                  <span className="zt-pill">{moduleGroup.challengeCount} challenges</span>
                  <span className="zt-pill">{moduleGroup.totalXP} XP</span>
                </div>
              </div>

              <div className="mt-4 space-y-3">
                {moduleGroup.challenges.map((challenge) => (
                  <Link key={challenge.slug} to={`/challenges/${challenge.slug}`} className="zt-card-link">
                    <div className="flex flex-wrap items-center justify-between gap-4">
                      <div>
                        <p className="zt-kicker">{challenge.difficulty}</p>
                        <span className="font-medium">{challenge.title}</span>
                      </div>
                      <span className="zt-pill">{challenge.points} pts</span>
                    </div>
                  </Link>
                ))}
              </div>
            </section>
          ))}
        </div>
      ) : (
        <div className="zt-alert zt-alert--info">No published challenges available.</div>
      )}
    </div>
  )
}
