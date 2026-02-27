import { NavLink, Outlet } from "react-router-dom"

export const AdminLayout = () => {
  return (
    <div className="zt-app-screen scan-overlay">
      <div className="zt-app-bg-grid cyber-grid" aria-hidden />
      <div className="zt-app-glow-top" aria-hidden />
      <div className="zt-app-glow-right" aria-hidden />
      <div className="zt-app-glow-left" aria-hidden />

      <div className="zt-app-content flex min-h-screen">
        <aside className="zt-sidebar">
          <h2 className="zt-panel-title mb-2">Control Plane</h2>
          <p className="zt-subheading mb-6 mt-0">Operations, content governance, and telemetry.</p>

          <nav className="space-y-2">
            <NavLink end to="/admin" className={({ isActive }) => `zt-sidebar-link ${isActive ? "zt-sidebar-link--active" : ""}`}>
              Dashboard
            </NavLink>
            <NavLink to="/admin/challenges" className={({ isActive }) => `zt-sidebar-link ${isActive ? "zt-sidebar-link--active" : ""}`}>
              Manage Challenges
            </NavLink>
            <NavLink to="/admin/logs" className={({ isActive }) => `zt-sidebar-link ${isActive ? "zt-sidebar-link--active" : ""}`}>
              Logs
            </NavLink>
          </nav>
        </aside>

        <main className="zt-main flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
