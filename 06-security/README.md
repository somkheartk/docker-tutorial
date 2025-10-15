# 06. Docker Security

## ทำไม Docker Security สำคัญ?

Container ที่ไม่ปลอดภัยอาจนำไปสู่:
- 🔓 ข้อมูลรั่วไหล
- 💥 System compromise
- 🐛 Malware distribution
- 💰 ความเสียหายทางธุรกิจ

## Common Security Risks

### 1. Running as Root
```dockerfile
# ❌ อันตราย - Run as root
FROM node:18-alpine
COPY app.js /app/
CMD ["node", "/app/app.js"]

# ✅ ปลอดภัย - Run as non-root user
FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs
COPY --chown=nodejs:nodejs app.js /app/
CMD ["node", "/app/app.js"]
```

### 2. Using Latest Tags
```dockerfile
# ❌ ไม่ปลอดภัย - latest อาจมี vulnerabilities ใหม่
FROM node:latest

# ✅ ปลอดภัย - ระบุ version ชัดเจน
FROM node:18.17.0-alpine
```

### 3. Exposing Secrets
```dockerfile
# ❌ อันตราย - hardcode secrets
FROM node:18-alpine
ENV DATABASE_PASSWORD=mysecretpassword
ENV API_KEY=1234567890

# ✅ ปลอดภัย - ใช้ runtime secrets
FROM node:18-alpine
# Pass secrets at runtime
# docker run -e DATABASE_PASSWORD=$DB_PASS app
```

### 4. Large Attack Surface
```dockerfile
# ❌ มี attack surface เยอะ
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    curl wget git vim nano less

# ✅ Minimal attack surface
FROM alpine:3.18
RUN apk add --no-cache nodejs npm
```

## Security Best Practices

### 1. Use Official Images
```dockerfile
# ✅ Official image - verified และ maintained
FROM node:18-alpine
FROM postgres:15-alpine
FROM nginx:alpine

# ❌ Random image - unknown source
FROM randomuser/node
```

### 2. Scan Images for Vulnerabilities

```bash
# ใช้ Docker Scout
docker scout cves myapp:latest

# ใช้ Trivy
trivy image myapp:latest

# ใช้ Snyk
snyk container test myapp:latest
```

### 3. Create Non-root User
```dockerfile
FROM node:18-alpine

# สร้าง user และ group
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# กำหนด ownership
WORKDIR /app
COPY --chown=appuser:appgroup . .

# เปลี่ยนเป็น non-root user
USER appuser

CMD ["node", "app.js"]
```

### 4. Use Read-only Filesystem
```bash
# รัน container ด้วย read-only filesystem
docker run --read-only \
  --tmpfs /tmp \
  --tmpfs /run \
  myapp:latest
```

### 5. Limit Container Capabilities
```bash
# Drop all capabilities และเพิ่มเฉพาะที่ต้องการ
docker run \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  myapp:latest

# Run without privileged mode
docker run --security-opt=no-new-privileges myapp:latest
```

### 6. Use Docker Content Trust
```bash
# Enable Content Trust
export DOCKER_CONTENT_TRUST=1

# Pull และ push images จะต้อง signed
docker pull nginx:alpine
docker push myapp:latest
```

### 7. Secrets Management

#### ใช้ Docker Secrets (Swarm mode)
```bash
# สร้าง secret
echo "mysecretpassword" | docker secret create db_password -

# ใช้ใน service
docker service create \
  --name myapp \
  --secret db_password \
  myapp:latest
```

#### ใช้ Environment Variables (ระวัง!)
```bash
# ❌ ไม่ดี - secret อยู่ใน command history
docker run -e DB_PASSWORD=secret myapp

# ✅ ดีกว่า - อ่านจากไฟล์
docker run --env-file .env myapp

# ✅ ดีที่สุด - ใช้ secrets management service
# AWS Secrets Manager, HashiCorp Vault, etc.
```

#### ใช้ Build Secrets (BuildKit)
```dockerfile
# syntax=docker/dockerfile:1.4

FROM node:18-alpine

WORKDIR /app

# ใช้ secret ตอน build
RUN --mount=type=secret,id=npm_token \
    echo "//registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token)" > .npmrc && \
    npm install && \
    rm .npmrc

COPY . .
CMD ["node", "app.js"]
```

```bash
# Build ด้วย secret
DOCKER_BUILDKIT=1 docker build \
  --secret id=npm_token,src=$HOME/.npmrc \
  -t myapp .
```

## 🎯 Workshop: Secure Docker Images

### Mission 1: Basic Security

**app.js**
```javascript
const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

**Dockerfile.insecure**
```dockerfile
FROM node:latest
WORKDIR /app
COPY . .
RUN npm install
ENV SECRET_KEY=mysecretkey123
EXPOSE 3000
CMD ["node", "app.js"]
```

**Dockerfile.secure**
```dockerfile
# ใช้ specific version และ alpine
FROM node:18.17.0-alpine

# Install dumb-init สำหรับ proper signal handling
RUN apk add --no-cache dumb-init

# สร้าง non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY --chown=nodejs:nodejs app.js ./

# เปลี่ยนเป็น non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init เพื่อ handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
```

```bash
# Build
docker build -f Dockerfile.secure -t secure-app:latest .

# รันด้วย security options
docker run -d \
  --name secure-app \
  --read-only \
  --tmpfs /tmp \
  --security-opt=no-new-privileges:true \
  --cap-drop=ALL \
  -p 3000:3000 \
  secure-app:latest

# ตรวจสอบ
curl http://localhost:3000/health

# ทำความสะอาด
docker stop secure-app
docker rm secure-app
```

### Mission 2: Image Scanning

```bash
# Install Trivy
# macOS
brew install trivy

# Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan image
trivy image node:18-alpine
trivy image secure-app:latest

# Scan สำหรับ HIGH และ CRITICAL เท่านั้น
trivy image --severity HIGH,CRITICAL secure-app:latest

# Export เป็น JSON
trivy image -f json -o results.json secure-app:latest

# Scan Dockerfile
trivy config Dockerfile.secure
```

### Mission 3: Docker Bench Security

```bash
# Run Docker Bench Security
docker run --rm \
  --net host \
  --pid host \
  --userns host \
  --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/etc:ro \
  --label docker_bench_security \
  docker/docker-bench-security

# ดูผลลัพธ์และแก้ไข warnings/errors
```

## Docker Compose Security

```yaml
version: '3.8'

services:
  app:
    image: myapp:latest
    # อ่าน secrets จาก file
    secrets:
      - db_password
    environment:
      - NODE_ENV=production
      # ไม่ใส่ password โดยตรง
    # Security options
    security_opt:
      - no-new-privileges:true
    # Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp
      - /run
    # ลด capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    # Restart policy
    restart: unless-stopped
    
  db:
    image: postgres:15-alpine
    secrets:
      - db_password
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    # Database ไม่ควรเปิด port ออกไป
    # ports:
    #   - "5432:5432"
    networks:
      - backend
    restart: unless-stopped

secrets:
  db_password:
    file: ./secrets/db_password.txt

volumes:
  db-data:

networks:
  backend:
    driver: bridge
    internal: true  # ไม่สามารถเข้าถึงจากภายนอกได้
```

## Security Checklist

### Image Security
- [ ] ใช้ official base images
- [ ] ใช้ specific version tags (ไม่ใช่ latest)
- [ ] ใช้ minimal images (alpine, distroless)
- [ ] Scan images สำหรับ vulnerabilities
- [ ] Update images เป็นประจำ
- [ ] Sign images (Content Trust)

### Dockerfile Security
- [ ] Run as non-root user
- [ ] ไม่ hardcode secrets
- [ ] ลบ unnecessary tools
- [ ] ใช้ .dockerignore
- [ ] Multi-stage builds
- [ ] COPY แทน ADD
- [ ] ใช้ HEALTHCHECK

### Runtime Security
- [ ] ใช้ read-only filesystem
- [ ] ลด Linux capabilities
- [ ] ใช้ security-opt=no-new-privileges
- [ ] ไม่ใช้ --privileged
- [ ] ไม่ mount Docker socket
- [ ] กำหนด resource limits
- [ ] ใช้ secrets management
- [ ] Enable logging

### Network Security
- [ ] ใช้ custom networks
- [ ] แยก networks ตาม layer
- [ ] ใช้ internal networks สำหรับ backend
- [ ] ไม่เปิด port ที่ไม่จำเป็น
- [ ] ใช้ TLS/SSL

### Host Security
- [ ] Update Docker Engine เป็นประจำ
- [ ] Enable Docker Content Trust
- [ ] ใช้ user namespaces
- [ ] กำหนด ulimits
- [ ] Monitor container activity
- [ ] Audit logs

## Security Tools

### 1. Trivy - Vulnerability Scanner
```bash
trivy image myapp:latest
```

### 2. Docker Scout
```bash
docker scout cves myapp:latest
docker scout recommendations myapp:latest
```

### 3. Snyk
```bash
snyk container test myapp:latest
```

### 4. Clair
```bash
# Run Clair scanner
docker run -d --name clair clair/clair:latest
```

### 5. Anchore
```bash
# Install Anchore CLI
pip install anchorecli

# Scan image
anchore-cli image add myapp:latest
anchore-cli image vuln myapp:latest all
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ Security risks ที่พบบ่อยใน Docker
- ✅ การใช้ non-root user
- ✅ การจัดการ secrets อย่างปลอดภัย
- ✅ Image scanning และ vulnerability management
- ✅ Docker security best practices
- ✅ Security tools (Trivy, Docker Scout, etc.)
- ✅ Runtime security options
- ✅ Security checklist

## 🎓 แบบฝึกหัด

1. Scan images ของคุณหา vulnerabilities
2. แก้ไข Dockerfile ให้ผ่าน security best practices
3. ตั้งค่า Docker Bench Security และแก้ไข issues
4. ใช้ secrets management ใน production environment

## ➡️ บทถัดไป

[07. Advanced Topics](../07-advanced/README.md)

---

**Happy Docker! 🐳**
