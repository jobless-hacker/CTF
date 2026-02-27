from __future__ import annotations


class SecurityLayerError(Exception):
    """Base exception for security primitives."""


class PasswordHashError(SecurityLayerError):
    """Raised when password hashing fails."""


class InvalidTokenError(SecurityLayerError):
    """Raised when a token is invalid for any reason."""


class ExpiredTokenError(InvalidTokenError):
    """Raised when a token is expired."""


class TokenDecodeError(InvalidTokenError):
    """Raised when a token cannot be decoded or validated."""
