const configuredApiBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim()
const allowEphemeralTunnel = import.meta.env.VITE_ALLOW_EPHEMERAL_TUNNEL === "true"
const browserOrigin = typeof window === "undefined" ? "" : window.location.origin
const isGithubPages = typeof window !== "undefined" && window.location.hostname.endsWith("github.io")
const runtimeApiStorageKey = "zerotrace.apiBaseUrl"
const isEphemeralTunnel = (url: string) => /(^https?:\/\/)?[a-z0-9.-]+\.trycloudflare\.com(?:\/|$)/i.test(
  url.replace(/\/+$/, ""),
)
const normalizeApiBaseUrl = (value?: string | null) => value?.trim().replace(/\/+$/, "") ?? ""

const readRuntimeApiBaseUrl = () => {
  if (typeof window === "undefined") {
    return ""
  }

  const searchParams = new URLSearchParams(window.location.search)
  const fromSearch = searchParams.get("api") ?? searchParams.get("apiBaseUrl")

  const hashQueryIndex = window.location.hash.indexOf("?")
  const hashParams = hashQueryIndex >= 0
    ? new URLSearchParams(window.location.hash.slice(hashQueryIndex + 1))
    : null
  const fromHash = hashQueryIndex >= 0
    ? hashParams?.get("api") ?? hashParams?.get("apiBaseUrl")
    : null

  const fromRuntime = normalizeApiBaseUrl(fromSearch ?? fromHash)
  if (fromRuntime) {
    window.localStorage.setItem(runtimeApiStorageKey, fromRuntime)
    return fromRuntime
  }

  return normalizeApiBaseUrl(window.localStorage.getItem(runtimeApiStorageKey))
}

const runtimeApiBaseUrl = readRuntimeApiBaseUrl()

const shouldRejectConfiguredUrl = Boolean(
  configuredApiBaseUrl
  && import.meta.env.PROD
  && !allowEphemeralTunnel
  && isEphemeralTunnel(configuredApiBaseUrl),
)

const defaultApiBaseUrl = import.meta.env.DEV
  ? "http://localhost:8000"
  : browserOrigin
const configuredResolvedApiBaseUrl = configuredApiBaseUrl && configuredApiBaseUrl.length > 0 && !shouldRejectConfiguredUrl
  ? normalizeApiBaseUrl(configuredApiBaseUrl)
  : ""

export const ENV = {
  API_BASE_URL: runtimeApiBaseUrl
    || configuredResolvedApiBaseUrl
    || defaultApiBaseUrl,
}

if (shouldRejectConfiguredUrl) {
  console.warn(
    "[env] Ignoring VITE_API_BASE_URL because temporary trycloudflare domains are not allowed in production builds. Set VITE_ALLOW_EPHEMERAL_TUNNEL=true only for temporary emergency testing.",
  )
}

if (import.meta.env.PROD && isGithubPages && !runtimeApiBaseUrl && !configuredResolvedApiBaseUrl) {
  console.warn(
    "[env] No public backend URL is configured for GitHub Pages. Set VITE_API_BASE_URL at build time or open the app with ?api=<backend-url> to bind it to a reachable backend.",
  )
}
