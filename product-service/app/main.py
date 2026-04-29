import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@app-db:5432/app_db_dev")


class ProductPayload(BaseModel):
    name: str
    description: str
    price: float
    stock: int


@contextmanager
def db_cursor():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            yield cursor
            conn.commit()
    finally:
        conn.close()


app = FastAPI(title="Product Service")
Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.on_event("startup")
def startup():
    with db_cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT NOT NULL,
                price NUMERIC(10, 2) NOT NULL,
                stock INTEGER NOT NULL
            )
            """
        )
        cursor.execute("SELECT COUNT(*) AS count FROM products")
        if cursor.fetchone()["count"] == 0:
            cursor.executemany(
                "INSERT INTO products (name, description, price, stock) VALUES (%s, %s, %s, %s)",
                [
                    ("SRE Handbook", "Operational playbook for resilient systems", 25.00, 40),
                    ("Monitoring Bundle", "Prometheus and Grafana starter kit", 49.99, 20),
                    ("Incident Drill", "Simulation package for on-call training", 15.50, 100),
                ],
            )


@app.get("/health")
def health():
    with db_cursor() as cursor:
        cursor.execute("SELECT 1 AS ok")
        return {"status": "ok", "database": cursor.fetchone()["ok"]}


@app.get("/products")
def list_products():
    with db_cursor() as cursor:
        cursor.execute("SELECT id, name, description, price::float, stock FROM products ORDER BY id")
        return cursor.fetchall()


@app.get("/products/{product_id}")
def get_product(product_id: int):
    with db_cursor() as cursor:
        cursor.execute(
            "SELECT id, name, description, price::float, stock FROM products WHERE id=%s",
            (product_id,),
        )
        product = cursor.fetchone()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        return product


@app.post("/products", status_code=201)
def create_product(payload: ProductPayload):
    with db_cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO products (name, description, price, stock)
            VALUES (%s, %s, %s, %s)
            RETURNING id, name, description, price::float, stock
            """,
            (payload.name, payload.description, payload.price, payload.stock),
        )
        return cursor.fetchone()
