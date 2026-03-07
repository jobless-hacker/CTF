import { useEffect, useMemo, useState } from "react"
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom"

import { useTrackChallengeModules } from "../../features/tracks/hooks/useTrackChallengeModules"
import { useTracks } from "../../features/tracks/hooks/useTracks"

const getChallengeCode = (slug: string) => {
  const match = slug.match(/^m(\d+)-(\d+)/i)
  if (!match) {
    return slug.toUpperCase()
  }
  return `M${match[1]}-${match[2]}`
}

export const TrackDetailPage = () => {
  const { slug, moduleCode } = useParams<{ slug: string; moduleCode?: string }>()
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const { moduleGroups, challenges, isLoading, error } = useTrackChallengeModules(slug)
  const { data: tracks } = useTracks()
  const [query, setQuery] = useState("")
  const [activeDifficultyTab, setActiveDifficultyTab] = useState<"all" | "easy" | "medium">("all")
  const [activeModuleKey, setActiveModuleKey] = useState<string | null>(null)

  const safeModuleGroups = moduleGroups ?? []
  const safeChallenges = challenges ?? []
  const currentTrack = tracks?.find((track) => track.slug === slug)
  const normalizedQuery = query.trim().toLowerCase()
  const routeModuleParam = moduleCode?.trim().toUpperCase() ?? null
  const moduleQueryParam = searchParams.get("module")?.trim().toUpperCase() ?? null

  const filteredModuleGroups = useMemo(
    () =>
      safeModuleGroups
        .map((moduleGroup) => {
          const filteredChallenges = moduleGroup.challenges.filter((challenge) => {
            const matchesQuery =
              !normalizedQuery || `${challenge.title} ${challenge.slug} ${moduleGroup.moduleName}`.toLowerCase().includes(normalizedQuery)
            return matchesQuery
          })

          return {
            ...moduleGroup,
            challenges: filteredChallenges,
            challengeCount: filteredChallenges.length,
            totalXP: filteredChallenges.reduce((sum, challenge) => sum + challenge.points, 0),
          }
        })
        .filter((moduleGroup) => moduleGroup.challenges.length > 0),
    [normalizedQuery, safeModuleGroups],
  )

  useEffect(() => {
    if (filteredModuleGroups.length === 0) {
      setActiveModuleKey(null)
      return
    }

    const hasActive = activeModuleKey
      ? filteredModuleGroups.some((moduleGroup) => moduleGroup.moduleKey === activeModuleKey)
      : false
    if (hasActive) {
      return
    }

    if (routeModuleParam) {
      const fromRoute = filteredModuleGroups.find(
        (moduleGroup) =>
          moduleGroup.moduleCode.toUpperCase() === routeModuleParam || moduleGroup.moduleKey.toUpperCase() === routeModuleParam,
      )
      if (fromRoute) {
        setActiveModuleKey(fromRoute.moduleKey)
        return
      }
    }

    if (moduleQueryParam) {
      const fromQuery = filteredModuleGroups.find(
        (moduleGroup) =>
          moduleGroup.moduleCode.toUpperCase() === moduleQueryParam || moduleGroup.moduleKey.toUpperCase() === moduleQueryParam,
      )
      if (fromQuery) {
        setActiveModuleKey(fromQuery.moduleKey)
        return
      }
    }

    setActiveModuleKey(filteredModuleGroups[0]?.moduleKey ?? null)
  }, [activeModuleKey, filteredModuleGroups, moduleQueryParam, routeModuleParam])

  const activeModule =
    filteredModuleGroups.find((moduleGroup) => moduleGroup.moduleKey === activeModuleKey)
    ?? filteredModuleGroups[0]
    ?? null

  useEffect(() => {
    if (!activeModule) {
      return
    }

    const currentParam = searchParams.get("module")?.trim().toUpperCase() ?? ""
    const targetParam = activeModule.moduleCode.toUpperCase()
    if (currentParam === targetParam) {
      return
    }

    const next = new URLSearchParams(searchParams)
    next.set("module", activeModule.moduleCode)
    setSearchParams(next, { replace: true })
  }, [activeModule, searchParams, setSearchParams])

  useEffect(() => {
    if (!slug || !activeModule) {
      return
    }
    const currentRouteModule = moduleCode?.trim().toUpperCase() ?? ""
    const targetRouteModule = activeModule.moduleCode.toUpperCase()
    if (currentRouteModule === targetRouteModule) {
      return
    }
    navigate(`/tracks/${slug}/module/${targetRouteModule}`, { replace: true })
  }, [activeModule, moduleCode, navigate, slug])

  const activeModuleVisibleChallenges = useMemo(() => {
    if (!activeModule) {
      return []
    }
    if (activeDifficultyTab === "all") {
      return activeModule.challenges
    }
    return activeModule.challenges.filter((challenge) => challenge.difficulty === activeDifficultyTab)
  }, [activeDifficultyTab, activeModule])

  const activeModuleIndex = activeModule
    ? filteredModuleGroups.findIndex((moduleGroup) => moduleGroup.moduleKey === activeModule.moduleKey)
    : -1
  const previousModule = activeModuleIndex > 0 ? filteredModuleGroups[activeModuleIndex - 1] : null
  const nextModule =
    activeModuleIndex >= 0 && activeModuleIndex < filteredModuleGroups.length - 1
      ? filteredModuleGroups[activeModuleIndex + 1]
      : null

  const visibleChallengeCount = filteredModuleGroups.reduce((sum, moduleGroup) => sum + moduleGroup.challenges.length, 0)
  const firstVisibleChallenge = activeModuleVisibleChallenges[0] ?? null

  const handleSelectModule = (moduleKey: string) => {
    const selectedModule = filteredModuleGroups.find((moduleGroup) => moduleGroup.moduleKey === moduleKey)
    if (!selectedModule || !slug) {
      return
    }
    setActiveModuleKey(moduleKey)
    navigate(`/tracks/${slug}/module/${selectedModule.moduleCode}`)
  }

  if (!slug) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">Invalid track.</div>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading challenges...</div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">{error.message}</div>
      </div>
    )
  }

  return (
    <div className="zt-page zt-page--vector">
      <div className="zt-hero">
        <div>
          <p className="zt-kicker">CTF Mission Board</p>
          <h1 className="zt-heading mt-1">{currentTrack?.name ?? "Challenges"}</h1>
          <p className="zt-subheading mt-2">Selecting a module now loads that module board directly instead of scrolling the page.</p>
          <div className="zt-hero-meta mt-4">
            <span className="zt-pill">{filteredModuleGroups.length} modules</span>
            <span className="zt-pill">{visibleChallengeCount} challenges visible</span>
            <span className="zt-pill">{safeChallenges.length} total in track</span>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            {firstVisibleChallenge ? (
              <Link to={`/challenges/${firstVisibleChallenge.slug}`} className="zt-button zt-button--primary">
                Start Active Module
              </Link>
            ) : null}
            {currentTrack ? (
              <Link to={`/tracks/${currentTrack.id}/leaderboard`} className="zt-button zt-button--ghost">
                Track Leaderboard
              </Link>
            ) : null}
          </div>
        </div>
      </div>

      <section className="zt-panel">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-end">
          <div className="flex-1">
            <label htmlFor="challenge-search" className="zt-field-label">
              Search Challenges
            </label>
            <input
              id="challenge-search"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search by title, slug, or module..."
              className="zt-input"
              autoComplete="off"
            />
          </div>

          <div className="w-full lg:w-64">
            <label className="zt-field-label">Difficulty</label>
            <div className="zt-alert zt-alert--info">Use module tabs below</div>
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className="zt-button zt-button--ghost"
              onClick={() => {
                setQuery("")
                setActiveDifficultyTab("all")
              }}
            >
              Reset Filters
            </button>
          </div>
        </div>
      </section>

      {filteredModuleGroups.length > 0 && activeModule ? (
        <div className="zt-vector-layout">
          <aside className="zt-module-rail">
            <p className="zt-kicker">Module Navigator</p>
            <div className="mt-3 space-y-2">
              {filteredModuleGroups.map((moduleGroup) => {
                const isActive = activeModule.moduleKey === moduleGroup.moduleKey
                return (
                  <button
                    key={moduleGroup.moduleKey}
                    type="button"
                    onClick={() => handleSelectModule(moduleGroup.moduleKey)}
                    className={`zt-module-node ${isActive ? "zt-module-node--active" : ""}`}
                  >
                    <span className="zt-module-node-code">{moduleGroup.moduleCode}</span>
                    <span className="zt-module-node-name">{moduleGroup.moduleName}</span>
                    <span className="zt-module-node-meta">
                      {moduleGroup.challengeCount} challenges | {moduleGroup.totalXP} XP
                    </span>
                  </button>
                )
              })}
            </div>
          </aside>

          <section key={activeModule.moduleKey} className="zt-panel zt-module-panel zt-module-panel--active">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="zt-kicker">{activeModule.moduleCode}</p>
                <h2 className="zt-panel-title mt-1">{activeModule.moduleName}</h2>
              </div>
              <div className="flex flex-wrap items-center gap-2">
                <span className="zt-pill">{activeModule.challengeCount} challenges</span>
                <span className="zt-pill">{activeModule.totalXP} XP</span>
              </div>
            </div>

            <div className="mt-4 flex flex-wrap gap-2">
              <button
                type="button"
                className="zt-button zt-button--ghost"
                onClick={() => previousModule && handleSelectModule(previousModule.moduleKey)}
                disabled={!previousModule}
              >
                Previous Module
              </button>
              <button
                type="button"
                className="zt-button zt-button--ghost"
                onClick={() => nextModule && handleSelectModule(nextModule.moduleKey)}
                disabled={!nextModule}
              >
                Next Module
              </button>
            </div>

            <div className="mt-4 flex flex-wrap gap-2">
              <button
                type="button"
                className={`zt-button ${activeDifficultyTab === "all" ? "zt-button--primary" : "zt-button--ghost"}`}
                onClick={() => setActiveDifficultyTab("all")}
              >
                All
              </button>
              <button
                type="button"
                className={`zt-button ${activeDifficultyTab === "easy" ? "zt-button--primary" : "zt-button--ghost"}`}
                onClick={() => setActiveDifficultyTab("easy")}
              >
                Easy
              </button>
              <button
                type="button"
                className={`zt-button ${activeDifficultyTab === "medium" ? "zt-button--primary" : "zt-button--ghost"}`}
                onClick={() => setActiveDifficultyTab("medium")}
              >
                Medium
              </button>
            </div>

            <div className="zt-challenge-grid mt-4">
              {activeModuleVisibleChallenges.map((challenge) => (
                <Link key={challenge.slug} to={`/challenges/${challenge.slug}`} className="zt-challenge-card">
                  <div className="flex items-start justify-between gap-3">
                    <span className={`zt-difficulty-chip zt-difficulty-chip--${challenge.difficulty}`}>{challenge.difficulty}</span>
                    <span className="zt-pill">{challenge.points} pts</span>
                  </div>
                  <h3 className="mt-3 text-base font-semibold text-cyber-text">{challenge.title}</h3>
                  <p className="zt-subheading mt-2">{challenge.slug}</p>
                  <div className="mt-4 flex items-center justify-between">
                    <span className="zt-kicker">{getChallengeCode(challenge.slug)}</span>
                    <span className="text-sm text-cyber-neon">Enter Challenge</span>
                  </div>
                </Link>
              ))}
            </div>

            {activeModuleVisibleChallenges.length === 0 ? (
              <div className="zt-alert zt-alert--info mt-4">No challenges in this module for selected difficulty.</div>
            ) : null}
          </section>
        </div>
      ) : (
        <div className="zt-alert zt-alert--info">
          {safeChallenges.length > 0 ? "No challenges match your filters." : "No published challenges available."}
        </div>
      )}
    </div>
  )
}
