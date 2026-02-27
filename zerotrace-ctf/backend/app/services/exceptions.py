from __future__ import annotations


class AuthServiceError(Exception):
    """Base error for auth service operations."""


class UserAlreadyExistsError(AuthServiceError):
    """Raised when a registration email already exists."""


class InvalidCredentialsError(AuthServiceError):
    """Raised when authentication credentials are invalid."""


class InactiveUserError(AuthServiceError):
    """Raised when an inactive user attempts authentication."""


class TokenIssuanceError(AuthServiceError):
    """Raised when issuing an access token fails."""


class TokenValidationError(AuthServiceError):
    """Raised when token validation fails."""


class ExpiredAuthTokenError(TokenValidationError):
    """Raised when token validation fails due to expiration."""
