import type { ReactNode } from "react"

import { CyberPanel } from "../components/common/cyber-panel"

type AuthLayoutProps = {
  panelTitle: string
  panelSubtitle: string
  children: ReactNode
  footer?: ReactNode
}

export const AuthLayout = ({ panelTitle, panelSubtitle, children, footer }: AuthLayoutProps) => {
  return (
    <div className="zt-auth-screen relative scan-overlay">
      <div className="absolute inset-0 cyber-grid opacity-40" aria-hidden />
      <div className="absolute inset-0 bg-gradient-to-b from-black via-cyber-bg to-black opacity-80" aria-hidden />
      <div
        className="absolute inset-0 bg-[radial-gradient(circle_at_70%_30%,rgba(0,255,156,0.15),transparent_60%)]"
        aria-hidden
      />
      <div
        className="absolute inset-0 bg-[radial-gradient(circle_at_20%_80%,rgba(0,255,156,0.1),transparent_60%)]"
        aria-hidden
      />

      <div className="zt-auth-content">
        <div className="zt-auth-shell">
          <header className="zt-auth-header">
            <h1 className="zt-auth-brand font-orbitron text-6xl tracking-[0.4em] text-cyber-neon drop-shadow-[0_0_25px_rgba(0,255,156,0.8)] glitch-text">
              ZEROTRACE CTF
            </h1>
            <p className="text-xs tracking-[0.6em] text-cyber-textMuted uppercase">
              INFILTRATE • EXPLOIT • CAPTURE THE FLAG
            </p>
          </header>

          <section className="zt-auth-frame zt-terminal-frame">
            <div className="zt-terminal-corner zt-terminal-corner--tl" aria-hidden />
            <div className="zt-terminal-corner zt-terminal-corner--tr" aria-hidden />
            <div className="zt-terminal-corner zt-terminal-corner--bl" aria-hidden />
            <div className="zt-terminal-corner zt-terminal-corner--br" aria-hidden />

            <img
              src="/skull.svg"
              alt=""
              className="absolute bottom-[-40px] right-[-100px] w-72 animate-pulse opacity-10 blur-[1px] skull-glow"
              aria-hidden
            />

            <CyberPanel className="zt-auth-panel cyber-pulse shadow-[0_0_60px_rgba(0,255,156,0.25),inset_0_0_40px_rgba(0,255,156,0.05)]">
              <h2 className="zt-auth-panel-title font-orbitron">{panelTitle}</h2>
              <div className="my-4 border-t border-cyber-neon/20" />
              <p className="text-xs tracking-widest text-cyber-textMuted uppercase">{panelSubtitle}</p>

              <div className="mt-6">{children}</div>
              {footer ? <div className="mt-5">{footer}</div> : null}
            </CyberPanel>
          </section>
        </div>
      </div>
    </div>
  )
}
