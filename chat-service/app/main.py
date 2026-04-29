import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@app-db:5432/app_db_dev")


class MessagePayload(BaseModel):
    sender_id: int
    receiver_id: int
    message: str


@contextmanager
def db_cursor():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            yield cursor
            conn.commit()
    finally:
        conn.close()


app = FastAPI(title="Chat Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def startup():
    with db_cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS chat_messages (
                id SERIAL PRIMARY KEY,
                sender_id INTEGER NOT NULL,
                receiver_id INTEGER NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT NOW()
            )
            """
        )


@app.get("/health")
def health():
    with db_cursor() as cursor:
        cursor.execute("SELECT 1 AS ok")
        return {"status": "ok", "database": cursor.fetchone()["ok"]}


@app.get("/chat/messages")
def list_messages():
    with db_cursor() as cursor:
        cursor.execute(
            "SELECT id, sender_id, receiver_id, message, created_at FROM chat_messages ORDER BY id"
        )
        return cursor.fetchall()


@app.post("/chat/messages", status_code=201)
def create_message(payload: MessagePayload):
    with db_cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO chat_messages (sender_id, receiver_id, message)
            VALUES (%s, %s, %s)
            RETURNING id, sender_id, receiver_id, message, created_at
            """,
            (payload.sender_id, payload.receiver_id, payload.message),
        )
        return cursor.fetchone()
