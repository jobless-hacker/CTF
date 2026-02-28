const configuredApiBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim()
const browserOrigin = typeof window === "undefined" ? "" : window.location.origin
const defaultApiBaseUrl = import.meta.env.DEV
  ? "http://localhost:8000"
  : browserOrigin

export const ENV = {
  API_BASE_URL: configuredApiBaseUrl && configuredApiBaseUrl.length > 0
    ? configuredApiBaseUrl
    : defaultApiBaseUrl,
}
