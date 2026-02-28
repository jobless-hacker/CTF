import { useState, type FormEvent } from "react"
import { useNavigate, useParams } from "react-router-dom"

import { useChallengeDetail } from "../../features/challenges/hooks/useChallengeDetail"
import { useChallengeLabCommand } from "../../features/challenges/hooks/useChallengeLabCommand"
import { useSubmitFlag } from "../../features/challenges/hooks/useSubmitFlag"
import { challengeLabCommandSchema, submitFlagSchema } from "../../features/challenges/schemas/challenge.schemas"
import type { SubmitFlagResponse } from "../../features/challenges/types/challenge.types"

interface LabHistoryEntry {
  id: number
  cwd: string
  command: string
  output: string
  exitCode: number
}

export const ChallengeDetailPage = () => {
  const { slug } = useParams<{ slug: string }>()
  const navigate = useNavigate()
  const { data, isLoading, error } = useChallengeDetail(slug)
  const { mutateAsync, isPending, error: submitError, reset } = useSubmitFlag(slug)
  const {
    mutateAsync: executeLabCommand,
    isPending: isLabPending,
    error: labError,
    reset: resetLabError,
  } = useChallengeLabCommand(slug)

  const [flag, setFlag] = useState("")
  const [result, setResult] = useState<SubmitFlagResponse | null>(null)
  const [validationError, setValidationError] = useState<string | null>(null)
  const [labCwd, setLabCwd] = useState("/etc")
  const [labCommand, setLabCommand] = useState("")
  const [labValidationError, setLabValidationError] = useState<string | null>(null)
  const [labHistory, setLabHistory] = useState<LabHistoryEntry[]>([
    {
      id: 1,
      cwd: "/etc",
      command: "help",
      output: "Type `help` to list supported commands.",
      exitCode: 0,
    },
  ])

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

  const isTerminalLabChallenge = data.lab_available

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

  const handleLabCommandSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setLabValidationError(null)
    resetLabError()

    const parsed = challengeLabCommandSchema.safeParse({
      command: labCommand,
      cwd: labCwd,
    })
    if (!parsed.success) {
      setLabValidationError(parsed.error.issues[0]?.message ?? "Command is required.")
      return
    }

    const submittedCommand = parsed.data.command
    try {
      const response = await executeLabCommand(parsed.data)
      setLabHistory((previous) => [
        ...previous,
        {
          id: Date.now() + previous.length,
          cwd: labCwd,
          command: submittedCommand,
          output: response.output,
          exitCode: response.exit_code,
        },
      ])
      setLabCwd(response.cwd)
      setLabCommand("")
    } catch (requestError) {
      setLabHistory((previous) => [
        ...previous,
        {
          id: Date.now() + previous.length,
          cwd: labCwd,
          command: submittedCommand,
          output: requestError instanceof Error ? requestError.message : "Lab command failed.",
          exitCode: 1,
        },
      ])
    }
  }

  const handleBackClick = () => {
    if (window.history.length > 1) {
      navigate(-1)
      return
    }
    navigate("/tracks")
  }

  return (
    <div className="zt-page">
      <section className="zt-panel">
        <button onClick={handleBackClick} className="zt-button zt-button--ghost mb-4" type="button">
          Back
        </button>
        <p className="zt-kicker">Mission Brief</p>
        <h1 className="zt-heading mt-2">{data.title}</h1>
        <div className="mt-3 flex flex-wrap gap-2">
          <span className="zt-pill">Difficulty: {data.difficulty}</span>
          <span className="zt-pill">{data.points} pts</span>
        </div>
        <p className="mt-5 whitespace-pre-wrap text-sm leading-7 text-[color:var(--zt-text)]">{data.description}</p>
      </section>

      {isTerminalLabChallenge ? (
        <section className="zt-panel">
          <h2 className="zt-panel-title">Terminal Lab</h2>
          <p className="zt-subheading mt-2">
            Interactive read-only lab for this challenge.
          </p>

          <div className="mt-4 max-h-96 overflow-y-auto rounded-lg border border-cyber-border bg-black/70 p-4 font-mono text-xs leading-6 text-cyber-text">
            {labHistory.map((entry) => (
              <div key={entry.id} className="mb-3">
                <div className="text-cyber-neon">
                  {entry.cwd} $ {entry.command}
                </div>
                {entry.output ? (
                  <pre
                    className={`mt-1 whitespace-pre-wrap ${entry.exitCode === 0 ? "text-cyber-text" : "text-red-300"}`}
                  >
                    {entry.output}
                  </pre>
                ) : null}
              </div>
            ))}
            {isLabPending ? <div className="text-cyber-textMuted">executing...</div> : null}
          </div>

          <form onSubmit={handleLabCommandSubmit} className="mt-4 flex flex-col gap-3 md:flex-row">
            <input
              value={labCommand}
              onChange={(event) => setLabCommand(event.target.value)}
              placeholder="Type command (example: help)"
              className="zt-input flex-1 font-mono"
              autoComplete="off"
            />
            <button disabled={isLabPending} className="zt-button zt-button--ghost md:min-w-40">
              {isLabPending ? "Running..." : "Run"}
            </button>
          </form>

          <div className="mt-3 space-y-2">
            {labValidationError ? <div className="zt-alert zt-alert--error">{labValidationError}</div> : null}
            {labError ? <div className="zt-alert zt-alert--error">{labError.message}</div> : null}
          </div>
        </section>
      ) : null}

      <section className="zt-panel">
        <h2 className="zt-panel-title">Flag Submission</h2>

        <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-3 md:flex-row">
          <input
            value={flag}
            onChange={(event) => setFlag(event.target.value)}
            placeholder="Enter flag (e.g., CTF{example_flag})"
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
