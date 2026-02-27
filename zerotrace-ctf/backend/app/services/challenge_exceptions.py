from __future__ import annotations


class ChallengeServiceError(Exception):
    """Base error for challenge service operations."""


class ChallengeNotFoundError(ChallengeServiceError):
    """Raised when a challenge cannot be found."""


class ChallengeNotPublishedError(ChallengeServiceError):
    """Raised when a challenge exists but is not published."""


class FlagNotSetError(ChallengeServiceError):
    """Raised when a challenge flag is required but not configured."""


class InvalidFlagSubmissionError(ChallengeServiceError):
    """Raised when a submitted flag is invalid (e.g. empty)."""


class ChallengeAlreadyPublishedError(ChallengeServiceError):
    """Raised when attempting to publish an already published challenge."""


class ChallengeAlreadyHasFlagError(ChallengeServiceError):
    """Raised when attempting to set a flag more than once."""


class TrackNotFoundError(ChallengeServiceError):
    """Raised when a referenced track does not exist."""


class InvalidChallengeConfigurationError(ChallengeServiceError):
    """Raised when challenge configuration input is invalid."""


class FlagHashingError(ChallengeServiceError):
    """Raised when flag hashing or verification fails unexpectedly."""


class ChallengeRateLimitedError(ChallengeServiceError):
    """Raised when challenge submission rate limit is exceeded."""

    def __init__(self, retry_after_seconds: int) -> None:
        super().__init__("Challenge submission rate limit exceeded.")
        self.retry_after_seconds = retry_after_seconds
