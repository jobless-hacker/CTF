import { useAdminChallengeCatalog } from "../../features/admin/hooks/useAdminChallengeCatalog"
import { useAdminTracks } from "../../features/admin/hooks/useAdminTracks"

export const AdminDashboardPage = () => {
  const { data: tracks, isLoading: tracksLoading } = useAdminTracks()
  const { data: challenges, isLoading: challengesLoading } = useAdminChallengeCatalog()

  return (
    <div className="zt-page">
      <div>
        <p className="zt-kicker">Operations Status</p>
        <h1 className="zt-heading mt-1">Admin Dashboard</h1>
        <p className="zt-subheading">Operational overview for challenge management.</p>
      </div>

      <div className="zt-grid-3">
        <div className="zt-stat-card">
          <h2 className="zt-stat-label">Active Tracks</h2>
          <p className="zt-stat-value">{tracksLoading ? "..." : tracks?.length ?? 0}</p>
        </div>
        <div className="zt-stat-card">
          <h2 className="zt-stat-label">Published Challenges</h2>
          <p className="zt-stat-value">{challengesLoading ? "..." : challenges?.length ?? 0}</p>
        </div>
        <div className="zt-stat-card">
          <h2 className="zt-stat-label">Audit Logs</h2>
          <p className="mt-2 text-lg font-semibold">Available via Logs tab</p>
        </div>
      </div>
    </div>
  )
}
