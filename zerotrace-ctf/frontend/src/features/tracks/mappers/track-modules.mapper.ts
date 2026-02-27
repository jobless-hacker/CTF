import type { TrackChallengeModuleGroup, TrackChallengeSummary } from "../types/track.types"

const MODULE_SLUG_PATTERN = /^m(\d+)-/i
const MODULE_TITLE_PATTERN = /^m(\d+):\s*([^-]+?)(?:\s*-\s*|$)/i

const parseModuleFromChallenge = (challenge: TrackChallengeSummary): { moduleOrder: number; moduleCode: string; moduleName: string } => {
  const slugMatch = challenge.slug.match(MODULE_SLUG_PATTERN)
  const titleMatch = challenge.title.match(MODULE_TITLE_PATTERN)

  if (!slugMatch) {
    return {
      moduleOrder: Number.MAX_SAFE_INTEGER,
      moduleCode: "M?",
      moduleName: "Ungrouped Challenges",
    }
  }

  const order = Number.parseInt(slugMatch[1], 10)
  const moduleCode = `M${order}`
  const titleName = titleMatch?.[2]?.trim()

  return {
    moduleOrder: Number.isFinite(order) ? order : Number.MAX_SAFE_INTEGER,
    moduleCode,
    moduleName: titleName || `Module ${moduleCode}`,
  }
}

export const groupTrackChallengesByModule = (challenges: TrackChallengeSummary[]): TrackChallengeModuleGroup[] => {
  const groups = new Map<string, TrackChallengeModuleGroup>()

  for (const challenge of challenges) {
    const parsed = parseModuleFromChallenge(challenge)
    const moduleKey = `${parsed.moduleOrder}:${parsed.moduleCode}`
    const existing = groups.get(moduleKey)

    if (!existing) {
      groups.set(moduleKey, {
        moduleKey,
        moduleCode: parsed.moduleCode,
        moduleName: parsed.moduleName,
        moduleOrder: parsed.moduleOrder,
        challengeCount: 1,
        totalXP: challenge.points,
        challenges: [challenge],
      })
      continue
    }

    existing.challenges.push(challenge)
    existing.challengeCount += 1
    existing.totalXP += challenge.points
  }

  const sortedGroups = Array.from(groups.values())
    .sort((left, right) => {
      if (left.moduleOrder !== right.moduleOrder) {
        return left.moduleOrder - right.moduleOrder
      }
      return left.moduleName.localeCompare(right.moduleName)
    })
    .map((group) => ({
      ...group,
      challenges: [...group.challenges].sort((left, right) => left.title.localeCompare(right.title)),
    }))

  return sortedGroups
}
