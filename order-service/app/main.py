import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
import requests
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel


def database_url() -> str:
    if os.getenv("DATABASE_URL"):
        return os.environ["DATABASE_URL"]
    host = os.getenv("DB_HOST", "app-db")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "app_db_dev")
    user = os.getenv("DB_USER", "postgres")
    password = os.getenv("DB_PASSWORD", "postgres")
    return f"postgresql://{user}:{password}@{host}:{port}/{name}"


USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8000")
PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8000")


class OrderPayload(BaseModel):
    user_id: int
    product_id: int
    quantity: int = 1


@contextmanager
def db_cursor():
    conn = psycopg2.connect(database_url())
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            yield cursor
            conn.commit()
    finally:
        conn.close()


app = FastAPI(title="Order Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def startup():
    with db_cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL,
                product_id INTEGER NOT NULL,
                quantity INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'created',
                created_at TIMESTAMP NOT NULL DEFAULT NOW()
            )
            """
        )


@app.get("/health")
def health():
    with db_cursor() as cursor:
        cursor.execute("SELECT 1 AS ok")
        return {"status": "ok", "database": cursor.fetchone()["ok"]}


@app.get("/orders")
def list_orders():
    with db_cursor() as cursor:
        cursor.execute(
            "SELECT id, user_id, product_id, quantity, status, created_at FROM orders ORDER BY id"
        )
        return cursor.fetchall()


@app.post("/orders", status_code=201)
def create_order(payload: OrderPayload):
    if payload.quantity < 1:
        raise HTTPException(status_code=400, detail="Quantity must be positive")

    user_response = requests.get(f"{USER_SERVICE_URL}/users/{payload.user_id}", timeout=3)
    if user_response.status_code != 200:
        raise HTTPException(status_code=404, detail="User not found")

    product_response = requests.get(f"{PRODUCT_SERVICE_URL}/products/{payload.product_id}", timeout=3)
    if product_response.status_code != 200:
        raise HTTPException(status_code=404, detail="Product not found")

    with db_cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO orders (user_id, product_id, quantity)
            VALUES (%s, %s, %s)
            RETURNING id, user_id, product_id, quantity, status, created_at
            """,
            (payload.user_id, payload.product_id, payload.quantity),
        )
        return cursor.fetchone()
