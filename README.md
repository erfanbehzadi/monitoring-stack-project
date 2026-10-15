# Monitoring Stack Project

A containerized monitoring stack built with Docker Compose. Nginx serves a demo page and exposes its status, an exporter turns that status into Prometheus metrics, cAdvisor collects container metrics, Prometheus scrapes and stores everything, and Grafana is used to explore and visualize the data.

Built as a hands-on project to practice infrastructure observability.

---

## Architecture

```text
Docker containers ──► cAdvisor (:8080) ───────────────┐
                                                       ├──► Prometheus (:9090) ──► Grafana (:3000)
Nginx (:80) ──► Nginx Exporter (:9113) ───────────────┘
```

Prometheus pulls (scrapes) metrics from cAdvisor, the Nginx exporter, and itself every 15 seconds. Grafana queries Prometheus as its data source.

### Components

| Component | Image | Purpose | Port |
|:---|:---|:---|:---|
| **Nginx** | `nginx:alpine` | Serves a demo page and exposes `/stub_status` | 80 |
| **Nginx Prometheus Exporter** | `nginx/nginx-prometheus-exporter` | Reads `stub_status` and exposes it as Prometheus metrics | 9113 |
| **cAdvisor** | `ghcr.io/google/cadvisor` | Collects per-container CPU, memory, network, and filesystem metrics | 8080 |
| **Prometheus** | `prom/prometheus` | Scrapes and stores metrics as time series | 9090 |
| **Grafana** | `grafana/grafana` | Visualization; the Prometheus data source is provisioned automatically | 3000 |

---

## Features

- **Container monitoring:** resource metrics for every container on the host, via cAdvisor
- **Web server metrics:** Nginx connections and request counts via the official Prometheus exporter
- **Automatic Grafana data source:** Prometheus is configured through Grafana provisioning, no manual setup
- **Persistent data:** Prometheus and Grafana data are stored in named Docker volumes
- **Startup ordering and restarts:** `depends_on` between services and `restart: unless-stopped` on all of them
- **Read-only configuration mounts:** config files are mounted with `:ro`
- **Dedicated network:** all services share one Docker bridge network and reach each other by container name
- **Load test script:** generates traffic against Nginx so you can watch the metrics change

---

## Quick Start

### Prerequisites

- Docker Engine
- Docker Compose v2 (`docker compose`)
- Optional: Apache Bench (`ab`) for the load test. On Debian/Ubuntu: `sudo apt install apache2-utils`. Without it, the script falls back to `curl`.

### 1. Clone the repository

```bash
git clone https://github.com/erfanbehzadi/monitoring-stack-project.git
cd monitoring-stack-project
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Check that everything is running

```bash
docker compose ps
```

Expected containers: `nginx`, `nginx-exporter`, `cadvisor`, `prometheus`, `grafana`.

### 4. Open the services

| Service | URL | Credentials |
|:---|:---|:---|
| **Grafana** | http://localhost:3000 | `admin` / `admin123` (set in `docker-compose.yml`) |
| **Prometheus** | http://localhost:9090 | none |
| **cAdvisor** | http://localhost:8080 | none |
| **Nginx demo page** | http://localhost | none |

This setup is meant for local demos. See [Limitations](#limitations-and-possible-improvements) before using it anywhere else.

---

## Usage

### Generate traffic

```bash
chmod +x scripts/load-test.sh
./scripts/load-test.sh
```

If `ab` is installed, the script runs two tests: 200 requests (concurrency 50), then 1,000 requests (concurrency 100). If `ab` is not installed, it falls back to `curl` with a much smaller load. Console messages are in Persian.

You can also just refresh http://localhost several times; the demo page says to watch the request counter in Grafana.

### Check the Nginx status endpoint

```bash
curl http://localhost/stub_status
```

Example output:

```text
Active connections: 1
server accepts handled requests
 10 10 10
Reading: 0 Writing: 1 Waiting: 0
```

### Check the Prometheus targets

Open http://localhost:9090/targets. Three targets should show **UP**: `prometheus`, `cadvisor`, and `nginx`.

### Example PromQL queries

Run these in the Prometheus UI (http://localhost:9090) or in a Grafana panel:

```promql
# Nginx connections accepted (counter)
nginx_connections_accepted

# Nginx requests per second over the last minute
rate(nginx_http_requests_total[1m])

# CPU usage per container
rate(container_cpu_usage_seconds_total[5m])

# Memory usage of the nginx container
container_memory_usage_bytes{name="nginx"}
```

### Dashboards

The repository provisions the Prometheus data source only. To visualize the data, create panels in Grafana with the queries above, or import a community cAdvisor or Nginx dashboard from grafana.com (Dashboards, then Import).

---

## Project Structure

```text
monitoring-stack-project/
├── docker-compose.yml                 # All services, network, and volumes
├── README.md
├── prometheus/
│   └── prometheus.yml                 # Scrape configuration
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── prometheus.yml         # Auto-provisioned data source
├── nginx/
│   ├── nginx.conf                     # Nginx config with /stub_status
│   ├── html/
│   │   └── index.html                 # Demo page
│   └── logs/                          # Access and error logs (mounted volume)
└── scripts/
    └── load-test.sh                   # Traffic generator
```

---

## Configuration Details

### Prometheus (`prometheus/prometheus.yml`)

```yaml
global:
  scrape_interval: 15s

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

Targets use container names (`cadvisor`, `nginx-exporter`), which Docker resolves on the shared `monitoring` network.

### Nginx status endpoint (`nginx/nginx.conf`)

```nginx
location /stub_status {
    stub_status on;
    access_log off;
}
```

The exporter is started with `-nginx.scrape-uri=http://nginx:80/stub_status`, reads this endpoint, and exposes the values to Prometheus on port 9113.

### Grafana data source (`grafana/provisioning/datasources/prometheus.yml`)

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

Grafana loads this file at startup, so Prometheus is already connected the first time you log in.

### cAdvisor

cAdvisor runs with `privileged: true` and mounts `/`, `/sys`, `/var/run`, `/var/lib/docker`, and `/dev/disk` read-only. This is what lets it read container and host resource data.

---

## Stopping the Stack

```bash
# Stop and remove the containers (data volumes are kept)
docker compose down

# Also remove the volumes (full cleanup)
docker compose down -v
```

---

## Troubleshooting

| Issue | What to check |
|:---|:---|
| Grafana shows "No data" | Open `:9090/targets` and confirm all targets are UP, then check the time range in Grafana |
| cAdvisor shows no metrics | Confirm it runs with `privileged: true` and the host paths in `docker-compose.yml` are mounted |
| Nginx exporter target is DOWN | Check that `curl http://localhost/stub_status` returns data and the `nginx` container is running |
| Grafana password does not change | `GF_SECURITY_ADMIN_PASSWORD` only applies on first startup. Remove the volume with `docker compose down -v` to reset |
| Port already in use | Change the host port in `docker-compose.yml`, for example `"8081:80"` |

---

## Limitations and Possible Improvements

This is a learning and demo project, not a production setup.

- All service ports are published on the host, and Prometheus and cAdvisor have no authentication
- cAdvisor runs as a privileged container
- The Grafana admin password is written in `docker-compose.yml`; a real setup would use an `.env` file or a secrets manager
- Images use the `latest` tag; pinning versions would make the stack reproducible
- No alerting yet: adding Alertmanager and alert rules would be the next step
- No host-level metrics yet: adding Node Exporter would cover CPU, disk, and memory of the host itself
- Dashboards are not provisioned from files; exporting them as JSON would make the setup fully automatic

---

## Contact

- **Email:** erfanbs02@gmail.com
- **GitHub:** [erfanbehzadi](https://github.com/erfanbehzadi)
- **Docker Hub:** [erfanbehzadii](https://hub.docker.com/u/erfanbehzadii)
