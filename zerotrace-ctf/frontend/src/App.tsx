import { BrowserRouter, HashRouter } from "react-router-dom"

import { AppRoutes } from "./app/router/routes"

const shouldUseHashRouter = import.meta.env.PROD
  && typeof window !== "undefined"
  && window.location.hostname.endsWith("github.io")

function App() {
  const Router = shouldUseHashRouter ? HashRouter : BrowserRouter

  return (
    <Router basename={import.meta.env.BASE_URL}>
      <AppRoutes />
    </Router>
  )
}

export default App
