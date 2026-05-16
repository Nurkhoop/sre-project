# Architecture Diagram

```mermaid
flowchart LR
    Browser[User Browser] --> Nginx[Nginx Frontend and API Gateway]

    Nginx --> Auth[auth-service]
    Nginx --> Users[user-service]
    Nginx --> Products[product-service]
    Nginx --> Orders[order-service]
    Nginx --> Payments[payment-service]
    Nginx --> Chat[chat-service]

    Auth --> DB[(PostgreSQL)]
    Users --> DB
    Products --> DB
    Orders --> DB
    Payments --> DB
    Chat --> DB

    Orders --> Users
    Orders --> Products
    Payments --> Orders

    Prometheus[Prometheus] --> Auth
    Prometheus --> Users
    Prometheus --> Products
    Prometheus --> Orders
    Prometheus --> Payments
    Prometheus --> Chat
    Grafana[Grafana] --> Prometheus

    Terraform[Terraform] --> VM[Cloud VM]
    Ansible[Ansible] --> VM
    VM --> Docker[Docker Compose Stack]
```

## Notes

- Nginx serves the frontend and routes `/api/*` requests to backend services.
- Each FastAPI service exposes `/health` and `/metrics`.
- Prometheus scrapes metrics from all backend services.
- Grafana visualizes service availability, request rate, and error trends.
- The incident simulation breaks the Order Service database hostname.
- Payment Service provides the sixth backend microservice required by the end-term project.
