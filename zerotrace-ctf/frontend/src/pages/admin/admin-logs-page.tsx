import { useState } from "react"

import { useAdminLogs } from "../../features/admin/hooks/useAdminLogs"

const PAGE_SIZE = 25

const formatDate = (value: string): string => {
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) {
    return "-"
  }
  return parsed.toLocaleString()
}

export const AdminLogsPage = () => {
  const [offset, setOffset] = useState(0)
  const { data, isLoading, error } = useAdminLogs(PAGE_SIZE, offset)

  if (isLoading) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading admin logs...</div>
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

  const entries = data?.results ?? []

  return (
    <div className="zt-page">
      <div>
        <p className="zt-kicker">Observability Stream</p>
        <h1 className="zt-heading mt-1">Admin Logs</h1>
      </div>

      <div className="zt-table-wrap">
        <table className="zt-table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Event</th>
              <th>Severity</th>
              <th>Message</th>
              <th>User</th>
              <th>Challenge</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((entry) => (
              <tr key={entry.id}>
                <td className="whitespace-nowrap">{formatDate(entry.created_at)}</td>
                <td>{entry.event_type}</td>
                <td>{entry.severity}</td>
                <td>{entry.message}</td>
                <td>{entry.user_id ? `${entry.user_id.slice(0, 8)}...` : "-"}</td>
                <td>{entry.challenge_id ? `${entry.challenge_id.slice(0, 8)}...` : "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {entries.length === 0 ? <div className="zt-alert zt-alert--info">No admin logs available.</div> : null}

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
