import { Component, type ErrorInfo, type ReactNode } from "react"

interface AppErrorBoundaryProps {
  children: ReactNode
}

interface AppErrorBoundaryState {
  hasError: boolean
}

export class AppErrorBoundary extends Component<AppErrorBoundaryProps, AppErrorBoundaryState> {
  state: AppErrorBoundaryState = {
    hasError: false,
  }

  static getDerivedStateFromError(): AppErrorBoundaryState {
    return { hasError: true }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("[AppErrorBoundary] Unhandled render error", error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="zt-page">
          <section className="zt-panel text-center">
            <p className="zt-kicker">Runtime Error</p>
            <h1 className="zt-heading mt-2">Something went wrong</h1>
            <p className="zt-subheading mt-3">
              The app hit an unexpected error. Reload the page to continue.
            </p>
            <button type="button" className="zt-button zt-button--primary mt-6" onClick={() => window.location.reload()}>
              Reload
            </button>
          </section>
        </div>
      )
    }

    return this.props.children
  }
}
