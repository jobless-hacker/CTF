import { useEffect, useState, type FormEvent } from "react"
import { useNavigate, useParams } from "react-router-dom"

import { ENV } from "../../config/environment"
import { useAuth } from "../../context/use-auth"
import { useChallengeDetail } from "../../features/challenges/hooks/useChallengeDetail"
import { useChallengeLabCommand } from "../../features/challenges/hooks/useChallengeLabCommand"
import { useSubmitFlag } from "../../features/challenges/hooks/useSubmitFlag"
import { challengeLabCommandSchema, submitFlagSchema } from "../../features/challenges/schemas/challenge.schemas"
import { ChallengeRequestError } from "../../features/challenges/services/challenge.errors"
import type { SubmitFlagResponse } from "../../features/challenges/types/challenge.types"
import { getAccessToken } from "../../services/auth-session/token"

interface LabHistoryEntry {
  id: number
  cwd: string
  command: string
  output: string
  exitCode: number
}

const M11_HINTS = [
  "Search under /etc for included configuration files.",
  "Use grep recursively to find the word 'include'.",
  "Inspect /etc/.config_chain and list hidden files.",
]

const normalizeLabPath = (rawPath?: string | null) => {
  const value = rawPath?.trim()
  if (!value) {
    return "/"
  }
  return value.startsWith("/") ? value : `/${value}`
}

const getInitialLabCwd = (challengeSlug?: string, labStartPath?: string | null) => {
  if (labStartPath && labStartPath.trim().length > 0) {
    return normalizeLabPath(labStartPath)
  }
  return challengeSlug?.toLowerCase().startsWith("m11-") ? "/etc" : "/"
}

const createInitialLabHistory = (cwd: string): LabHistoryEntry[] => [
  {
    id: Date.now(),
    cwd,
    command: "help",
    output: "Type `help` to list supported commands.",
    exitCode: 0,
  },
]

const getAttemptLockStorageKey = (slug: string, userId?: string) =>
  `zerotrace.m1_attempt_locked.${(userId ?? "anon").trim().toLowerCase()}.${slug.trim().toLowerCase()}`

const decodeJwtSub = (token: string): string | null => {
  const parts = token.split(".")
  if (parts.length < 2) {
    return null
  }

  try {
    const encodedPayload = parts[1].replace(/-/g, "+").replace(/_/g, "/")
    const paddingLength = (4 - (encodedPayload.length % 4)) % 4
    const paddedPayload = `${encodedPayload}${"=".repeat(paddingLength)}`
    const payload = JSON.parse(window.atob(paddedPayload)) as { sub?: unknown }
    if (typeof payload.sub !== "string") {
      return null
    }
    const normalized = payload.sub.trim()
    return normalized.length > 0 ? normalized : null
  } catch {
    return null
  }
}

const getSessionUserId = () => {
  if (typeof window === "undefined") {
    return null
  }

  const token = getAccessToken()
  if (!token) {
    return null
  }

  return decodeJwtSub(token)
}

const readAttemptLocked = (slug: string, userId?: string) => {
  if (typeof window === "undefined") {
    return false
  }
  try {
    return window.localStorage.getItem(getAttemptLockStorageKey(slug, userId)) === "1"
  } catch {
    return false
  }
}

const writeAttemptLocked = (slug: string, userId: string | undefined, isLocked: boolean) => {
  if (typeof window === "undefined") {
    return
  }
  try {
    const storageKey = getAttemptLockStorageKey(slug, userId)
    if (isLocked) {
      window.localStorage.setItem(storageKey, "1")
      return
    }
    window.localStorage.removeItem(storageKey)
  } catch {
    return
  }
}

export const ChallengeDetailPage = () => {
  const { slug } = useParams<{ slug: string }>()
  const { user } = useAuth()
  const navigate = useNavigate()
  const { data, isLoading, error } = useChallengeDetail(slug)
  const { mutateAsync, isPending, error: submitError, reset } = useSubmitFlag(slug)
  const {
    mutateAsync: executeLabCommand,
    isPending: isLabPending,
    error: labError,
    reset: resetLabError,
  } = useChallengeLabCommand(slug)

  const lockIdentity = (user?.id?.trim() || getSessionUserId() || "anon").toLowerCase()
  const [flag, setFlag] = useState("")
  const [isLocallyAttemptLocked, setIsLocallyAttemptLocked] = useState(() =>
    slug ? readAttemptLocked(slug, lockIdentity) : false,
  )
  const [result, setResult] = useState<SubmitFlagResponse | null>(null)
  const [validationError, setValidationError] = useState<string | null>(null)
  const [labCwd, setLabCwd] = useState(() => getInitialLabCwd(slug))
  const [labCommand, setLabCommand] = useState("")
  const [labValidationError, setLabValidationError] = useState<string | null>(null)
  const [copyStatus, setCopyStatus] = useState<string | null>(null)
  const [labHintLevel, setLabHintLevel] = useState(0)
  const [labHistory, setLabHistory] = useState<LabHistoryEntry[]>(() => createInitialLabHistory(getInitialLabCwd(slug)))

  useEffect(() => {
    if (!slug) {
      setIsLocallyAttemptLocked(false)
      return
    }

    const lockedForIdentity = readAttemptLocked(slug, lockIdentity)
    if (lockedForIdentity) {
      setIsLocallyAttemptLocked(true)
      return
    }

    // Migrate prior anonymous lock entry to stable authenticated identity.
    if (lockIdentity !== "anon" && readAttemptLocked(slug, "anon")) {
      writeAttemptLocked(slug, lockIdentity, true)
      writeAttemptLocked(slug, "anon", false)
      setIsLocallyAttemptLocked(true)
      return
    }

    setIsLocallyAttemptLocked(false)
  }, [slug, lockIdentity])

  useEffect(() => {
    if (!slug || !data?.attempt_locked) {
      return
    }
    writeAttemptLocked(slug, lockIdentity, true)
    setIsLocallyAttemptLocked(true)
  }, [slug, lockIdentity, data?.attempt_locked])

  useEffect(() => {
    setCopyStatus(null)
  }, [slug])

  useEffect(() => {
    const nextCwd = getInitialLabCwd(slug, data?.lab_start_path)
    setLabCwd(nextCwd)
    setLabCommand("")
    setLabValidationError(null)
    setLabHintLevel(0)
    resetLabError()
    setLabHistory(createInitialLabHistory(nextCwd))
  }, [slug, data?.lab_start_path])

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
  const isM1SingleAttemptChallenge = data.slug.toLowerCase().startsWith("m1-")
  const isAttemptLocked =
    Boolean(data.attempt_locked)
    || isLocallyAttemptLocked
    || (isM1SingleAttemptChallenge && (result !== null || submitError?.code === "ATTEMPT_LIMIT_REACHED"))
  const resolvedAttachmentUrl = data.attachment_url
    ? new URL(data.attachment_url, `${ENV.API_BASE_URL.replace(/\/+$/, "")}/`).toString()
    : null

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
      if (isM1SingleAttemptChallenge) {
        setIsLocallyAttemptLocked(true)
        writeAttemptLocked(data.slug, lockIdentity, true)
      }
      setFlag("")
    } catch (requestError) {
      if (
        isM1SingleAttemptChallenge
        && requestError instanceof ChallengeRequestError
        && requestError.code === "ATTEMPT_LIMIT_REACHED"
      ) {
        setIsLocallyAttemptLocked(true)
        writeAttemptLocked(data.slug, lockIdentity, true)
      }
      return
    }
  }

  const handleLabCommandSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    await runLabCommand(labCommand)
  }

  const runLabCommand = async (rawCommand: string) => {
    setLabValidationError(null)
    resetLabError()

    const incomingCommand = rawCommand.trim()
    const normalizedCommand = incomingCommand.toLowerCase()

    if (normalizedCommand === "clear") {
      setLabHistory([])
      setLabCommand("")
      return
    }

    if (normalizedCommand === "history") {
      setLabHistory((previous) => {
        const lines = previous.map((entry, index) => `${index + 1}  ${entry.command}`)
        return [
          ...previous,
          {
            id: Date.now() + previous.length,
            cwd: labCwd,
            command: incomingCommand,
            output: lines.length > 0 ? lines.join("\n") : "No command history for this session.",
            exitCode: 0,
          },
        ]
      })
      setLabCommand("")
      return
    }

    const parsed = challengeLabCommandSchema.safeParse({
      command: rawCommand,
      cwd: labCwd,
    })
    if (!parsed.success) {
      setLabValidationError(parsed.error.issues[0]?.message ?? "Command is required.")
      return
    }

    const submittedCommand = parsed.data.command
    try {
      const response = await executeLabCommand(parsed.data)
      if (response.output === "__CLEAR__") {
        setLabHistory([])
      } else {
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
      }
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

  const resetLabSession = () => {
    const initialCwd = getInitialLabCwd(data.slug, data.lab_start_path)
    setLabCwd(initialCwd)
    setLabCommand("")
    setLabValidationError(null)
    setLabHintLevel(0)
    resetLabError()
    setLabHistory(createInitialLabHistory(initialCwd))
  }

  const isM11Lab = data.slug.toLowerCase().startsWith("m11-")
  const configuredHints = (data.lab_hints ?? (isM11Lab ? M11_HINTS : [])).filter(
    (hint) => typeof hint === "string" && hint.trim().length > 0,
  )
  const revealedHints = configuredHints.slice(0, labHintLevel)

  const handleHintClick = () => {
    if (configuredHints.length === 0) {
      setLabHistory((previous) => [
        ...previous,
        {
          id: Date.now() + previous.length,
          cwd: labCwd,
          command: "hint",
          output: "Hints are currently available for M11 labs only.",
          exitCode: 0,
        },
      ])
      return
    }

    if (labHintLevel >= configuredHints.length) {
      setLabHistory((previous) => [
        ...previous,
        {
          id: Date.now() + previous.length,
          cwd: labCwd,
          command: "hint",
          output: "All hints are already unlocked.",
          exitCode: 0,
        },
      ])
      return
    }

    setLabHintLevel((previous) => previous + 1)
  }

  const handleBackClick = () => {
    if (window.history.length > 1) {
      navigate(-1)
      return
    }
    navigate("/tracks")
  }

  const handleInsertTemplate = () => {
    setFlag("CTF{}")
  }

  const handleCopySlug = async () => {
    if (!navigator?.clipboard) {
      setCopyStatus("Clipboard unavailable in this browser.")
      return
    }
    try {
      await navigator.clipboard.writeText(data.slug)
      setCopyStatus("Challenge slug copied.")
    } catch {
      setCopyStatus("Unable to copy slug.")
    }
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
          <span className="zt-pill">Slug: {data.slug}</span>
        </div>
        <div className="mt-4 flex flex-wrap gap-2">
          <button type="button" className="zt-button zt-button--ghost" onClick={handleCopySlug}>
            Copy Slug
          </button>
        </div>
        {copyStatus ? <div className="zt-alert zt-alert--info mt-3">{copyStatus}</div> : null}
        {resolvedAttachmentUrl ? (
          <div className="mt-5 rounded-lg border border-cyber-border bg-black/40 p-4">
            <p className="zt-subheading">Attachment</p>
            <a
              href={resolvedAttachmentUrl}
              target="_blank"
              rel="noreferrer"
              download
              className="zt-button zt-button--ghost mt-3 inline-flex"
            >
              Download artifact
            </a>
          </div>
        ) : null}
        <p className="mt-5 whitespace-pre-wrap text-sm leading-7 text-[color:var(--zt-text)]">{data.description}</p>
      </section>

      {isTerminalLabChallenge ? (
        <section className="zt-panel">
          <h2 className="zt-panel-title">Terminal Lab</h2>
          <p className="zt-subheading mt-2">
            Interactive read-only lab for this challenge.
          </p>

          <div className="mt-3 flex flex-wrap gap-2">
            <button type="button" className="zt-button zt-button--ghost" onClick={() => { void runLabCommand("help") }}>
              Help
            </button>
            <button type="button" className="zt-button zt-button--ghost" onClick={() => { void runLabCommand("clear") }}>
              Clear
            </button>
            <button type="button" className="zt-button zt-button--ghost" onClick={handleHintClick}>
              Hint
            </button>
            <button type="button" className="zt-button zt-button--ghost" onClick={resetLabSession}>
              Reset Lab
            </button>
          </div>

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
          <p className="mt-2 text-xs text-cyber-textMuted">
            Examples: help, ls -a, grep -R include /etc, find /opt -name "*.tar"
          </p>

          {revealedHints.length > 0 ? (
            <div className="mt-4 rounded-lg border border-cyber-border bg-black/40 p-4">
              <p className="zt-subheading">Hints</p>
              <div className="mt-2 space-y-1 text-xs text-cyber-text">
                {revealedHints.map((hint, index) => (
                  <p key={hint}>
                    {index + 1}. {hint}
                  </p>
                ))}
              </div>
            </div>
          ) : null}

          <div className="mt-3 space-y-2">
            {labValidationError ? <div className="zt-alert zt-alert--error">{labValidationError}</div> : null}
            {labError ? <div className="zt-alert zt-alert--error">{labError.message}</div> : null}
          </div>
        </section>
      ) : null}

      <section className="zt-panel">
        <h2 className="zt-panel-title">Flag Submission</h2>
        {isM1SingleAttemptChallenge ? (
          <div className="zt-alert zt-alert--warn mt-3">
            One attempt only for this challenge. Your first submission is final.
          </div>
        ) : null}

        <div className="mt-4 flex flex-wrap gap-2">
          <button type="button" className="zt-button zt-button--ghost" onClick={handleInsertTemplate} disabled={isAttemptLocked}>
            Insert CTF Template
          </button>
        </div>

        <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-3 md:flex-row">
          <input
            value={flag}
            onChange={(event) => setFlag(event.target.value)}
            placeholder="Enter flag (e.g., CTF{example_flag})"
            className="zt-input flex-1"
            autoComplete="off"
            disabled={isPending || isAttemptLocked}
          />
          <button disabled={isPending || isAttemptLocked} className="zt-button zt-button--primary md:min-w-40">
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
          {isAttemptLocked ? (
            <div className="zt-alert zt-alert--warn">Attempt used. Further submissions are disabled.</div>
          ) : null}
        </div>
      </section>
    </div>
  )
}
