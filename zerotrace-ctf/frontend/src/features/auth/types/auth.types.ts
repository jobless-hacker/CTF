export interface LoginResponse {
  access_token: string
  token_type: string
}

export interface User {
  id: string
  email: string
  roles: string[]
  created_at: string
}
