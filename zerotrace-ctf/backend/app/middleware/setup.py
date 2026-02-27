from fastapi import FastAPI

from app.middleware.request_id import RequestIDMiddleware

def register_middleware(app: FastAPI) -> None:
    app.add_middleware(RequestIDMiddleware)
