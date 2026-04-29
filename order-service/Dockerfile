FROM python:3.11-slim

WORKDIR /usr/src/app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends netcat-openbsd gcc libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY entrypoint.sh .
RUN chmod +x /usr/src/app/entrypoint.sh

COPY app ./app

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
