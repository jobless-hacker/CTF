/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        cyber: {
          bg: "#03060A",
          panel: "#0D1117",
          neon: "#00FF9C",
          neonSoft: "#00C97A",
          border: "#15202B",
          textPrimary: "#E6F1FF",
          textMuted: "#6B7C8C",
        },
      },
      fontFamily: {
        orbitron: ["Orbitron", "sans-serif"],
        mono: ["JetBrains Mono", "monospace"],
      },
    },
  },
  plugins: [],
}
