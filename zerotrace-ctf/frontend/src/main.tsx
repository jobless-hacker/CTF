import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import ReactDOM from "react-dom/client"
import "@fontsource/orbitron/index.css"
import "@fontsource/jetbrains-mono/index.css"

import App from "./App"
import { AppErrorBoundary } from "./app/error-boundary/app-error-boundary"
import { AuthProvider } from "./context/auth-context"
import "./index.css"

const queryClient = new QueryClient()

ReactDOM.createRoot(document.getElementById("root")!).render(
  <QueryClientProvider client={queryClient}>
    <AppErrorBoundary>
      <AuthProvider>
        <App />
      </AuthProvider>
    </AppErrorBoundary>
  </QueryClientProvider>,
)
