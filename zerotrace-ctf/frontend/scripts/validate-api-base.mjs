const apiBaseUrl = process.env.VITE_API_BASE_URL?.trim()
const allowEphemeralTunnel = process.env.VITE_ALLOW_EPHEMERAL_TUNNEL === "true"

if (!apiBaseUrl) {
  process.exit(0)
}

const isTemporaryTunnel = /(^https?:\/\/)?[a-z0-9.-]+\.trycloudflare\.com(?:\/|$)/i.test(apiBaseUrl)

if (isTemporaryTunnel && !allowEphemeralTunnel) {
  console.error(
    [
      "Build blocked: VITE_API_BASE_URL points to a temporary trycloudflare domain.",
      "Use a stable backend URL before deploying the frontend.",
      "If this is an emergency temporary deployment, set VITE_ALLOW_EPHEMERAL_TUNNEL=true.",
    ].join(" "),
  )
  process.exit(1)
}
