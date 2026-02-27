import { useMemo, useState, type FormEvent } from "react"

import {
  challengeIdSchema,
  createAdminChallengeSchema,
  setChallengeFlagSchema,
} from "../../features/admin/schemas/admin.schemas"
import {
  useAdminCreateChallenge,
  useAdminPublishChallenge,
  useAdminSetFlag,
  useAdminUnpublishChallenge,
} from "../../features/admin/hooks/useAdminChallengeActions"
import { useAdminChallengeCatalog } from "../../features/admin/hooks/useAdminChallengeCatalog"
import { useAdminTracks } from "../../features/admin/hooks/useAdminTracks"

type CreateFormState = {
  track_id: string
  title: string
  slug: string
  description: string
  difficulty: "easy" | "medium" | "hard"
  points: string
}

type CreatedChallenge = {
  id: string
  slug: string
  is_published: boolean
}

const initialCreateForm: CreateFormState = {
  track_id: "",
  title: "",
  slug: "",
  description: "",
  difficulty: "easy",
  points: "100",
}

export const AdminChallengesPage = () => {
  const { data: tracks, isLoading: tracksLoading, error: tracksError } = useAdminTracks()
  const {
    data: catalog,
    isLoading: catalogLoading,
    error: catalogError,
  } = useAdminChallengeCatalog()

  const createMutation = useAdminCreateChallenge()
  const setFlagMutation = useAdminSetFlag()
  const publishMutation = useAdminPublishChallenge()
  const unpublishMutation = useAdminUnpublishChallenge()

  const [createForm, setCreateForm] = useState<CreateFormState>(initialCreateForm)
  const [actionForm, setActionForm] = useState<{ challenge_id: string; flag: string }>({
    challenge_id: "",
    flag: "",
  })
  const [recentlyCreated, setRecentlyCreated] = useState<CreatedChallenge[]>([])
  const [createError, setCreateError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const combinedChallenges = useMemo(() => {
    const fromCatalog =
      catalog?.map((item) => ({
        id: item.id,
        slug: item.slug,
        is_published: item.is_published,
      })) ?? []

    const merged = new Map<string, CreatedChallenge>()
    for (const challenge of fromCatalog) {
      merged.set(challenge.id, challenge)
    }
    for (const challenge of recentlyCreated) {
      merged.set(challenge.id, challenge)
    }
    return Array.from(merged.values())
  }, [catalog, recentlyCreated])

  const handleCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setCreateError(null)

    const points = Number.parseInt(createForm.points, 10)
    const parsed = createAdminChallengeSchema.safeParse({
      ...createForm,
      points,
    })
    if (!parsed.success) {
      setCreateError(parsed.error.issues[0]?.message ?? "Invalid challenge payload.")
      return
    }

    try {
      const created = await createMutation.mutateAsync(parsed.data)
      const createdChallenge: CreatedChallenge = {
        id: created.id,
        slug: created.slug,
        is_published: created.is_published,
      }
      setRecentlyCreated((previous) => [createdChallenge, ...previous.filter((item) => item.id !== created.id)])
      setActionForm((previous) => ({
        ...previous,
        challenge_id: created.id,
      }))
      setCreateForm(initialCreateForm)
    } catch (error) {
      if (error instanceof Error) {
        setCreateError(error.message)
      } else {
        setCreateError("Failed to create challenge.")
      }
    }
  }

  const handleSetFlag = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setActionError(null)

    const parsed = setChallengeFlagSchema.safeParse(actionForm)
    if (!parsed.success) {
      setActionError(parsed.error.issues[0]?.message ?? "Invalid flag payload.")
      return
    }

    try {
      await setFlagMutation.mutateAsync({
        challengeId: parsed.data.challenge_id,
        flag: parsed.data.flag,
      })
      setActionForm((previous) => ({ ...previous, flag: "" }))
    } catch (error) {
      if (error instanceof Error) {
        setActionError(error.message)
      } else {
        setActionError("Failed to set challenge flag.")
      }
    }
  }

  const handlePublish = async () => {
    setActionError(null)

    const parsed = challengeIdSchema.safeParse({ challenge_id: actionForm.challenge_id })
    if (!parsed.success) {
      setActionError(parsed.error.issues[0]?.message ?? "Invalid challenge identifier.")
      return
    }

    try {
      await publishMutation.mutateAsync({ challengeId: parsed.data.challenge_id })
      setRecentlyCreated((previous) =>
        previous.map((item) =>
          item.id === parsed.data.challenge_id
            ? {
                ...item,
                is_published: true,
              }
            : item,
        ),
      )
    } catch (error) {
      if (error instanceof Error) {
        setActionError(error.message)
      } else {
        setActionError("Failed to publish challenge.")
      }
    }
  }

  const handleUnpublish = async () => {
    setActionError(null)

    const parsed = challengeIdSchema.safeParse({ challenge_id: actionForm.challenge_id })
    if (!parsed.success) {
      setActionError(parsed.error.issues[0]?.message ?? "Invalid challenge identifier.")
      return
    }

    try {
      await unpublishMutation.mutateAsync({ challengeId: parsed.data.challenge_id })
      setRecentlyCreated((previous) =>
        previous.map((item) =>
          item.id === parsed.data.challenge_id
            ? {
                ...item,
                is_published: false,
              }
            : item,
        ),
      )
    } catch (error) {
      if (error instanceof Error) {
        setActionError(error.message)
      } else {
        setActionError("Failed to unpublish challenge.")
      }
    }
  }

  return (
    <div className="zt-page">
      <div>
        <p className="zt-kicker">Content Operations</p>
        <h1 className="zt-heading mt-1">Manage Challenges</h1>
        <p className="zt-subheading">Create, configure flags, and publish challenge content.</p>
      </div>

      <section className="zt-panel">
        <h2 className="zt-panel-title mb-4">Create Challenge</h2>

        <form onSubmit={handleCreate} className="zt-form-grid">
          <select
            value={createForm.track_id}
            onChange={(event) =>
              setCreateForm((previous) => ({
                ...previous,
                track_id: event.target.value,
              }))
            }
            className="zt-select"
            disabled={tracksLoading || createMutation.isPending}
          >
            <option value="">Select Track</option>
            {(tracks ?? []).map((track) => (
              <option key={track.id} value={track.id}>
                {track.name}
              </option>
            ))}
          </select>

          <input
            value={createForm.title}
            onChange={(event) =>
              setCreateForm((previous) => ({
                ...previous,
                title: event.target.value,
              }))
            }
            placeholder="Title"
            className="zt-input"
            disabled={createMutation.isPending}
          />

          <input
            value={createForm.slug}
            onChange={(event) =>
              setCreateForm((previous) => ({
                ...previous,
                slug: event.target.value,
              }))
            }
            placeholder="slug-example"
            className="zt-input"
            disabled={createMutation.isPending}
          />

          <input
            value={createForm.points}
            onChange={(event) =>
              setCreateForm((previous) => ({
                ...previous,
                points: event.target.value,
              }))
            }
            placeholder="Points"
            className="zt-input"
            disabled={createMutation.isPending}
          />

          <select
            value={createForm.difficulty}
            onChange={(event) =>
              setCreateForm((previous) => ({
                ...previous,
                difficulty: event.target.value as CreateFormState["difficulty"],
              }))
            }
            className="zt-select"
            disabled={createMutation.isPending}
          >
            <option value="easy">easy</option>
            <option value="medium">medium</option>
            <option value="hard">hard</option>
          </select>

          <input
            value={createForm.description}
            onChange={(event) =>
              setCreateForm((previous) => ({
                ...previous,
                description: event.target.value,
              }))
            }
            placeholder="Description"
            className="zt-input"
            disabled={createMutation.isPending}
          />

          <button
            type="submit"
            className="zt-button zt-button--primary md:col-span-2"
            disabled={createMutation.isPending}
          >
            {createMutation.isPending ? "Creating..." : "Create Challenge"}
          </button>
        </form>

        {createError ? <div className="zt-alert zt-alert--error mt-3">{createError}</div> : null}
        {createMutation.isSuccess ? (
          <div className="zt-alert zt-alert--success mt-3">Challenge created successfully.</div>
        ) : null}
        {tracksError ? <div className="zt-alert zt-alert--error mt-3">{tracksError.message}</div> : null}
      </section>

      <section className="zt-panel">
        <h2 className="zt-panel-title mb-4">Set Flag / Publish Control</h2>

        <div className="zt-subheading mb-3 mt-0">
          Use a recently created challenge ID or pick one from the catalog below.
        </div>

        <div className="mb-4 flex flex-wrap gap-2">
          {combinedChallenges.slice(0, 8).map((challenge) => (
            <button
              type="button"
              key={challenge.id}
              onClick={() =>
                setActionForm((previous) => ({
                  ...previous,
                  challenge_id: challenge.id,
                }))
              }
              className={`zt-button zt-button--ghost ${
                actionForm.challenge_id === challenge.id ? "border-[color:var(--zt-border-strong)] bg-[var(--zt-accent-soft)] text-[color:var(--zt-accent)]" : ""
              }`}
            >
              {challenge.slug}
            </button>
          ))}
        </div>

        <form onSubmit={handleSetFlag} className="space-y-4">
          <input
            value={actionForm.challenge_id}
            onChange={(event) =>
              setActionForm((previous) => ({
                ...previous,
                challenge_id: event.target.value,
              }))
            }
            placeholder="Challenge ID"
            className="zt-input"
            disabled={setFlagMutation.isPending}
          />

          <input
            value={actionForm.flag}
            onChange={(event) =>
              setActionForm((previous) => ({
                ...previous,
                flag: event.target.value,
              }))
            }
            placeholder="Flag"
            className="zt-input"
            disabled={setFlagMutation.isPending}
            autoComplete="off"
          />

          <div className="flex flex-wrap gap-3">
            <button type="submit" className="zt-button zt-button--primary" disabled={setFlagMutation.isPending}>
              {setFlagMutation.isPending ? "Setting..." : "Set Flag"}
            </button>
            <button type="button" onClick={handlePublish} className="zt-button zt-button--success">
              {publishMutation.isPending ? "Publishing..." : "Publish"}
            </button>
            <button type="button" onClick={handleUnpublish} className="zt-button zt-button--warn">
              {unpublishMutation.isPending ? "Unpublishing..." : "Unpublish"}
            </button>
          </div>
        </form>

        {actionError ? <div className="zt-alert zt-alert--error mt-3">{actionError}</div> : null}
      </section>

      <section className="zt-panel">
        <h2 className="zt-panel-title mb-4">Published Challenge Catalog</h2>
        {catalogLoading ? <div className="zt-alert zt-alert--info mb-3">Loading catalog...</div> : null}
        {catalogError ? <div className="zt-alert zt-alert--error">{catalogError.message}</div> : null}
        {!catalogLoading && !catalogError ? (
          <div className="zt-table-wrap">
            <table className="zt-table">
              <thead>
                <tr>
                  <th>Track</th>
                  <th>Title</th>
                  <th>Slug</th>
                  <th>Points</th>
                  <th>ID</th>
                </tr>
              </thead>
              <tbody>
                {(catalog ?? []).map((challenge) => (
                  <tr key={challenge.id}>
                    <td>{challenge.track_name}</td>
                    <td>{challenge.title}</td>
                    <td>{challenge.slug}</td>
                    <td>{challenge.points}</td>
                    <td className="text-xs text-[color:var(--zt-muted)]">{challenge.id}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : null}
      </section>
    </div>
  )
}
