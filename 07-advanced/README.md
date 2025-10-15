# 07. Advanced Topics

## Docker Swarm พื้นฐาน

Docker Swarm เป็น orchestration tool ของ Docker สำหรับจัดการ cluster ของ Docker nodes

### Swarm Concepts

**Node Types:**
- **Manager Node**: จัดการ cluster state และ scheduling
- **Worker Node**: รัน containers ตามที่ manager สั่ง

**Services:**
- Replicated Services: รันจำนวน replica ที่กำหนด
- Global Services: รันทุก node

### เริ่มต้นใช้งาน Swarm

```bash
# Initialize Swarm
docker swarm init

# ดูสถานะ
docker node ls

# สร้าง service
docker service create --name web --replicas 3 -p 80:80 nginx

# ดู services
docker service ls

# ดู tasks
docker service ps web

# Scale service
docker service scale web=5

# Update service
docker service update --image nginx:alpine web

# ลบ service
docker service rm web
```

### Deploy Stack ด้วย Docker Compose

```yaml
# docker-stack.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - webnet

  api:
    image: myapi:latest
    deploy:
      replicas: 5
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    networks:
      - webnet
      - backend

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    deploy:
      placement:
        constraints:
          - node.role == manager
    networks:
      - backend

secrets:
  db_password:
    external: true

volumes:
  db-data:

networks:
  webnet:
  backend:
```

```bash
# Deploy stack
docker stack deploy -c docker-stack.yml myapp

# ดู stacks
docker stack ls

# ดู services ใน stack
docker stack services myapp

# ลบ stack
docker stack rm myapp
```

## Health Checks

Health checks ช่วยให้ Docker ตรวจสอบว่า container ทำงานปกติหรือไม่

### ใน Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

EXPOSE 3000

# Health check ทุก 30 วินาที
HEALTHCHECK --interval=30s \
            --timeout=3s \
            --start-period=10s \
            --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "app.js"]
```

### ใน Docker Compose

```yaml
services:
  api:
    build: .
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

### ตรวจสอบ Health Status

```bash
# ดู health status
docker ps

# ดูรายละเอียด health check
docker inspect --format='{{json .State.Health}}' container-name | jq

# ดู health check logs
docker inspect container-name | jq '.[0].State.Health.Log'
```

## Resource Limits

### CPU Limits

```bash
# จำกัด CPU shares (relative weight)
docker run --cpu-shares 512 myapp

# จำกัด CPU cores
docker run --cpus 2 myapp
docker run --cpus 0.5 myapp

# Pin to specific CPUs
docker run --cpuset-cpus 0,1 myapp
```

### Memory Limits

```bash
# จำกัด memory
docker run -m 512m myapp
docker run --memory 1g myapp

# Memory reservation (soft limit)
docker run -m 1g --memory-reservation 512m myapp

# OOM kill disable (ระวัง!)
docker run -m 512m --oom-kill-disable myapp

# Memory swap limit
docker run -m 512m --memory-swap 1g myapp
```

### ใน Docker Compose

```yaml
services:
  api:
    image: myapi:latest
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Logging

### Log Drivers

```bash
# Default json-file
docker run --log-driver json-file myapp

# Syslog
docker run --log-driver syslog myapp

# Journald (systemd)
docker run --log-driver journald myapp

# Fluentd
docker run --log-driver fluentd --log-opt fluentd-address=localhost:24224 myapp

# Splunk
docker run --log-driver splunk --log-opt splunk-token=xxx myapp

# AWS CloudWatch
docker run --log-driver awslogs \
  --log-opt awslogs-region=us-east-1 \
  --log-opt awslogs-group=myapp \
  myapp
```

### Log Options

```bash
# จำกัดขนาดและจำนวนไฟล์
docker run \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp
```

### ใน Docker Compose

```yaml
services:
  api:
    image: myapi:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "production,api"
```

### ดู Logs

```bash
# ดู logs
docker logs container-name

# Follow logs
docker logs -f container-name

# ดู logs ย้อนหลัง
docker logs --tail 100 container-name
docker logs --since 1h container-name

# ดู logs พร้อม timestamp
docker logs -t container-name
```

## Monitoring

### Docker Stats

```bash
# ดู resource usage แบบ real-time
docker stats

# ดูเฉพาะบาง containers
docker stats container1 container2

# Format output
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### System Events

```bash
# ดู events แบบ real-time
docker events

# Filter events
docker events --filter event=start
docker events --filter container=myapp
docker events --since 1h

# Format events
docker events --format '{{json .}}'
```

### Prometheus + Grafana

**docker-compose-monitoring.yml**
```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
```

**prometheus.yml**
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
```

```bash
# Start monitoring stack
docker-compose -f docker-compose-monitoring.yml up -d

# เข้าถึง:
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3001 (admin/admin)
# cAdvisor: http://localhost:8080
```

## 🎯 Workshop: Production Setup

### Mission: Complete Production Environment

**โครงสร้างโปรเจค:**
```
production-app/
├── app/
│   ├── Dockerfile
│   ├── app.js
│   └── package.json
├── nginx/
│   ├── Dockerfile
│   └── nginx.conf
├── monitoring/
│   ├── prometheus.yml
│   └── grafana-dashboards/
├── docker-compose.yml
├── docker-compose.prod.yml
└── .env.example
```

**app/Dockerfile**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs package.json ./
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
CMD ["node", "dist/app.js"]
```

**nginx/nginx.conf**
```nginx
upstream api {
    least_conn;
    server api:3000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
    }

    # API proxy
    location /api/ {
        proxy_pass http://api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    location /api/login {
        limit_req zone=api_limit burst=5;
        proxy_pass http://api/login;
    }
}
```

**docker-compose.yml**
```yaml
version: '3.8'

services:
  nginx:
    build: ./nginx
    ports:
      - "80:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - frontend
    volumes:
      - nginx-logs:/var/log/nginx
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped

  api:
    build: ./app
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - REDIS_HOST=redis
    env_file:
      - .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=appdb
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped

secrets:
  db_password:
    file: ./secrets/db_password.txt

volumes:
  postgres-data:
  redis-data:
  nginx-logs:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ Docker Swarm พื้นฐาน
- ✅ Health Checks
- ✅ Resource Limits (CPU, Memory)
- ✅ Logging strategies
- ✅ Monitoring ด้วย Prometheus + Grafana
- ✅ Production-ready setup
- ✅ Load balancing และ scaling

## 🎓 แบบฝึกหัด

1. ตั้งค่า Docker Swarm cluster 3 nodes
2. Deploy application ด้วย rolling update
3. ตั้งค่า monitoring dashboard ใน Grafana
4. ทดสอบ auto-scaling based on metrics

## ➡️ บทถัดไป

[08. CI/CD บน AWS](../08-cicd-aws/README.md)

---

**Happy Docker! 🐳**
