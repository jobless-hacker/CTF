import { useMemo, useState } from "react"
import { Link } from "react-router-dom"

import { useTracks } from "../../features/tracks/hooks/useTracks"

export const TrackListPage = () => {
  const { data, isLoading, error } = useTracks()
  const [query, setQuery] = useState("")

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
  const normalizedQuery = query.trim().toLowerCase()
  const filteredTracks = useMemo(() => {
    if (!normalizedQuery) {
      return tracks
    }
    return tracks.filter((track) => {
      const searchable = `${track.name} ${track.slug} ${track.description ?? ""}`.toLowerCase()
      return searchable.includes(normalizedQuery)
    })
  }, [normalizedQuery, tracks])

  return (
    <div className="zt-page">
      <div className="zt-hero">
        <p className="zt-kicker">Target Categories</p>
        <h1 className="zt-heading mt-1">Tracks</h1>
        <p className="zt-subheading mt-2">Find a track quickly and jump into modules without scrolling through noise.</p>
        <div className="zt-hero-meta mt-4">
          <span className="zt-pill">{tracks.length} total tracks</span>
          <span className="zt-pill">{filteredTracks.length} visible</span>
        </div>
      </div>

      <section className="zt-panel">
        <label htmlFor="track-search" className="zt-field-label">
          Search Tracks
        </label>
        <input
          id="track-search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search by name, slug, or description..."
          className="zt-input"
          autoComplete="off"
        />
      </section>

      {filteredTracks.length > 0 ? (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-3">
          {filteredTracks.map((track) => (
            <Link key={track.slug} to={`/tracks/${track.slug}`} className="zt-card-link">
              <p className="zt-kicker">Track</p>
              <h2 className="mt-1 text-lg font-semibold">{track.name}</h2>
              {track.description ? <p className="zt-subheading mt-2">{track.description}</p> : null}
              <div className="mt-4 flex items-center justify-between">
                <span className="zt-pill">{track.slug}</span>
                <span className="text-sm text-cyber-neon">Open</span>
              </div>
            </Link>
          ))}
        </div>
      ) : (
        <div className="zt-alert zt-alert--info">
          {tracks.length === 0 ? "No active tracks available." : "No tracks match your search."}
        </div>
      )}
    </div>
  )
}
