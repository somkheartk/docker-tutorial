# 05. Optimization และ Multi-stage Builds

## ทำไมต้อง Optimize Docker Images?

**ปัญหาของ Images ที่ใหญ่เกินไป:**
- ⏰ Build และ Deploy ช้า
- 💾 ใช้ space เยอะ
- 🔒 มี attack surface มากขึ้น
- 💰 ค่าใช้จ่าย bandwidth และ storage สูง
- 🐌 Pull/Push นานขึ้น

**เป้าหมาย:**
- ✅ ลดขนาด Image ให้เล็กที่สุด
- ✅ ลดเวลา Build
- ✅ ลดจำนวน vulnerabilities
- ✅ เพิ่ม security

## เทคนิคการลดขนาด Image

### 1. เลือก Base Image ที่เล็ก

```dockerfile
# ❌ ไม่ดี - ใหญ่มาก (1GB+)
FROM ubuntu:22.04

# ⚠️ พอใช้ (200-300MB)
FROM node:18

# ✅ ดี (100-150MB)
FROM node:18-slim

# ✅✅ ดีที่สุด (40-50MB)
FROM node:18-alpine
```

**เปรียบเทียบขนาด:**
| Base Image | Size |
|------------|------|
| ubuntu:22.04 | ~77MB |
| node:18 | ~990MB |
| node:18-slim | ~245MB |
| node:18-alpine | ~175MB |

### 2. Multi-stage Builds

Multi-stage builds ช่วยให้เราแยก build environment และ runtime environment

```dockerfile
# ❌ Single-stage (ขนาดใหญ่)
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install  # รวม devDependencies
COPY . .
RUN npm run build
CMD ["node", "dist/app.js"]
# ผลลัพธ์: ~1GB+

# ✅ Multi-stage (ขนาดเล็ก)
# Stage 1: Build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
CMD ["node", "dist/app.js"]
# ผลลัพธ์: ~200MB
```

### 3. Layer Caching

Docker cache แต่ละ layer - วางคำสั่งที่เปลี่ยนบ่อยไว้ล่างสุด

```dockerfile
# ❌ ไม่ดี - cache ไม่ได้ใช้
FROM node:18-alpine
WORKDIR /app
COPY . .                    # เปลี่ยนบ่อย - rebuild ทุกอย่าง
RUN npm ci

# ✅ ดี - ใช้ cache ได้
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./       # เปลี่ยนไม่บ่อย
RUN npm ci                  # cache ได้
COPY . .                    # เปลี่ยนบ่อย - rebuild แค่นี้
```

### 4. รวม RUN Commands

```dockerfile
# ❌ ไม่ดี - หลาย layers
FROM alpine
RUN apk update
RUN apk add --no-cache curl
RUN apk add --no-cache git
RUN apk add --no-cache vim

# ✅ ดี - layer เดียว
FROM alpine
RUN apk update && \
    apk add --no-cache \
        curl \
        git \
        vim && \
    rm -rf /var/cache/apk/*
```

### 5. ใช้ .dockerignore

```
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.local
.vscode
.idea
coverage
.next
dist
build
*.md
.DS_Store
Thumbs.db
```

### 6. ลบไฟล์ชั่วคราว

```dockerfile
# ❌ ไม่ดี - ไฟล์ temporary ยังอยู่
FROM node:18-alpine
RUN apk add --no-cache python3 make g++
RUN npm install
RUN apk del python3 make g++  # ลบแต่ layer ยังมีขนาด

# ✅ ดี - ลบใน layer เดียวกัน
FROM node:18-alpine
RUN apk add --no-cache python3 make g++ && \
    npm install && \
    apk del python3 make g++ && \
    rm -rf /tmp/*
```

### 7. ใช้ npm ci แทน npm install

```dockerfile
# ❌ ไม่ดี
RUN npm install

# ✅ ดี - เร็วกว่าและ reproducible
RUN npm ci --only=production
```

## 🎯 Workshop: Optimize Node.js Application

### Mission 1: Before Optimization

**app.js**
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ message: 'Hello Docker!' });
});

app.listen(3000, () => {
  console.log('Server running');
});
```

**package.json**
```json
{
  "name": "optimize-demo",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "eslint": "^8.50.0"
  }
}
```

**Dockerfile.before**
```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["node", "app.js"]
```

```bash
# Build
docker build -f Dockerfile.before -t app:before .

# ตรวจสอบขนาด
docker images | grep app

# app:before จะมีขนาด ~990MB
```

### Mission 2: Basic Optimization

**Dockerfile.optimized**
```dockerfile
# ใช้ alpine
FROM node:18-alpine

WORKDIR /app

# Copy เฉพาะ package files ก่อน
COPY package*.json ./

# Install เฉพาะ production dependencies
RUN npm ci --only=production

# Copy source code
COPY app.js ./

EXPOSE 3000

CMD ["node", "app.js"]
```

```bash
# Build
docker build -f Dockerfile.optimized -t app:optimized .

# ตรวจสอบขนาด
docker images | grep app

# app:optimized จะมีขนาด ~180MB (ลดลง ~82%)
```

### Mission 3: Multi-stage Build

**Dockerfile.multistage**
```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Stage 2: Build (ถ้ามี TypeScript หรือ build step)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# RUN npm run build

# Stage 3: Production
FROM node:18-alpine AS production
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy dependencies และ app
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs package.json ./
COPY --chown=nodejs:nodejs app.js ./

# เปลี่ยนเป็น non-root user
USER nodejs

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "app.js"]
```

```bash
# Build
docker build -f Dockerfile.multistage -t app:multistage .

# ตรวจสอบขนาด
docker images | grep app

# app:multistage จะมีขนาด ~130MB
```

### Mission 4: ใช้ Distroless

Distroless images มีเฉพาะ runtime ไม่มี shell หรือ package manager

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Distroless
FROM gcr.io/distroless/nodejs18-debian11
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY package.json app.js ./
EXPOSE 3000
CMD ["app.js"]
```

```bash
docker build -f Dockerfile.distroless -t app:distroless .
docker images | grep app

# app:distroless จะมีขนาด ~150MB และ secure มากกว่า
```

## Advanced Optimization Techniques

### 1. Optimize Dependencies

```dockerfile
# แยก production และ development dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force && \
    # ลบ unnecessary files
    rm -rf /root/.npm && \
    # Remove documentation
    find /app/node_modules -name "*.md" -delete && \
    find /app/node_modules -name "LICENSE" -delete && \
    find /app/node_modules -name "CHANGELOG*" -delete
```

### 2. Build-time Arguments

```dockerfile
ARG NODE_VERSION=18
ARG NPM_CONFIG_LOGLEVEL=info

FROM node:${NODE_VERSION}-alpine

# ใช้ build args
ENV NPM_CONFIG_LOGLEVEL=${NPM_CONFIG_LOGLEVEL}

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

CMD ["node", "app.js"]
```

```bash
# Build ด้วย custom arguments
docker build \
  --build-arg NODE_VERSION=20 \
  --build-arg NPM_CONFIG_LOGLEVEL=warn \
  -t app:custom .
```

### 3. BuildKit Features

Enable BuildKit สำหรับ performance ที่ดีขึ้น:

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# หรือเพิ่มใน command
DOCKER_BUILDKIT=1 docker build -t app .
```

**ใช้ cache mounts:**
```dockerfile
# syntax=docker/dockerfile:1.4

FROM node:18-alpine
WORKDIR /app

COPY package*.json ./

# ใช้ cache mount สำหรับ npm cache
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

COPY . .
CMD ["node", "app.js"]
```

### 4. Parallel Builds

```dockerfile
# syntax=docker/dockerfile:1.4

FROM node:18-alpine AS base
WORKDIR /app

# Stage ที่ไม่ depend กันจะ build พร้อมกัน
FROM base AS deps
COPY package*.json ./
RUN npm ci --only=production

FROM base AS test-deps
COPY package*.json ./
RUN npm ci

FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS test
COPY --from=test-deps /app/node_modules ./node_modules
COPY . .
RUN npm test

# Final stage
FROM base AS production
COPY --from=build /app/dist ./dist
COPY --from=deps /app/node_modules ./node_modules
CMD ["node", "dist/app.js"]
```

## เปรียบเทียบผลลัพธ์

```bash
# สรุปขนาด images
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep app

# ผลลัพธ์:
# app    before        990MB
# app    optimized     180MB  (ลด 82%)
# app    multistage    130MB  (ลด 87%)
# app    distroless    150MB  (ลด 85%, secure++)
```

## Best Practices Summary

### ✅ DO
1. ใช้ alpine หรือ slim base images
2. ใช้ multi-stage builds
3. ใช้ .dockerignore
4. รวม RUN commands
5. วาง layers ที่เปลี่ยนบ่อยไว้ล่าง
6. ใช้ npm ci แทน npm install
7. ลบ cache และ temporary files
8. ใช้ non-root user
9. กำหนด health checks
10. ใช้ specific version tags

### ❌ DON'T
1. ใช้ latest tag
2. แยก RUN commands โดยไม่จำเป็น
3. COPY ทั้งหมดก่อน install dependencies
4. เก็บ devDependencies ใน production
5. เก็บ source code ที่ไม่ใช้
6. Run as root
7. ใส่ secrets ใน Dockerfile
8. Build แบบไม่มี cache strategy

## Performance Tips

```dockerfile
# 1. ใช้ npm ci แทน npm install
RUN npm ci --only=production

# 2. Clean up ใน layer เดียวกัน
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. ใช้ --no-cache สำหรับ apk
RUN apk add --no-cache curl git

# 4. ลบ npm cache
RUN npm ci && npm cache clean --force

# 5. Parallel downloads
RUN npm ci --prefer-offline --no-audit
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ ทำไมต้อง optimize Docker images
- ✅ เทคนิคการลดขนาด image
- ✅ Multi-stage builds
- ✅ Layer caching strategies
- ✅ การใช้ .dockerignore
- ✅ Alpine และ Distroless images
- ✅ BuildKit features
- ✅ Best practices สำหรับ optimization

## 🎓 แบบฝึกหัด

1. Optimize React application ให้มีขนาดเล็กที่สุด
2. สร้าง multi-stage build สำหรับ Go application
3. เปรียบเทียบ build time ระหว่าง มี cache และไม่มี cache
4. ใช้ BuildKit cache mounts

## ➡️ บทถัดไป

[06. Docker Security](../06-security/README.md)

---

**Happy Docker! 🐳**
