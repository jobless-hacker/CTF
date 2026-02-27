import type { ReactElement } from "react"
import { Navigate, useLocation } from "react-router-dom"

import { useAuth } from "../../context/use-auth"

export const AdminRoute = ({ children }: { children: ReactElement }) => {
  const { isAuthenticated, isBootstrapping, user } = useAuth()
  const location = useLocation()

  if (isBootstrapping) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading admin context...</div>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  if (!user?.roles?.includes("admin")) {
    return <Navigate to="/" replace />
  }
  return children
}
