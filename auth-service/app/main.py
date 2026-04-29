import os
import uuid
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@app-db:5432/app_db_dev")


class Credentials(BaseModel):
    username: str
    password: str


class RegisterPayload(Credentials):
    role: str = "user"


@contextmanager
def db_cursor():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            yield cursor
            conn.commit()
    finally:
        conn.close()


app = FastAPI(title="Authentication Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def startup():
    with db_cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS auth_accounts (
                id SERIAL PRIMARY KEY,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'user',
                token TEXT UNIQUE
            )
            """
        )
        cursor.execute("ALTER TABLE auth_accounts ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user'")


@app.get("/health")
def health():
    with db_cursor() as cursor:
        cursor.execute("SELECT 1 AS ok")
        return {"status": "ok", "database": cursor.fetchone()["ok"]}


@app.post("/auth/register", status_code=201)
def register(payload: RegisterPayload):
    if payload.role not in ("user", "admin"):
        raise HTTPException(status_code=400, detail="Role must be user or admin")
    try:
        with db_cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO auth_accounts (username, password, role)
                VALUES (%s, %s, %s)
                RETURNING id, username, role
                """,
                (payload.username, payload.password, payload.role),
            )
            return cursor.fetchone()
    except psycopg2.errors.UniqueViolation:
        raise HTTPException(status_code=409, detail="Username already exists")


@app.post("/auth/login")
def login(payload: Credentials):
    with db_cursor() as cursor:
        cursor.execute(
            "SELECT id, username, role FROM auth_accounts WHERE username=%s AND password=%s",
            (payload.username, payload.password),
        )
        account = cursor.fetchone()
        if not account:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        token = str(uuid.uuid4())
        cursor.execute("UPDATE auth_accounts SET token=%s WHERE id=%s", (token, account["id"]))
        account["token"] = token
        return account


@app.get("/auth/validate/{token}")
def validate(token: str):
    with db_cursor() as cursor:
        cursor.execute("SELECT id, username, role FROM auth_accounts WHERE token=%s", (token,))
        account = cursor.fetchone()
        if not account:
            raise HTTPException(status_code=401, detail="Invalid token")
        return {"valid": True, "account": account}


@app.get("/auth/admin/{token}")
def validate_admin(token: str):
    with db_cursor() as cursor:
        cursor.execute("SELECT id, username, role FROM auth_accounts WHERE token=%s", (token,))
        account = cursor.fetchone()
        if not account:
            raise HTTPException(status_code=401, detail="Invalid token")
        if account["role"] != "admin":
            raise HTTPException(status_code=403, detail="Admin role required")
        return {"authorized": True, "account": account}
