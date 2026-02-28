const apiBaseUrl = process.env.VITE_API_BASE_URL?.trim()

if (!apiBaseUrl) {
  process.exit(0)
}

const isTemporaryTunnel = /(^https?:\/\/)?[a-z0-9.-]+\.trycloudflare\.com(?:\/|$)/i.test(apiBaseUrl)

if (isTemporaryTunnel) {
  console.error(
    [
      "Build blocked: VITE_API_BASE_URL points to a temporary trycloudflare domain.",
      "Use a stable backend URL before deploying the frontend.",
    ].join(" "),
  )
  process.exit(1)
}
