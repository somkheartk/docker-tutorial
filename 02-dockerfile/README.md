# 02. Dockerfile และการสร้าง Image

## Dockerfile คืออะไร?

Dockerfile เป็นไฟล์ข้อความที่บอกขั้นตอนการสร้าง Docker Image เหมือนกับสูตรการทำอาหาร - มีขั้นตอนการทำที่ชัดเจนเพื่อให้ได้ผลลัพธ์ที่ต้องการ

## โครงสร้างพื้นฐานของ Dockerfile

```dockerfile
# Base image - เริ่มจาก image ไหน
FROM node:18-alpine

# Metadata
LABEL maintainer="your-email@example.com"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Copy files
COPY package*.json ./

# Run commands
RUN npm install

# Copy application files
COPY . .

# Expose port
EXPOSE 3000

# Command to run
CMD ["node", "app.js"]
```

## คำสั่งสำคัญใน Dockerfile

### 1. FROM - ระบุ Base Image
```dockerfile
# Official image
FROM node:18

# Specific version
FROM node:18.17.0

# Alpine (เล็กกว่า)
FROM node:18-alpine

# Multi-stage build
FROM node:18 AS builder
```

### 2. WORKDIR - กำหนด Working Directory
```dockerfile
# กำหนด directory สำหรับทำงาน
WORKDIR /app

# คำสั่งถัดไปจะทำงานใน /app
COPY . .
RUN npm install
```

### 3. COPY และ ADD - คัดลอกไฟล์
```dockerfile
# COPY - แนะนำให้ใช้
COPY package.json .
COPY src/ ./src/
COPY . .

# ADD - มีความสามารถเพิ่ม (auto-extract tar, download URL)
ADD https://example.com/file.tar.gz /tmp/
ADD archive.tar.gz /tmp/  # จะแตกไฟล์อัตโนมัติ
```

**Best Practice:** ใช้ COPY เสมอ เว้นแต่ต้องการ feature พิเศษของ ADD

### 4. RUN - รันคำสั่งตอน Build
```dockerfile
# รันคำสั่งเดียว
RUN npm install

# รันหลายคำสั่ง (แนะนำ - ลด layers)
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ใช้ exec form
RUN ["npm", "install"]
```

### 5. CMD - คำสั่งเริ่มต้นเมื่อ Container รัน
```dockerfile
# Exec form (แนะนำ)
CMD ["node", "app.js"]

# Shell form
CMD node app.js

# หมายเหตุ: มีได้แค่ CMD เดียวใน Dockerfile
```

### 6. ENTRYPOINT - กำหนดคำสั่งหลัก
```dockerfile
# ENTRYPOINT ใช้ร่วมกับ CMD
ENTRYPOINT ["node"]
CMD ["app.js"]

# สามารถ override CMD ได้:
# docker run myapp server.js
```

**ความแตกต่าง CMD vs ENTRYPOINT:**
- CMD: ถูก override ได้ง่าย
- ENTRYPOINT: เป็นคำสั่งหลักที่ไม่ค่อยเปลี่ยน
- ใช้ร่วมกัน: ENTRYPOINT เป็นคำสั่ง, CMD เป็น arguments

### 7. ENV - ตั้งค่า Environment Variables
```dockerfile
# กำหนดตัวแปร
ENV NODE_ENV=production
ENV PORT=3000

# หลายตัวแปร
ENV NODE_ENV=production \
    PORT=3000 \
    DB_HOST=localhost
```

### 8. EXPOSE - ระบุ Port
```dockerfile
# เอกสารว่าใช้ port อะไร (ไม่ได้เปิด port จริง)
EXPOSE 3000
EXPOSE 8080 8443
```

### 9. ARG - Build-time Variables
```dockerfile
# กำหนดตัวแปรตอน build
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}

ARG APP_PORT=3000
ENV PORT=${APP_PORT}

# ใช้งาน:
# docker build --build-arg NODE_VERSION=20 .
```

### 10. USER - กำหนด User
```dockerfile
# สร้าง user และใช้งาน (security best practice)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs
```

### 11. VOLUME - กำหนด Volume
```dockerfile
# สร้าง mount point
VOLUME ["/data"]
VOLUME /app/logs
```

### 12. HEALTHCHECK - ตรวจสอบความพร้อม
```dockerfile
# ตรวจสอบว่า container ทำงานปกติหรือไม่
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

## การสร้าง Image

### Build Image
```bash
# Build พื้นฐาน
docker build -t myapp .

# Build และ tag version
docker build -t myapp:1.0.0 .
docker build -t myapp:latest .

# Build หลาย tag
docker build -t myapp:1.0.0 -t myapp:latest .

# Build จาก Dockerfile ชื่ออื่น
docker build -f Dockerfile.dev -t myapp:dev .

# Build ไม่ใช้ cache
docker build --no-cache -t myapp .

# Build ด้วย build arguments
docker build --build-arg NODE_VERSION=20 -t myapp .
```

### Tag Image
```bash
# Tag image
docker tag myapp:latest myapp:1.0.0
docker tag myapp:latest username/myapp:latest

# Tag สำหรับ Docker Hub
docker tag myapp:latest somkheartk/myapp:latest
```

### Push Image
```bash
# Login Docker Hub
docker login

# Push image
docker push somkheartk/myapp:latest
docker push somkheartk/myapp:1.0.0
```

## Best Practices

### 1. ใช้ Official Images
```dockerfile
# ดี - Official image
FROM node:18-alpine

# ไม่ดี - Random image
FROM some-random/node
```

### 2. ใช้ Specific Tags
```dockerfile
# ดี - Specific version
FROM node:18.17.0-alpine

# พอใช้
FROM node:18-alpine

# ไม่ดี - latest เปลี่ยนได้ตลอด
FROM node:latest
```

### 3. เรียง Layer อย่างมีประสิทธิภาพ
```dockerfile
# ดี - สิ่งที่เปลี่ยนบ่อยอยู่ล่าง
FROM node:18-alpine
WORKDIR /app

# Dependencies เปลี่ยนไม่บ่อย - อยู่บน
COPY package*.json ./
RUN npm ci --only=production

# Source code เปลี่ยนบ่อย - อยู่ล่าง
COPY . .

CMD ["node", "app.js"]
```

### 4. รวมคำสั่ง RUN
```dockerfile
# ดี - ลด layers
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ไม่ดี - เยอะเกินไป layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
```

### 5. ใช้ .dockerignore
```
# .dockerignore
node_modules
npm-debug.log
.git
.env
.DS_Store
*.md
coverage
.vscode
```

### 6. ไม่ Run as Root
```dockerfile
FROM node:18-alpine

# สร้าง non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app
COPY --chown=nodejs:nodejs . .

# เปลี่ยนเป็น user nodejs
USER nodejs

CMD ["node", "app.js"]
```

### 7. ใช้ Multi-stage Build
```dockerfile
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
CMD ["node", "dist/app.js"]
```

## 🎯 Workshop 2: สร้าง Docker Image สำหรับ Node.js App

### Mission 1: Simple Node.js App

#### 1. สร้างโปรเจค
```bash
mkdir nodejs-app
cd nodejs-app
```

#### 2. สร้างไฟล์ package.json
```json
{
  "name": "docker-nodejs-app",
  "version": "1.0.0",
  "description": "Simple Node.js app for Docker",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

#### 3. สร้างไฟล์ app.js
```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Docker!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

#### 4. สร้าง Dockerfile
```dockerfile
FROM node:18-alpine

# กำหนด working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY app.js ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run application
CMD ["node", "app.js"]
```

#### 5. สร้าง .dockerignore
```
node_modules
npm-debug.log
.git
.env
*.md
.DS_Store
```

#### 6. Build และ Run
```bash
# Build image
docker build -t nodejs-app:1.0.0 .

# Run container
docker run -d -p 3000:3000 --name my-nodejs-app nodejs-app:1.0.0

# Test
curl http://localhost:3000
curl http://localhost:3000/health

# ดู logs
docker logs my-nodejs-app

# ตรวจสอบ health
docker inspect --format='{{json .State.Health}}' my-nodejs-app

# ทำความสะอาด
docker stop my-nodejs-app
docker rm my-nodejs-app
```

### Mission 2: Multi-stage Build

#### สร้าง Dockerfile.multistage
```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build (สำหรับโปรเจคที่ต้อง build)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# RUN npm run build  # ถ้ามี build step

# Stage 3: Production
FROM node:18-alpine AS production
WORKDIR /app

# สร้าง non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy dependencies
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application
COPY --chown=nodejs:nodejs app.js ./
COPY --chown=nodejs:nodejs package.json ./

# เปลี่ยนเป็น non-root user
USER nodejs

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "app.js"]
```

```bash
# Build
docker build -f Dockerfile.multistage -t nodejs-app:multistage .

# เปรียบเทียบขนาด
docker images | grep nodejs-app

# Run
docker run -d -p 3001:3000 --name nodejs-multistage nodejs-app:multistage

# Test
curl http://localhost:3001

# ทำความสะอาด
docker stop nodejs-multistage
docker rm nodejs-multistage
```

### Mission 3: Build Arguments

#### สร้าง Dockerfile.args
```dockerfile
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

ARG APP_PORT=3000
ENV PORT=${APP_PORT}

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY app.js ./

EXPOSE ${APP_PORT}

CMD ["node", "app.js"]
```

```bash
# Build ด้วย default args
docker build -f Dockerfile.args -t nodejs-app:default .

# Build ด้วย custom args
docker build -f Dockerfile.args --build-arg NODE_VERSION=20 --build-arg APP_PORT=8080 -t nodejs-app:custom .

# Run custom build
docker run -d -p 8080:8080 --name nodejs-custom nodejs-app:custom

# Test
curl http://localhost:8080

# ทำความสะอาด
docker stop nodejs-custom
docker rm nodejs-custom
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ Dockerfile คืออะไรและมีโครงสร้างอย่างไร
- ✅ คำสั่งสำคัญใน Dockerfile (FROM, RUN, COPY, CMD, etc.)
- ✅ ความแตกต่างระหว่าง CMD และ ENTRYPOINT
- ✅ การใช้ ARG และ ENV
- ✅ Best Practices สำหรับเขียน Dockerfile
- ✅ การใช้ .dockerignore
- ✅ Multi-stage Builds
- ✅ Security considerations (non-root user)
- ✅ Health checks

## 🎓 แบบฝึกหัด

1. สร้าง Dockerfile สำหรับ Python Flask app
2. สร้าง Multi-stage build สำหรับ React app
3. ลดขนาด image ให้เล็กที่สุด
4. เพิ่ม health check ให้กับ image

## ➡️ บทถัดไป

[03. Docker Compose](../03-docker-compose/README.md)

---

**Happy Docker! 🐳**
