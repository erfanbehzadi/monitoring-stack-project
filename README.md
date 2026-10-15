
---

```markdown
# Monitoring Stack Project

A complete **DevOps monitoring stack** built with Docker Compose, featuring Prometheus, Grafana, cAdvisor, and Nginx. This project demonstrates real-world infrastructure observability by collecting metrics from containers, the host system, and a web server, then visualizing them in Grafana dashboards.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Docker Host                          │
│                                                          │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │  Nginx   │───▶│ Nginx        │    │   cAdvisor    │  │
│  │  :80     │    │ Exporter     │    │   :8080       │  │
│  │          │    │ :9113        │    │               │  │
│  └──────────┘    └──────┬───────┘    └───────┬───────┘  │
│                         │                     │          │
│                         ▼                     ▼          │
│                  ┌─────────────────────────────────┐     │
│                  │         Prometheus              │     │
│                  │            :9090                │     │
│                  └──────────────┬──────────────────┘     │
│                                 │                        │
│                                 ▼                        │
│                  ┌─────────────────────────────────┐     │
│                  │           Grafana               │     │
│                  │            :3000                │     │
│                  └─────────────────────────────────┘     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Components

| Component | Purpose | Port |
|:---|:---|:---|
| **Nginx** | Web server generating traffic and logs | 80 |
| **Nginx Prometheus Exporter** | Exposes Nginx metrics (connections, requests) | 9113 |
| **cAdvisor** | Collects container resource metrics (CPU, memory, network) | 8080 |
| **Prometheus** | Time-series database that scrapes and stores all metrics | 9090 |
| **Grafana** | Visualization platform with dashboards | 3000 |

---

## Features

- **Container Monitoring**: Real-time CPU, memory, and network metrics for all containers via cAdvisor
- **Web Server Observability**: Nginx connection and request metrics via the official Prometheus exporter
- **Host System Monitoring**: Disk, filesystem, and system-level metrics
- **Automated Data Source Provisioning**: Grafana automatically connects to Prometheus on startup
- **Load Testing Script**: Built-in Bash script using Apache Bench (`ab`) to generate traffic and see live metrics
- **Clean Network Isolation**: All services communicate over a dedicated Docker bridge network

---

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2+
- At least 4 GB RAM (recommended)

### 1. Clone the repository

```bash
git clone https://github.com/erfanbehzadi/monitoring-stack-project.git
cd monitoring-stack-project
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Verify containers are running

```bash
docker compose ps
```

Expected output: 5 containers running (`nginx`, `nginx-exporter`, `cadvisor`, `prometheus`, `grafana`).

### 4. Access the services

| Service | URL | Credentials |
|:---|:---|:---|
| **Grafana** | http://localhost:3000 | `admin` / `admin123` |
| **Prometheus** | http://localhost:9090 | — |
| **cAdvisor** | http://localhost:8080 | — |
| **Nginx Demo** | http://localhost | — |

---

## Usage

### Generate traffic and watch metrics

Run the included load test script to simulate real traffic:

```bash
chmod +x scripts/load-test.sh
./scripts/load-test.sh
```

The script sends 200 requests first (light load), then 1,000 requests (heavy load). After running, refresh your Grafana dashboard to see the spike in metrics.

### Verify Nginx metrics endpoint

```bash
curl http://localhost/stub_status
```

Expected output:

```
Active connections: 1
server accepts handled requests
 10 10 10
Reading: 0 Writing: 1 Waiting: 0
```

### Verify Prometheus targets

Open http://localhost:9090/targets — all three targets (`prometheus`, `cadvisor`, `nginx-exporter`) should show status **UP**.

### Query metrics in Prometheus

Example queries:

```promql
# Total Nginx connections accepted
nginx_connections_accepted

# Container CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Container memory usage
container_memory_usage_bytes
```

---

## Project Structure

```
monitoring-stack-project/
├── docker-compose.yml                    # Main stack definition
├── README.md
├── LICENSE
├── prometheus/
│   └── prometheus.yml                    # Prometheus scrape configuration
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── prometheus.yml            # Auto-provisioned Grafana data source
├── nginx/
│   ├── nginx.conf                        # Nginx configuration with stub_status
│   ├── html/
│   │   └── index.html                    # Demo landing page
│   └── logs/                             # Nginx access and error logs
└── scripts/
    └── load-test.sh                      # Traffic generator using Apache Bench
```

---

## Configuration Details

### Prometheus Scrape Targets

Prometheus is configured to scrape three targets every 15 seconds:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']
```

### Nginx Metrics Endpoint

The Nginx configuration exposes a `/stub_status` endpoint for the Prometheus exporter:

```nginx
location /stub_status {
    stub_status on;
    access_log off;
}
```

### Grafana Auto-Provisioning

Grafana automatically loads the Prometheus data source on startup via the provisioning configuration. No manual setup required.

---

## Skills Demonstrated

This project showcases hands-on experience with:

- **Docker & Docker Compose** — Multi-container orchestration with health checks and dependency management
- **Prometheus** — Metric collection, scrape configuration, and PromQL queries
- **Grafana** — Dashboard creation, data source provisioning, and visualization
- **cAdvisor** — Container resource monitoring
- **Nginx** — Web server configuration and stub_status module
- **Linux & Bash** — Scripting for load testing and automation
- **Networking** — Docker bridge networks, port mapping, and service discovery

---

## Stopping the Stack

```bash
# Stop containers (data persists in volumes)
docker compose down

# Stop and remove volumes (full cleanup)
docker compose down -v
```

---

## Troubleshooting

| Issue | Solution |
|:---|:---|
| Grafana shows "No data" | Check Prometheus targets at `:9090/targets` — all should be UP |
| cAdvisor not collecting metrics | Ensure `privileged: true` is set and host paths are mounted |
| Nginx exporter shows DOWN | Verify `/stub_status` returns data: `curl localhost/stub_status` |
| Port already in use | Change the host port in `docker-compose.yml` (e.g., `"8081:80"`) |

---

## Contact

- **Email:** erfanbs02@gmail.com
- **GitHub:** [erfanbehzadi](https://github.com/erfanbehzadi)
- **Docker Hub:** [erfanbehzadii](https://hub.docker.com/u/erfanbehzadii)
```

---

## چرا این README قویه؟

| بخش | چرا مهمه |
|:---|:---|
| **نمودار معماری** | کارفرما در یک نگاه می‌فهمه پروژه چیه |
| **جدول اجزا** | نشون می‌ده هر ابزار چیکار می‌کنه |
| **Quick Start** | هر کسی بتونه در ۵ دقیقه اجراش کنه |
| **Usage** | نشون می‌ده پروژه واقعاً کار می‌کنه |
| **Configuration Details** | عمق فنی رو نشون می‌ده |
| **Skills Demonstrated** | دقیقاً می‌گه چه مهارت‌هایی داری |
| **Troubleshooting** | نشون می‌ده تجربه‌ی عملی داری |

---

**الان این README رو کپی کن، توی گیت‌هاب `README.md` رو باز کن و جایگزینش کن. بعد Commit کن. 🚀**
