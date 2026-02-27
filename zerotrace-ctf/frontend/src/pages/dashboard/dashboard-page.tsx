import { Link } from "react-router-dom"

import { useAuth } from "../../context/use-auth"
import { useCurrentUserXP } from "../../features/xp/hooks/useCurrentUserXP"

export const DashboardPage = () => {
  const { user } = useAuth()
  const { data: xp, isLoading } = useCurrentUserXP()

  return (
    <div className="zt-page">
      <div>
        <p className="zt-kicker">Mission Console</p>
        <h1 className="zt-heading mt-1">Dashboard</h1>
        <p className="zt-subheading">Welcome back, {user?.email ?? "player"}.</p>
      </div>

      <div className="zt-grid-3">
        <div className="zt-stat-card">
          <h2 className="zt-stat-label">Total XP</h2>
          <p className="zt-stat-value">{isLoading ? "..." : xp?.total_xp ?? 0}</p>
        </div>
        <Link to="/tracks" className="zt-card-link">
          <p className="zt-kicker">Recon</p>
          <h2 className="mt-1 text-lg font-semibold">Tracks</h2>
          <p className="zt-subheading mt-2">Browse all available tracks.</p>
        </Link>
        <Link to="/leaderboard" className="zt-card-link">
          <p className="zt-kicker">Intel</p>
          <h2 className="mt-1 text-lg font-semibold">Leaderboard</h2>
          <p className="zt-subheading mt-2">Monitor ranking and score drift.</p>
        </Link>
      </div>
    </div>
  )
}
