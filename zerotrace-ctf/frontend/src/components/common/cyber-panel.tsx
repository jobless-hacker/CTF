import type { ReactNode } from "react"

export const CyberPanel = ({ children, className = "" }: { children: ReactNode; className?: string }) => {
  return (
    <div
      className={`relative rounded-xl border border-cyber-border bg-cyber-panel/80 p-8 backdrop-blur-xl shadow-[0_0_30px_rgba(0,255,156,0.15)] ${className}`}
    >
      {children}
    </div>
  )
}
