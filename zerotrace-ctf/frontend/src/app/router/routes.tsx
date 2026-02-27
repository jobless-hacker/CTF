import { Route, Routes } from "react-router-dom"

import { AdminRoute } from "./admin-route"
import { ProtectedRoute } from "./protected-route"
import { AdminLayout } from "../../layouts/admin-layout"
import { MainLayout } from "../../layouts/main-layout"
import { AdminChallengesPage } from "../../pages/admin/admin-challenges-page"
import { AdminDashboardPage } from "../../pages/admin/admin-dashboard-page"
import { AdminLogsPage } from "../../pages/admin/admin-logs-page"
import { ChallengeDetailPage } from "../../pages/challenges/challenge-detail-page"
import { DashboardPage } from "../../pages/dashboard/dashboard-page"
import { LeaderboardPage } from "../../pages/leaderboard/leaderboard-page"
import { TrackLeaderboardPage } from "../../pages/leaderboard/track-leaderboard-page"
import { LoginPage } from "../../pages/auth/login-page"
import { NotFoundPage } from "../../pages/not-found-page"
import { RegisterPage } from "../../pages/auth/register-page"
import { TrackDetailPage } from "../../pages/tracks/track-detail-page"
import { TrackListPage } from "../../pages/tracks/track-list-page"

export const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      <Route element={<MainLayout />}>
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/leaderboard"
          element={
            <ProtectedRoute>
              <LeaderboardPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/tracks"
          element={
            <ProtectedRoute>
              <TrackListPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/tracks/:slug"
          element={
            <ProtectedRoute>
              <TrackDetailPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/challenges/:slug"
          element={
            <ProtectedRoute>
              <ChallengeDetailPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/tracks/:trackId/leaderboard"
          element={
            <ProtectedRoute>
              <TrackLeaderboardPage />
            </ProtectedRoute>
          }
        />
      </Route>

      <Route
        path="/admin"
        element={
          <ProtectedRoute>
            <AdminRoute>
              <AdminLayout />
            </AdminRoute>
          </ProtectedRoute>
        }
      >
        <Route index element={<AdminDashboardPage />} />
        <Route path="challenges" element={<AdminChallengesPage />} />
        <Route path="logs" element={<AdminLogsPage />} />
      </Route>

      <Route element={<MainLayout />}>
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}
