# SLI and SLO Design

## Service Level Indicators

| SLI | Measurement |
|---|---|
| Availability | Prometheus `up` metric for each backend service |
| Latency | p95 request duration from FastAPI histogram metrics |
| Error rate | Rate of HTTP 5xx responses |
| Request success rate | Ratio of non-5xx requests to total requests |

## Service Level Objectives

| SLO | Target |
|---|---|
| Availability | >= 99% |
| Latency | p95 <= 200 ms for normal load |
| Error rate | <= 1% |
| Request success rate | >= 99% |

## Covered Services

- `auth-service`
- `user-service`
- `product-service`
- `order-service`
- `payment-service`
- `chat-service`

Prometheus and Grafana provide the evidence for these indicators. Alert rules
detect outages, high error rates, elevated latency, resource saturation, and
restart-loop symptoms.
