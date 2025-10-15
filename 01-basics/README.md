# 01. Docker Basics - พื้นฐาน Docker

## Docker คืออะไร?

Docker เป็น Platform สำหรับการพัฒนา Deploy และรัน Application ในรูปแบบของ Container ซึ่งช่วยให้เราสามารถแพ็คเกจ Application พร้อมกับ Dependencies ทั้งหมดไว้ด้วยกัน

### ทำไมต้องใช้ Docker?

**ปัญหาเดิม:**
- "It works on my machine" - รันได้บนเครื่องเราแต่ไม่ได้บนเครื่องอื่น
- การติดตั้ง Dependencies ซับซ้อน
- ใช้ทรัพยากรเยอะเมื่อใช้ Virtual Machine
- การ Deploy ที่ไม่สม่ำเสมอ

**Docker แก้ปัญหาอย่างไร:**
- ✅ รันได้เหมือนกันทุกที่ (Dev, Test, Production)
- ✅ แพ็คเกจ App พร้อม Dependencies
- ✅ เบากว่า VM มาก (ใช้ RAM และ CPU น้อยกว่า)
- ✅ Start/Stop เร็ว (วินาทีเดียว)
- ✅ แยก Environment ของแต่ละ App

## Container vs Virtual Machine

### Virtual Machine (VM)
```
┌─────────────────────────────────┐
│         Application A           │
│         Application B           │
├─────────────────────────────────┤
│        Guest OS (Linux)         │
├─────────────────────────────────┤
│          Hypervisor             │
├─────────────────────────────────┤
│     Host OS (Windows/Linux)     │
├─────────────────────────────────┤
│      Physical Hardware          │
└─────────────────────────────────┘
```

### Docker Container
```
┌─────────────────────────────────┐
│     Container A │ Container B   │
│    (App + Libs) │ (App + Libs)  │
├─────────────────────────────────┤
│        Docker Engine            │
├─────────────────────────────────┤
│     Host OS (Linux/Windows)     │
├─────────────────────────────────┤
│      Physical Hardware          │
└─────────────────────────────────┘
```

**ความแตกต่าง:**
| Feature | Container | Virtual Machine |
|---------|-----------|-----------------|
| ขนาด | MB | GB |
| เวลา Startup | วินาที | นาที |
| Performance | Native | Slower |
| Isolation | Process-level | Complete |
| OS | Share Host OS | Separate OS |

## คำศัพท์พื้นฐาน

### Image
- เปรียบเหมือน "Class" ใน OOP
- เป็น Template สำหรับสร้าง Container
- Read-only และสามารถแชร์ได้
- สร้างจาก Dockerfile

### Container
- เปรียบเหมือน "Object/Instance" ใน OOP
- สร้างจาก Image
- สามารถ Start, Stop, Delete ได้
- แต่ละ Container แยกกัน

### Docker Hub
- Registry สำหรับเก็บ Image
- เหมือน GitHub แต่สำหรับ Docker Image
- มี Official Image มากมาย (nginx, node, python, etc.)

### Dockerfile
- ไฟล์สคริปต์สำหรับสร้าง Image
- บอกขั้นตอนการสร้าง Image

## การติดตั้ง Docker

### Windows และ macOS
1. ดาวน์โหลด Docker Desktop: https://www.docker.com/products/docker-desktop
2. ติดตั้งและเปิดใช้งาน
3. ตรวจสอบการติดตั้ง:
```bash
docker --version
docker-compose --version
```

### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group (ไม่ต้องใช้ sudo)
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

## คำสั่งพื้นฐาน

### 1. ตรวจสอบ Docker Version
```bash
docker --version
docker version  # แสดงข้อมูลละเอียด
docker info     # แสดงข้อมูลระบบ
```

### 2. ทำงานกับ Container

#### รัน Container แรก
```bash
# รัน nginx web server
docker run nginx

# รันแบบ Background (-d = detached)
docker run -d nginx

# รันและตั้งชื่อ Container
docker run -d --name my-nginx nginx

# รันและ Map Port
docker run -d -p 8080:80 --name my-nginx nginx
# เปิดเบราว์เซอร์ไปที่ http://localhost:8080
```

#### ดู Container ที่กำลังรัน
```bash
# ดู Container ที่กำลังรันอยู่
docker ps

# ดูทุก Container (รวมที่หยุดแล้ว)
docker ps -a

# ดูแบบละเอียด
docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
```

#### จัดการ Container
```bash
# หยุด Container
docker stop my-nginx

# Start Container อีกครั้ง
docker start my-nginx

# Restart Container
docker restart my-nginx

# ดู Logs
docker logs my-nginx
docker logs -f my-nginx  # ติดตามแบบ real-time

# ลบ Container
docker rm my-nginx

# ลบ Container ที่กำลังรัน (force)
docker rm -f my-nginx
```

#### เข้าไปใน Container
```bash
# เข้าไปใช้ bash ใน Container
docker exec -it my-nginx bash

# รันคำสั่งใน Container
docker exec my-nginx ls -la

# เข้าไปตอน run
docker run -it ubuntu bash
```

### 3. ทำงานกับ Image

#### ดึง Image จาก Docker Hub
```bash
# Pull image
docker pull nginx
docker pull nginx:1.23  # ระบุ version

# ดู Image ที่มี
docker images

# ค้นหา Image
docker search nginx
```

#### จัดการ Image
```bash
# ดู Image ทั้งหมด
docker images

# ลบ Image
docker rmi nginx

# ลบ Image ทั้งหมดที่ไม่ได้ใช้
docker image prune

# ดู Image layers
docker history nginx
```

### 4. ดูการใช้ทรัพยากร
```bash
# ดูการใช้ Resource แบบ real-time
docker stats

# ดูข้อมูล Container
docker inspect my-nginx
```

### 5. ทำความสะอาดระบบ
```bash
# ลบ Container ที่หยุดแล้วทั้งหมด
docker container prune

# ลบ Image ที่ไม่ได้ใช้
docker image prune

# ลบ Volume ที่ไม่ได้ใช้
docker volume prune

# ลบทั้งหมด (Container, Image, Network, Volume ที่ไม่ได้ใช้)
docker system prune -a
```

## 🎯 Workshop 1: รัน Container แรกของคุณ

### Mission 1: รัน Web Server
```bash
# 1. รัน nginx web server
docker run -d -p 8080:80 --name my-first-nginx nginx

# 2. ตรวจสอบว่ารันอยู่
docker ps

# 3. เปิดเบราว์เซอร์ไปที่ http://localhost:8080
# ควรเห็นหน้า "Welcome to nginx!"

# 4. ดู logs
docker logs my-first-nginx

# 5. หยุดและลบ
docker stop my-first-nginx
docker rm my-first-nginx
```

### Mission 2: รัน Interactive Container
```bash
# 1. รัน Ubuntu container แบบ interactive
docker run -it --name my-ubuntu ubuntu bash

# 2. ใน Container ลองรันคำสั่ง:
cat /etc/os-release
apt-get update
apt-get install -y curl
curl https://example.com

# 3. ออกจาก Container (พิมพ์ exit หรือกด Ctrl+D)
exit

# 4. ลบ Container
docker rm my-ubuntu
```

### Mission 3: รัน Database
```bash
# 1. รัน PostgreSQL
docker run -d \
  --name my-postgres \
  -e POSTGRES_PASSWORD=mysecret \
  -e POSTGRES_DB=testdb \
  -p 5432:5432 \
  postgres:15

# 2. ตรวจสอบ logs เพื่อดูว่า database พร้อมแล้ว
docker logs my-postgres

# 3. เชื่อมต่อเข้า Database
docker exec -it my-postgres psql -U postgres -d testdb

# 4. ลอง SQL commands:
# \l              (แสดง databases)
# \dt             (แสดง tables)
# CREATE TABLE test (id INT, name VARCHAR(50));
# \q              (ออกจาก psql)

# 5. หยุดและลบ
docker stop my-postgres
docker rm my-postgres
```

### Mission 4: Mount Volume
```bash
# 1. สร้างไฟล์ HTML
mkdir -p /tmp/docker-workshop
echo "<h1>Hello from Docker!</h1>" > /tmp/docker-workshop/index.html

# 2. รัน nginx และ mount ไฟล์เข้าไป
docker run -d \
  --name my-custom-nginx \
  -p 8080:80 \
  -v /tmp/docker-workshop:/usr/share/nginx/html \
  nginx

# 3. เปิดเบราว์เซอร์ http://localhost:8080
# ควรเห็น "Hello from Docker!"

# 4. แก้ไขไฟล์
echo "<h1>Updated content!</h1>" > /tmp/docker-workshop/index.html

# 5. Refresh เบราว์เซอร์ - เนื้อหาควรเปลี่ยน!

# 6. ทำความสะอาด
docker stop my-custom-nginx
docker rm my-custom-nginx
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ Docker คืออะไรและทำไมต้องใช้
- ✅ ความแตกต่างระหว่าง Container และ VM
- ✅ คำศัพท์พื้นฐาน (Image, Container, Docker Hub)
- ✅ การติดตั้ง Docker
- ✅ คำสั่งพื้นฐานที่ต้องรู้
- ✅ การรัน Container จาก Image ต่างๆ
- ✅ การจัดการ Container และ Image

## 🎓 แบบฝึกหัด

1. รัน nginx และ apache2 พร้อมกันบน port ต่างกัน
2. รัน MySQL container และสร้าง database ใหม่
3. รัน Node.js container และลองรันโค้ด JavaScript
4. ลองใช้ `docker stats` เพื่อดูการใช้ resource

## ➡️ บทถัดไป

[02. Dockerfile และการสร้าง Image](../02-dockerfile/README.md)

---

**Happy Docker! 🐳**
