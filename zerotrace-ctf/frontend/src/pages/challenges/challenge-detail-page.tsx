import { useState, type FormEvent } from "react"
import { useParams } from "react-router-dom"

import { useChallengeDetail } from "../../features/challenges/hooks/useChallengeDetail"
import { useSubmitFlag } from "../../features/challenges/hooks/useSubmitFlag"
import { submitFlagSchema } from "../../features/challenges/schemas/challenge.schemas"
import type { SubmitFlagResponse } from "../../features/challenges/types/challenge.types"

export const ChallengeDetailPage = () => {
  const { slug } = useParams<{ slug: string }>()
  const { data, isLoading, error } = useChallengeDetail(slug)
  const { mutateAsync, isPending, error: submitError, reset } = useSubmitFlag(slug)

  const [flag, setFlag] = useState("")
  const [result, setResult] = useState<SubmitFlagResponse | null>(null)
  const [validationError, setValidationError] = useState<string | null>(null)

  if (!slug) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">Invalid challenge.</div>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="zt-page">
        <div className="zt-panel">
          <div className="zt-alert zt-alert--info">Loading challenge...</div>
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

  if (!data) {
    return (
      <div className="zt-page">
        <div className="zt-alert zt-alert--error">Challenge not found.</div>
      </div>
    )
  }

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setValidationError(null)
    setResult(null)
    reset()

    const parsed = submitFlagSchema.safeParse({ flag })
    if (!parsed.success) {
      setValidationError(parsed.error.issues[0]?.message ?? "Flag is required.")
      return
    }

    try {
      const response = await mutateAsync(parsed.data)
      setResult(response)
      setFlag("")
    } catch {
      return
    }
  }

  return (
    <div className="zt-page">
      <section className="zt-panel">
        <p className="zt-kicker">Mission Brief</p>
        <h1 className="zt-heading mt-2">{data.title}</h1>
        <div className="mt-3 flex flex-wrap gap-2">
          <span className="zt-pill">Difficulty: {data.difficulty}</span>
          <span className="zt-pill">{data.points} pts</span>
        </div>
        <p className="mt-5 whitespace-pre-wrap text-sm leading-7 text-[color:var(--zt-text)]">{data.description}</p>
      </section>

      <section className="zt-panel">
        <h2 className="zt-panel-title">Flag Submission</h2>

        <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-3 md:flex-row">
          <input
            value={flag}
            onChange={(event) => setFlag(event.target.value)}
            placeholder="Enter flag"
            className="zt-input flex-1"
            autoComplete="off"
          />
          <button disabled={isPending} className="zt-button zt-button--primary md:min-w-40">
            {isPending ? "Submitting..." : "Submit"}
          </button>
        </form>

        <div className="mt-4 space-y-2">
          {validationError ? <div className="zt-alert zt-alert--error">{validationError}</div> : null}

          {submitError?.code === "RATE_LIMITED" ? (
            <div className="zt-alert zt-alert--warn">
              Too many submissions. Try again later.
              {submitError.retryAfterSeconds !== null ? (
                <span className="ml-2 text-xs">(Retry after {submitError.retryAfterSeconds}s)</span>
              ) : null}
            </div>
          ) : null}

          {submitError && submitError.code !== "RATE_LIMITED" ? (
            <div className="zt-alert zt-alert--error">{submitError.message}</div>
          ) : null}

          {result?.correct ? (
            <div className="zt-alert zt-alert--success">
              Correct! +{result.xp_awarded} XP
              {result.first_blood ? <span className="ml-2 font-semibold">First Blood</span> : null}
            </div>
          ) : null}

          {result && !result.correct ? <div className="zt-alert zt-alert--error">Incorrect flag.</div> : null}
        </div>
      </section>
    </div>
  )
}
