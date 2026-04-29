import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@app-db:5432/app_db_dev")


class UserPayload(BaseModel):
    username: str
    email: str


@contextmanager
def db_cursor():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            yield cursor
            conn.commit()
    finally:
        conn.close()


app = FastAPI(title="User Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def startup():
    with db_cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL
            )
            """
        )


@app.get("/health")
def health():
    with db_cursor() as cursor:
        cursor.execute("SELECT 1 AS ok")
        return {"status": "ok", "database": cursor.fetchone()["ok"]}


@app.get("/users")
def list_users():
    with db_cursor() as cursor:
        cursor.execute("SELECT id, username, email FROM users ORDER BY id")
        return cursor.fetchall()


@app.get("/users/{user_id}")
def get_user(user_id: int):
    with db_cursor() as cursor:
        cursor.execute("SELECT id, username, email FROM users WHERE id=%s", (user_id,))
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user


@app.post("/users", status_code=201)
def create_user(payload: UserPayload):
    try:
        with db_cursor() as cursor:
            cursor.execute(
                "INSERT INTO users (username, email) VALUES (%s, %s) RETURNING id, username, email",
                (payload.username, payload.email),
            )
            return cursor.fetchone()
    except psycopg2.errors.UniqueViolation:
        raise HTTPException(status_code=409, detail="User already exists")
