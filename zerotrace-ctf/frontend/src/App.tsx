import { BrowserRouter, HashRouter } from "react-router-dom"

import { AppRoutes } from "./app/router/routes"

const shouldUseHashRouter = import.meta.env.PROD
  && typeof window !== "undefined"
  && window.location.hostname.endsWith("github.io")

function App() {
  if (shouldUseHashRouter) {
    return (
      <HashRouter>
        <AppRoutes />
      </HashRouter>
    )
  }

  return (
    <BrowserRouter basename={import.meta.env.BASE_URL}>
      <AppRoutes />
    </BrowserRouter>
  )
}

export default App
