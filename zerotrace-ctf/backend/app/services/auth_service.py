from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories import user_repository
from app.schemas.token import AccessTokenResponse, TokenPayload
from app.security.exceptions import ExpiredTokenError, InvalidTokenError, PasswordHashError
from app.security.jwt import create_access_token, decode_access_token
from app.security.password import hash_password, verify_password
from app.services.exceptions import (
    AuthServiceError,
    ExpiredAuthTokenError,
    InactiveUserError,
    InvalidCredentialsError,
    TokenIssuanceError,
    TokenValidationError,
    UserAlreadyExistsError,
)


class AuthService:
    DEFAULT_PLAYER_ROLE = "player"

    def register_user(self, session: Session, email: str, password: str) -> User:
        existing_user = user_repository.get_by_email(session, email)
        if existing_user is not None:
            raise UserAlreadyExistsError("A user with this email already exists.")

        try:
            password_hash = hash_password(password)
        except PasswordHashError:
            raise AuthServiceError("User registration failed.") from None

        user = user_repository.create_user(session, email=email, password_hash=password_hash)

        try:
            user_repository.assign_role(session, user=user, role_name=self.DEFAULT_PLAYER_ROLE)
        except LookupError:
            raise AuthServiceError("Default role assignment failed.") from None

        return user

    def authenticate_user(self, session: Session, email: str, password: str) -> User:
        user = user_repository.get_by_email(session, email)
        if user is None:
            raise InvalidCredentialsError("Invalid credentials.")

        if not verify_password(password, user.password_hash):
            raise InvalidCredentialsError("Invalid credentials.")

        if not user.is_active:
            raise InactiveUserError("User account is inactive.")

        return user

    def issue_token(self, user: User) -> AccessTokenResponse:
        if user.id is None:
            raise TokenIssuanceError("Cannot issue token for a user without an identifier.")

        token_payload = {
            "sub": str(user.id),
            "roles": self._extract_role_names(user),
        }

        try:
            access_token = create_access_token(token_payload)
        except InvalidTokenError:
            raise TokenIssuanceError("Access token issuance failed.") from None

        return AccessTokenResponse(access_token=access_token)

    def validate_token(self, token: str) -> TokenPayload:
        try:
            return decode_access_token(token)
        except ExpiredTokenError:
            raise ExpiredAuthTokenError("Access token has expired.") from None
        except InvalidTokenError:
            raise TokenValidationError("Access token is invalid.") from None

    @staticmethod
    def _extract_role_names(user: User) -> list[str]:
        role_names = {role.name for role in user.roles if role.name}
        return sorted(role_names)
