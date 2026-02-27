import { Link } from "react-router-dom"

import { useTracks } from "../../features/tracks/hooks/useTracks"

export const TrackListPage = () => {
  const { data, isLoading, error } = useTracks()

  if (isLoading) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading tracks...</div>
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

  const tracks = data ?? []

  return (
    <div className="zt-page">
      <div>
        <p className="zt-kicker">Target Categories</p>
        <h1 className="zt-heading mt-1">Tracks</h1>
      </div>

      {tracks.length > 0 ? (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-3">
          {tracks.map((track) => (
            <Link key={track.slug} to={`/tracks/${track.slug}`} className="zt-card-link">
              <p className="zt-kicker">Track</p>
              <h2 className="mt-1 text-lg font-semibold">{track.name}</h2>
              {track.description ? <p className="zt-subheading mt-2">{track.description}</p> : null}
            </Link>
          ))}
        </div>
      ) : (
        <div className="zt-alert zt-alert--info">No active tracks available.</div>
      )}
    </div>
  )
}
