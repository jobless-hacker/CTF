import { NavLink, Outlet, useNavigate } from "react-router-dom"

import { useAuth } from "../context/use-auth"
import { XPSummaryBadge } from "../features/xp/components/xp-summary-badge"

export const MainLayout = () => {
  const { user, logout, isAuthenticated } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate("/login", { replace: true })
  }

  return (
    <div className="zt-app-screen scan-overlay">
      <div className="zt-app-bg-grid cyber-grid" aria-hidden />
      <div className="zt-app-glow-top" aria-hidden />
      <div className="zt-app-glow-right" aria-hidden />
      <div className="zt-app-glow-left" aria-hidden />
      <div className="zt-app-content">
        <nav className="zt-topbar">
          <div className="zt-topbar-inner">
            <div className="flex items-center gap-5">
              <NavLink to="/" className="zt-brand">
                <span className="zt-brand-mark">ZT</span>
                <span>ZeroTrace CTF</span>
              </NavLink>

              <div className="zt-nav">
                {isAuthenticated ? (
                  <>
                    <NavLink to="/leaderboard" className={({ isActive }) => `zt-nav-link ${isActive ? "zt-nav-link--active" : ""}`}>
                      Leaderboard
                    </NavLink>
                    <NavLink to="/tracks" className={({ isActive }) => `zt-nav-link ${isActive ? "zt-nav-link--active" : ""}`}>
                      Tracks
                    </NavLink>
                  </>
                ) : null}

                {user?.roles?.includes("admin") ? (
                  <NavLink to="/admin" className={({ isActive }) => `zt-nav-link ${isActive ? "zt-nav-link--active" : ""}`}>
                    Admin
                  </NavLink>
                ) : null}
              </div>
            </div>

            <div className="flex items-center gap-3">
              {isAuthenticated ? (
                <>
                  <XPSummaryBadge />
                  <span className="zt-pill">{user?.email}</span>
                  <button onClick={handleLogout} className="zt-button zt-button--ghost">
                    Logout
                  </button>
                </>
              ) : (
                <>
                  <NavLink to="/login" className={({ isActive }) => `zt-nav-link ${isActive ? "zt-nav-link--active" : ""}`}>
                    Login
                  </NavLink>
                  <NavLink to="/register" className={({ isActive }) => `zt-nav-link ${isActive ? "zt-nav-link--active" : ""}`}>
                    Register
                  </NavLink>
                </>
              )}
            </div>
          </div>
        </nav>

        <main className="zt-main">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
