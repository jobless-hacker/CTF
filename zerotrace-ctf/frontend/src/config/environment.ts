const configuredApiBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim()
const allowEphemeralTunnel = import.meta.env.VITE_ALLOW_EPHEMERAL_TUNNEL === "true"
const browserOrigin = typeof window === "undefined" ? "" : window.location.origin
const isEphemeralTunnel = (url: string) => /(^https?:\/\/)?[a-z0-9.-]+\.trycloudflare\.com(?:\/|$)/i.test(
  url.replace(/\/+$/, ""),
)

const shouldRejectConfiguredUrl = Boolean(
  configuredApiBaseUrl
  && import.meta.env.PROD
  && !allowEphemeralTunnel
  && isEphemeralTunnel(configuredApiBaseUrl),
)

const defaultApiBaseUrl = import.meta.env.DEV
  ? "http://localhost:8000"
  : browserOrigin

export const ENV = {
  API_BASE_URL: configuredApiBaseUrl && configuredApiBaseUrl.length > 0 && !shouldRejectConfiguredUrl
    ? configuredApiBaseUrl
    : defaultApiBaseUrl,
}

if (shouldRejectConfiguredUrl) {
  console.warn(
    "[env] Ignoring VITE_API_BASE_URL because temporary trycloudflare domains are not allowed in production builds. Set VITE_ALLOW_EPHEMERAL_TUNNEL=true only for temporary emergency testing.",
  )
}
