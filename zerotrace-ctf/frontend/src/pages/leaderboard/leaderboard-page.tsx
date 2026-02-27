import { useState } from "react"

import { useAuth } from "../../context/use-auth"
import { useLeaderboard } from "../../features/leaderboard/hooks/useLeaderboard"
import { normalizeLeaderboardError } from "../../features/leaderboard/services/leaderboard.errors"

const PAGE_SIZE = 20

const formatFirstSolveAt = (value: string | null | undefined): string => {
  if (!value) {
    return "-"
  }

  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) {
    return "-"
  }

  return parsed.toLocaleString()
}

export const LeaderboardPage = () => {
  const { user } = useAuth()
  const [offset, setOffset] = useState(0)

  const { data, isLoading, error } = useLeaderboard({
    limit: PAGE_SIZE,
    offset,
  })

  if (isLoading) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading leaderboard...</div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">{normalizeLeaderboardError(error)}</div>
      </div>
    )
  }

  const entries = data?.results ?? []

  return (
    <div className="zt-page">
      <div>
        <p className="zt-kicker">Competition Feed</p>
        <h1 className="zt-heading mt-1">Global Leaderboard</h1>
      </div>

      <div className="zt-table-wrap">
        <table className="zt-table">
          <thead>
            <tr>
              <th>Rank</th>
              <th>User</th>
              <th>XP</th>
              <th>First Solve</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((entry) => {
              const isCurrentUser = entry.user_id === user?.id

              return (
                <tr key={entry.user_id} className={isCurrentUser ? "zt-row-highlight font-semibold" : ""}>
                  <td>
                    {entry.rank === 1 ? "🥇 " : null}
                    {entry.rank === 2 ? "🥈 " : null}
                    {entry.rank === 3 ? "🥉 " : null}#{entry.rank}
                  </td>
                  <td>{entry.user_id.slice(0, 8)}...</td>
                  <td>{entry.total_xp}</td>
                  <td>{formatFirstSolveAt(entry.first_solve_at)}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {entries.length === 0 ? <div className="zt-alert zt-alert--info">No leaderboard entries yet.</div> : null}

      <div className="zt-pagination">
        <button
          disabled={offset === 0}
          onClick={() => setOffset((previous) => Math.max(0, previous - PAGE_SIZE))}
          className="zt-button zt-button--ghost"
        >
          Previous
        </button>

        <button
          disabled={entries.length < PAGE_SIZE}
          onClick={() => setOffset((previous) => previous + PAGE_SIZE)}
          className="zt-button zt-button--ghost"
        >
          Next
        </button>
      </div>
    </div>
  )
}
