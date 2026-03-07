import { useEffect, useMemo, useState } from "react"
import { Link, useParams } from "react-router-dom"

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
  const { slug } = useParams<{ slug: string }>()
  const { moduleGroups, challenges, isLoading, error } = useTrackChallengeModules(slug)
  const { data: tracks } = useTracks()
  const [query, setQuery] = useState("")
  const [difficultyFilter, setDifficultyFilter] = useState<"all" | "easy" | "medium" | "hard">("all")
  const [activeModuleKey, setActiveModuleKey] = useState<string | null>(null)
  const [collapsedModules, setCollapsedModules] = useState<Set<string>>(new Set())

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

  const currentTrack = tracks?.find((track) => track.slug === slug)
  const normalizedQuery = query.trim().toLowerCase()

  const filteredModuleGroups = useMemo(
    () =>
      moduleGroups
        .map((moduleGroup) => {
          const filteredChallenges = moduleGroup.challenges.filter((challenge) => {
            const matchesDifficulty = difficultyFilter === "all" || challenge.difficulty === difficultyFilter
            const matchesQuery =
              !normalizedQuery || `${challenge.title} ${challenge.slug} ${moduleGroup.moduleName}`.toLowerCase().includes(normalizedQuery)
            return matchesDifficulty && matchesQuery
          })

          return {
            ...moduleGroup,
            challenges: filteredChallenges,
            challengeCount: filteredChallenges.length,
            totalXP: filteredChallenges.reduce((sum, challenge) => sum + challenge.points, 0),
          }
        })
        .filter((moduleGroup) => moduleGroup.challenges.length > 0),
    [difficultyFilter, moduleGroups, normalizedQuery],
  )

  useEffect(() => {
    if (filteredModuleGroups.length === 0) {
      setActiveModuleKey(null)
      return
    }
    const hasActive = filteredModuleGroups.some((moduleGroup) => moduleGroup.moduleKey === activeModuleKey)
    if (!hasActive) {
      setActiveModuleKey(filteredModuleGroups[0]?.moduleKey ?? null)
    }
  }, [activeModuleKey, filteredModuleGroups])

  const visibleChallengeCount = filteredModuleGroups.reduce((sum, moduleGroup) => sum + moduleGroup.challenges.length, 0)
  const firstVisibleChallenge = filteredModuleGroups[0]?.challenges[0] ?? null

  const moduleIds = filteredModuleGroups.map((moduleGroup) => moduleGroup.moduleKey)
  const areAllCollapsed = moduleIds.length > 0 && moduleIds.every((moduleId) => collapsedModules.has(moduleId))

  const handleToggleModule = (moduleKey: string) => {
    setCollapsedModules((previous) => {
      const next = new Set(previous)
      if (next.has(moduleKey)) {
        next.delete(moduleKey)
      } else {
        next.add(moduleKey)
      }
      return next
    })
  }

  const handleModuleJump = (moduleKey: string) => {
    setActiveModuleKey(moduleKey)
    const element = document.getElementById(`module-${moduleKey}`)
    if (element) {
      element.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  const handleCollapseAll = () => {
    setCollapsedModules(new Set(moduleIds))
  }

  const handleExpandAll = () => {
    setCollapsedModules(new Set())
  }

  return (
    <div className="zt-page zt-page--vector">
      <div className="zt-hero">
        <div>
          <p className="zt-kicker">CTF Mission Board</p>
          <h1 className="zt-heading mt-1">{currentTrack?.name ?? "Challenges"}</h1>
          <p className="zt-subheading mt-2">
            Foundations challenges are now grouped as operations modules with quick navigation and visual priority cues.
          </p>
          <div className="zt-hero-meta mt-4">
            <span className="zt-pill">{filteredModuleGroups.length} modules</span>
            <span className="zt-pill">{visibleChallengeCount} challenges visible</span>
            <span className="zt-pill">{challenges.length} total in track</span>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            {firstVisibleChallenge ? (
              <Link to={`/challenges/${firstVisibleChallenge.slug}`} className="zt-button zt-button--primary">
                Start First Visible Challenge
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
            <label htmlFor="challenge-difficulty" className="zt-field-label">
              Difficulty
            </label>
            <select
              id="challenge-difficulty"
              value={difficultyFilter}
              onChange={(event) => setDifficultyFilter(event.target.value as "all" | "easy" | "medium" | "hard")}
              className="zt-select"
            >
              <option value="all">All</option>
              <option value="easy">Easy</option>
              <option value="medium">Medium</option>
              <option value="hard">Hard</option>
            </select>
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              className="zt-button zt-button--ghost"
              onClick={() => {
                setQuery("")
                setDifficultyFilter("all")
              }}
            >
              Reset Filters
            </button>
            <button
              type="button"
              className="zt-button zt-button--ghost"
              onClick={areAllCollapsed ? handleExpandAll : handleCollapseAll}
            >
              {areAllCollapsed ? "Expand All Modules" : "Collapse All Modules"}
            </button>
          </div>
        </div>
      </section>

      {filteredModuleGroups.length > 0 ? (
        <div className="zt-vector-layout">
          <aside className="zt-module-rail">
            <p className="zt-kicker">Module Navigator</p>
            <div className="mt-3 space-y-2">
              {filteredModuleGroups.map((moduleGroup) => {
                const isActive = activeModuleKey === moduleGroup.moduleKey
                return (
                  <button
                    key={moduleGroup.moduleKey}
                    type="button"
                    onClick={() => handleModuleJump(moduleGroup.moduleKey)}
                    className={`zt-module-node ${isActive ? "zt-module-node--active" : ""}`}
                  >
                    <span className="zt-module-node-code">{moduleGroup.moduleCode}</span>
                    <span className="zt-module-node-name">{moduleGroup.moduleName}</span>
                    <span className="zt-module-node-meta">
                      {moduleGroup.challengeCount} challenges • {moduleGroup.totalXP} XP
                    </span>
                  </button>
                )
              })}
            </div>
          </aside>

          <div className="space-y-5">
            {filteredModuleGroups.map((moduleGroup) => {
              const moduleId = `module-${moduleGroup.moduleKey}`
              const isCollapsed = collapsedModules.has(moduleGroup.moduleKey)

              return (
                <section
                  key={moduleGroup.moduleKey}
                  id={moduleId}
                  className={`zt-panel zt-module-panel ${activeModuleKey === moduleGroup.moduleKey ? "zt-module-panel--active" : ""}`}
                >
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <p className="zt-kicker">{moduleGroup.moduleCode}</p>
                      <h2 className="zt-panel-title mt-1">{moduleGroup.moduleName}</h2>
                    </div>
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="zt-pill">{moduleGroup.challengeCount} challenges</span>
                      <span className="zt-pill">{moduleGroup.totalXP} XP</span>
                      <button
                        type="button"
                        onClick={() => handleToggleModule(moduleGroup.moduleKey)}
                        className="zt-button zt-button--ghost"
                      >
                        {isCollapsed ? "Expand" : "Collapse"}
                      </button>
                    </div>
                  </div>

                  {!isCollapsed ? (
                    <div className="zt-challenge-grid mt-4">
                      {moduleGroup.challenges.map((challenge) => (
                        <Link key={challenge.slug} to={`/challenges/${challenge.slug}`} className="zt-challenge-card">
                          <div className="flex items-start justify-between gap-3">
                            <span className={`zt-difficulty-chip zt-difficulty-chip--${challenge.difficulty}`}>
                              {challenge.difficulty}
                            </span>
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
                  ) : null}
                </section>
              )
            })}
          </div>
        </div>
      ) : (
        <div className="zt-alert zt-alert--info">
          {challenges.length > 0 ? "No challenges match your filters." : "No published challenges available."}
        </div>
      )}
    </div>
  )
}
