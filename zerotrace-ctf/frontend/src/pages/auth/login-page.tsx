import { useState, type FormEvent } from "react"
import { Link, useLocation, useNavigate } from "react-router-dom"

import type { LoginInput } from "../../features/auth/schemas/auth.schemas"
import { loginSchema } from "../../features/auth/schemas/auth.schemas"
import { useLogin } from "../../features/auth/hooks/useLogin"
import { useTypewriter } from "../../hooks/ui/useTypewriter"
import { AuthLayout } from "../../layouts/auth-layout"

type RedirectState = {
  from?: string
}

export const LoginPage = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const typing = useTypewriter("Authenticate operator credentials and enter the mission grid.", 22)
  const { mutateAsync, isPending, error } = useLogin()
  const [validationError, setValidationError] = useState<string | null>(null)
  const [form, setForm] = useState<LoginInput>({
    email: "",
    password: "",
  })

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setValidationError(null)

    const parsed = loginSchema.safeParse(form)
    if (!parsed.success) {
      setValidationError(parsed.error.issues[0]?.message ?? "Invalid input.")
      return
    }

    try {
      await mutateAsync(parsed.data)
      const from = (location.state as RedirectState | null)?.from ?? "/"
      navigate(from, { replace: true })
    } catch {
      return
    }
  }

  return (
    <AuthLayout
      panelTitle="Login"
      panelSubtitle={typing}
      footer={
        <p className="zt-subheading mt-0 text-center">
          New operator?{" "}
          <Link className="text-[color:var(--zt-accent)] underline" to="/register">
            Register
          </Link>
        </p>
      }
    >
      <form onSubmit={handleSubmit} className="zt-form">
        <div>
          <label htmlFor="login-email" className="zt-field-label">
            Email
          </label>
          <input
            id="login-email"
            type="email"
            className="cyber-input"
            value={form.email}
            onChange={(event) =>
              setForm((previous) => ({
                ...previous,
                email: event.target.value,
              }))
            }
          />
        </div>

        <div>
          <label htmlFor="login-password" className="zt-field-label">
            Password
          </label>
          <input
            id="login-password"
            type="password"
            className="cyber-input"
            value={form.password}
            onChange={(event) =>
              setForm((previous) => ({
                ...previous,
                password: event.target.value,
              }))
            }
          />
        </div>

        <div className="zt-auth-separator" />

        <button disabled={isPending} className="cyber-button">
          {isPending ? "Authenticating..." : "Login"}
        </button>

        {validationError ? <div className="zt-alert zt-alert--error">{validationError}</div> : null}
        {error ? <div className="zt-alert zt-alert--error">{error.message}</div> : null}
      </form>
    </AuthLayout>
  )
}
