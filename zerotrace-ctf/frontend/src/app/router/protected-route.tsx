import type { ReactElement } from "react"
import { Navigate, useLocation } from "react-router-dom"

import { useAuth } from "../../context/use-auth"

export const ProtectedRoute = ({ children }: { children: ReactElement }) => {
  const { isAuthenticated, isBootstrapping } = useAuth()
  const location = useLocation()

  if (isBootstrapping) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading secure context...</div>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  return children
}
