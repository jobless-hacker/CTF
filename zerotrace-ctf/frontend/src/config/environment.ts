const configuredApiBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim()
const defaultApiBaseUrl = import.meta.env.DEV ? "http://localhost:8000" : ""

export const ENV = {
  API_BASE_URL: configuredApiBaseUrl && configuredApiBaseUrl.length > 0
    ? configuredApiBaseUrl
    : defaultApiBaseUrl,
}
