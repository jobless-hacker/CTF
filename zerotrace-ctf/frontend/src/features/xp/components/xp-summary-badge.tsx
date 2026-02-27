import { useCurrentUserXP } from "../hooks/useCurrentUserXP"

export const XPSummaryBadge = () => {
  const { data, isLoading, isError } = useCurrentUserXP()

  if (isLoading) {
    return <div className="zt-pill">XP: ...</div>
  }

  if (isError) {
    return <div className="zt-pill">XP: -</div>
  }

  return <div className="zt-pill border-[color:var(--zt-border-strong)] text-[color:var(--zt-accent)]">XP: {data?.total_xp ?? 0}</div>
}
