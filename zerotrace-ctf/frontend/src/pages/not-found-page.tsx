import { Link } from "react-router-dom"

export const NotFoundPage = () => {
  return (
    <div className="zt-page zt-page--narrow">
      <div className="zt-panel text-center">
        <p className="zt-kicker">Signal Lost</p>
        <h1 className="zt-heading mt-2">Page Not Found</h1>
        <p className="zt-subheading mt-3">The requested route does not exist.</p>
        <Link to="/" className="zt-button zt-button--primary mt-6">
          Go to Dashboard
        </Link>
      </div>
    </div>
  )
}
