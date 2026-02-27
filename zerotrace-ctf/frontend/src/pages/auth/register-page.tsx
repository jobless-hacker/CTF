import { useState, type FormEvent } from "react"
import { Link, useNavigate } from "react-router-dom"

import { registerSchema } from "../../features/auth/schemas/auth.schemas"
import { useRegister } from "../../features/auth/hooks/useRegister"
import { AuthLayout } from "../../layouts/auth-layout"

type RegisterFormState = {
  email: string
  password: string
  confirmPassword: string
}

export const RegisterPage = () => {
  const navigate = useNavigate()
  const { mutateAsync, isPending, error } = useRegister()
  const [validationError, setValidationError] = useState<string | null>(null)
  const [form, setForm] = useState<RegisterFormState>({
    email: "",
    password: "",
    confirmPassword: "",
  })

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setValidationError(null)

    if (form.password !== form.confirmPassword) {
      setValidationError("Passwords do not match.")
      return
    }

    const parsed = registerSchema.safeParse({
      email: form.email,
      password: form.password,
    })
    if (!parsed.success) {
      setValidationError(parsed.error.issues[0]?.message ?? "Invalid input.")
      return
    }

    try {
      await mutateAsync(parsed.data)
      navigate("/login", { replace: true })
    } catch {
      return
    }
  }

  return (
    <AuthLayout
      panelTitle="Create Account"
      panelSubtitle="Provision a new operator identity for challenge operations."
      footer={
        <p className="zt-subheading mt-0 text-center">
          Already have an account?{" "}
          <Link className="text-[color:var(--zt-accent)] underline" to="/login">
            Login
          </Link>
        </p>
      }
    >
      <form onSubmit={handleSubmit} className="zt-form">
        <div>
          <label htmlFor="register-email" className="zt-field-label">
            Email
          </label>
          <input
            id="register-email"
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
          <label htmlFor="register-password" className="zt-field-label">
            Password
          </label>
          <input
            id="register-password"
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

        <div>
          <label htmlFor="register-confirm-password" className="zt-field-label">
            Confirm Password
          </label>
          <input
            id="register-confirm-password"
            type="password"
            className="cyber-input"
            value={form.confirmPassword}
            onChange={(event) =>
              setForm((previous) => ({
                ...previous,
                confirmPassword: event.target.value,
              }))
            }
          />
        </div>

        <div className="zt-auth-separator" />

        <button disabled={isPending} className="cyber-button">
          {isPending ? "Provisioning..." : "Register"}
        </button>

        {validationError ? <div className="zt-alert zt-alert--error">{validationError}</div> : null}
        {error ? <div className="zt-alert zt-alert--error">{error.message}</div> : null}
      </form>
    </AuthLayout>
  )
}
