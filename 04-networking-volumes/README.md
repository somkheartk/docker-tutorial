# 04. Networking และ Volumes

## Docker Networking

Docker Networking ช่วยให้ Container สามารถสื่อสารกันได้ทั้งภายในเครื่องเดียวกันและระหว่างเครื่อง

### ประเภทของ Network Drivers

#### 1. Bridge (Default)
- Network แบบ private ภายในเครื่อง host เดียว
- Container สามารถสื่อสารกันได้ผ่าน container name
- เหมาะสำหรับ single host

```bash
# สร้าง bridge network
docker network create my-bridge-network

# รัน container ใน network
docker run -d --name web --network my-bridge-network nginx
docker run -d --name api --network my-bridge-network node:18-alpine
```

#### 2. Host
- Container ใช้ network ของ host โดยตรง
- ไม่มี network isolation
- Performance ดีกว่า bridge

```bash
docker run -d --network host nginx
```

#### 3. None
- ไม่มี network
- Container แยกอย่างสมบูรณ์

```bash
docker run -d --network none alpine
```

#### 4. Overlay
- สำหรับ multi-host networking (Docker Swarm)
- Container บนคนละเครื่องสื่อสารกันได้

#### 5. Macvlan
- Container มี MAC address เป็นของตัวเอง
- เหมือนเป็น physical device ใน network

### คำสั่งจัดการ Network

```bash
# ดู networks ทั้งหมด
docker network ls

# สร้าง network
docker network create my-network
docker network create --driver bridge my-bridge

# ดูรายละเอียด network
docker network inspect my-network

# เชื่อมต่อ container เข้า network
docker network connect my-network container-name

# ตัดการเชื่อมต่อ
docker network disconnect my-network container-name

# ลบ network
docker network rm my-network

# ลบ network ที่ไม่ได้ใช้
docker network prune
```

## 🎯 Workshop: Network Communication

### Mission 1: Container-to-Container Communication

```bash
# 1. สร้าง custom network
docker network create app-network

# 2. รัน PostgreSQL
docker run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:15-alpine

# 3. รัน app ที่เชื่อมต่อ PostgreSQL
docker run -d \
  --name app \
  --network app-network \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=secret \
  -p 3000:3000 \
  myapp

# 4. ทดสอบการเชื่อมต่อ
docker exec app ping postgres
docker exec app nslookup postgres

# 5. ทำความสะอาด
docker stop postgres app
docker rm postgres app
docker network rm app-network
```

### Mission 2: Multiple Networks

```bash
# สร้าง 2 networks
docker network create frontend
docker network create backend

# รัน database ใน backend network
docker run -d --name db --network backend postgres:15

# รัน api ใน backend network
docker run -d --name api --network backend myapi

# เชื่อม api เข้า frontend network ด้วย
docker network connect frontend api

# รัน web ใน frontend network
docker run -d --name web --network frontend -p 80:80 nginx

# ตอนนี้:
# - web สื่อสารกับ api ได้ (ผ่าน frontend)
# - api สื่อสารกับ db ได้ (ผ่าน backend)
# - web สื่อสารกับ db ไม่ได้ (isolated)
```

### Mission 3: Network Aliases

```bash
# สร้าง network
docker network create app-net

# รัน container ด้วย network alias
docker run -d \
  --name api-1 \
  --network app-net \
  --network-alias api \
  myapi

docker run -d \
  --name api-2 \
  --network app-net \
  --network-alias api \
  myapi

# Load balancing - requests จะกระจายไปยัง api-1 และ api-2
docker run --network app-net alpine nslookup api
```

## Docker Volumes

Volumes เป็นวิธีที่ดีที่สุดในการเก็บข้อมูลถาวรใน Docker เพราะ:
- ข้อมูลไม่หายเมื่อลบ Container
- แชร์ข้อมูลระหว่าง Container ได้
- ง่ายต่อการ Backup และ Restore
- ทำงานได้ทั้ง Linux และ Windows

### ประเภทของ Volumes

#### 1. Named Volumes (แนะนำ)
```bash
# สร้าง named volume
docker volume create my-data

# ใช้งาน
docker run -d -v my-data:/app/data myapp

# ดูรายการ volumes
docker volume ls

# ดูรายละเอียด
docker volume inspect my-data

# ลบ volume
docker volume rm my-data
```

#### 2. Anonymous Volumes
```bash
# Docker สร้าง volume ให้อัตโนมัติ
docker run -d -v /app/data myapp

# Volume จะมีชื่อเป็น hash
docker volume ls
```

#### 3. Bind Mounts
```bash
# Mount directory จาก host
docker run -d -v /host/path:/container/path myapp
docker run -d -v $(pwd)/data:/app/data myapp

# Read-only mount
docker run -d -v $(pwd)/config:/app/config:ro myapp
```

### เปรียบเทียบ Volumes vs Bind Mounts

| Feature | Named Volumes | Bind Mounts |
|---------|---------------|-------------|
| Location | Docker manages | You specify |
| Backup | ง่าย | ต้องทำเอง |
| Permissions | Docker จัดการ | Host permissions |
| Performance | ดีกว่า (especially Windows/Mac) | อาจช้ากว่า |
| Use Case | Production data | Development |

### คำสั่งจัดการ Volumes

```bash
# สร้าง volume
docker volume create my-volume

# ดู volumes
docker volume ls

# ดูรายละเอียด
docker volume inspect my-volume

# ลบ volume
docker volume rm my-volume

# ลบ volumes ที่ไม่ได้ใช้
docker volume prune

# ลบ volumes ทั้งหมดที่ไม่ได้ใช้
docker volume prune -a
```

## 🎯 Workshop: Persistent Data

### Mission 1: Database with Persistent Storage

```bash
# 1. สร้าง volume สำหรับ database
docker volume create postgres-data

# 2. รัน PostgreSQL ด้วย volume
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:15

# 3. สร้าง database และ table
docker exec -it postgres psql -U postgres
# CREATE DATABASE testdb;
# \c testdb
# CREATE TABLE users (id SERIAL, name VARCHAR(50));
# INSERT INTO users (name) VALUES ('John'), ('Jane');
# SELECT * FROM users;
# \q

# 4. ลบ container
docker stop postgres
docker rm postgres

# 5. สร้าง container ใหม่ด้วย volume เดิม
docker run -d \
  --name postgres-new \
  -e POSTGRES_PASSWORD=secret \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:15

# 6. ตรวจสอบว่าข้อมูลยังอยู่
docker exec -it postgres-new psql -U postgres -d testdb
# SELECT * FROM users;
# ข้อมูลยังคงอยู่!

# 7. ทำความสะอาด
docker stop postgres-new
docker rm postgres-new
docker volume rm postgres-data
```

### Mission 2: Development with Bind Mount

สร้างโปรเจค:
```bash
mkdir -p /tmp/docker-dev
cd /tmp/docker-dev
```

**app.js**
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ message: 'Hello from Docker!' });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

**package.json**
```json
{
  "name": "dev-app",
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

**Dockerfile**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "app.js"]
```

```bash
# Build image
docker build -t dev-app .

# รันด้วย bind mount สำหรับ hot reload
docker run -d \
  --name dev-app \
  -p 3000:3000 \
  -v $(pwd):/app \
  -v /app/node_modules \
  dev-app

# แก้ไขไฟล์ app.js (เปลี่ยน message)
# Restart container เพื่อเห็นการเปลี่ยนแปลง
docker restart dev-app

# ทดสอบ
curl http://localhost:3000

# ทำความสะอาด
docker stop dev-app
docker rm dev-app
```

### Mission 3: Sharing Data Between Containers

```bash
# 1. สร้าง shared volume
docker volume create shared-data

# 2. Container ที่เขียนข้อมูล
docker run -d \
  --name writer \
  -v shared-data:/data \
  alpine \
  sh -c "while true; do echo $(date) >> /data/log.txt; sleep 5; done"

# 3. Container ที่อ่านข้อมูล
docker run -d \
  --name reader \
  -v shared-data:/data:ro \
  alpine \
  sh -c "tail -f /data/log.txt"

# 4. ดู logs จาก reader
docker logs -f reader

# 5. ทำความสะอาด
docker stop writer reader
docker rm writer reader
docker volume rm shared-data
```

### Mission 4: Backup และ Restore

```bash
# 1. สร้าง volume พร้อมข้อมูล
docker volume create app-data
docker run -v app-data:/data alpine sh -c "echo 'Important data' > /data/file.txt"

# 2. Backup volume
docker run --rm \
  -v app-data:/data \
  -v $(pwd):/backup \
  alpine \
  tar czf /backup/app-data-backup.tar.gz -C /data .

# 3. ลบ volume
docker volume rm app-data

# 4. Restore volume
docker volume create app-data-restored
docker run --rm \
  -v app-data-restored:/data \
  -v $(pwd):/backup \
  alpine \
  sh -c "cd /data && tar xzf /backup/app-data-backup.tar.gz"

# 5. ตรวจสอบข้อมูล
docker run --rm -v app-data-restored:/data alpine cat /data/file.txt

# 6. ทำความสะอาด
docker volume rm app-data-restored
rm app-data-backup.tar.gz
```

## Docker Compose with Networks & Volumes

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    networks:
      - frontend
    volumes:
      - ./html:/usr/share/nginx/html:ro
    ports:
      - "80:80"

  api:
    build: ./api
    networks:
      - frontend
      - backend
    environment:
      - DB_HOST=postgres
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    networks:
      - backend
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro

  redis:
    image: redis:7-alpine
    networks:
      - backend
    volumes:
      - redis-data:/data

volumes:
  postgres-data:
    driver: local
  redis-data:
    driver: local

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # ไม่สามารถเข้าถึงจากภายนอกได้
```

## Best Practices

### Networking
1. ✅ ใช้ custom networks แทน default bridge
2. ✅ แยก network ตาม layer (frontend, backend)
3. ✅ ใช้ network aliases สำหรับ service discovery
4. ✅ ตั้งค่า internal networks สำหรับ backend services
5. ✅ ใช้ DNS names แทน IP addresses

### Volumes
1. ✅ ใช้ named volumes สำหรับ production data
2. ✅ ใช้ bind mounts สำหรับ development
3. ✅ Mount config files เป็น read-only
4. ✅ Backup volumes เป็นประจำ
5. ✅ ใช้ .dockerignore กับ bind mounts
6. ✅ ไม่ mount sensitive data โดยตรง

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ ประเภทของ Docker Networks (bridge, host, none, overlay)
- ✅ การสื่อสารระหว่าง Container
- ✅ Network isolation และ security
- ✅ ประเภทของ Volumes (named, anonymous, bind mounts)
- ✅ การเก็บข้อมูลถาวร
- ✅ การแชร์ข้อมูลระหว่าง Container
- ✅ Backup และ Restore volumes
- ✅ Best practices สำหรับ networking และ volumes

## 🎓 แบบฝึกหัด

1. สร้าง 3-tier architecture (web, api, db) ด้วย 3 networks แยกกัน
2. สร้าง volume backup script อัตโนมัติ
3. ทดสอบ network isolation ระหว่าง services
4. สร้าง development environment ด้วย bind mounts

## ➡️ บทถัดไป

[05. Optimization และ Multi-stage Builds](../05-optimization/README.md)

---

**Happy Docker! 🐳**
