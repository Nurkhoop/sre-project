import os
from contextlib import contextmanager
from decimal import Decimal

import psycopg2
import psycopg2.extras
import requests
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel, Field


def database_url() -> str:
    if os.getenv("DATABASE_URL"):
        return os.environ["DATABASE_URL"]
    host = os.getenv("DB_HOST", "app-db")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "app_db_dev")
    user = os.getenv("DB_USER", "postgres")
    password = os.getenv("DB_PASSWORD", "postgres")
    return f"postgresql://{user}:{password}@{host}:{port}/{name}"


ORDER_SERVICE_URL = os.getenv("ORDER_SERVICE_URL", "http://order-service:8000")


class PaymentPayload(BaseModel):
    order_id: int
    amount: Decimal = Field(gt=0)
    method: str = Field(default="card", min_length=2)


@contextmanager
def db_cursor():
    conn = psycopg2.connect(database_url())
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            yield cursor
            conn.commit()
    finally:
        conn.close()


app = FastAPI(title="Payment Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def startup():
    with db_cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS payments (
                id SERIAL PRIMARY KEY,
                order_id INTEGER NOT NULL,
                amount NUMERIC(10, 2) NOT NULL,
                method TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'paid',
                created_at TIMESTAMP NOT NULL DEFAULT NOW()
            )
            """
        )


@app.get("/health")
def health():
    with db_cursor() as cursor:
        cursor.execute("SELECT 1 AS ok")
        return {"status": "ok", "database": cursor.fetchone()["ok"]}


@app.get("/payments")
def list_payments():
    with db_cursor() as cursor:
        cursor.execute(
            """
            SELECT id, order_id, amount::float, method, status, created_at
            FROM payments
            ORDER BY id
            """
        )
        return cursor.fetchall()


@app.get("/payments/{payment_id}")
def get_payment(payment_id: int):
    with db_cursor() as cursor:
        cursor.execute(
            """
            SELECT id, order_id, amount::float, method, status, created_at
            FROM payments
            WHERE id=%s
            """,
            (payment_id,),
        )
        payment = cursor.fetchone()
        if not payment:
            raise HTTPException(status_code=404, detail="Payment not found")
        return payment


@app.post("/payments", status_code=201)
def create_payment(payload: PaymentPayload):
    order_response = requests.get(f"{ORDER_SERVICE_URL}/orders/{payload.order_id}", timeout=3)
    if order_response.status_code != 200:
        raise HTTPException(status_code=404, detail="Order not found")

    status = "paid"
    if payload.method.lower() not in {"card", "cash", "bank_transfer"}:
        status = "failed"

    with db_cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO payments (order_id, amount, method, status)
            VALUES (%s, %s, %s, %s)
            RETURNING id, order_id, amount::float, method, status, created_at
            """,
            (payload.order_id, payload.amount, payload.method, status),
        )
        return cursor.fetchone()
