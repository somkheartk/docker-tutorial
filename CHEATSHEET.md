# Docker Command Cheat Sheet - คำสั่ง Docker ที่ใช้บ่อย

## 📦 Container Commands

### รัน Container
```bash
# รัน container พื้นฐาน
docker run image-name

# รันแบบ interactive + TTY
docker run -it image-name bash

# รันแบบ background (detached)
docker run -d image-name

# รันและตั้งชื่อ
docker run --name my-container image-name

# รันและ map port
docker run -p 8080:80 image-name

# รันด้วย environment variables
docker run -e NODE_ENV=production image-name

# รันด้วย volume
docker run -v /host/path:/container/path image-name

# รันแบบลบอัตโนมัติเมื่อหยุด
docker run --rm image-name

# รันด้วย resource limits
docker run -m 512m --cpus 0.5 image-name
```

### จัดการ Container
```bash
# ดู containers ที่กำลังรัน
docker ps

# ดูทุก container
docker ps -a

# หยุด container
docker stop container-name

# Start container
docker start container-name

# Restart container
docker restart container-name

# ลบ container
docker rm container-name

# ลบ container ที่กำลังรัน (force)
docker rm -f container-name

# ลบทุก container ที่หยุดแล้ว
docker container prune
```

### ดูข้อมูล Container
```bash
# ดู logs
docker logs container-name
docker logs -f container-name  # follow
docker logs --tail 100 container-name  # แสดง 100 บรรทัดล่าสุด

# ดู resource usage
docker stats
docker stats container-name

# ดูรายละเอียด container
docker inspect container-name

# เข้าไปใน container
docker exec -it container-name bash
docker exec -it container-name sh  # สำหรับ alpine
```

## 🖼️ Image Commands

### จัดการ Image
```bash
# ดู images
docker images

# Pull image
docker pull image-name
docker pull image-name:tag

# Build image
docker build -t image-name .
docker build -t image-name:tag .
docker build -f Dockerfile.dev -t image-name .

# Tag image
docker tag image-name new-name:tag

# Push image
docker push image-name:tag

# ลบ image
docker rmi image-name

# ลบ images ที่ไม่ได้ใช้
docker image prune
docker image prune -a  # ลบทั้งหมด
```

### ดูข้อมูล Image
```bash
# ดูรายละเอียด image
docker inspect image-name

# ดู layers
docker history image-name

# Search images
docker search nginx
```

## 🌐 Network Commands

```bash
# ดู networks
docker network ls

# สร้าง network
docker network create network-name

# ดูรายละเอียด network
docker network inspect network-name

# เชื่อมต่อ container เข้า network
docker network connect network-name container-name

# ตัดการเชื่อมต่อ
docker network disconnect network-name container-name

# ลบ network
docker network rm network-name

# ลบ networks ที่ไม่ได้ใช้
docker network prune
```

## 💾 Volume Commands

```bash
# ดู volumes
docker volume ls

# สร้าง volume
docker volume create volume-name

# ดูรายละเอียด volume
docker volume inspect volume-name

# ลบ volume
docker volume rm volume-name

# ลบ volumes ที่ไม่ได้ใช้
docker volume prune
```

## 🎼 Docker Compose Commands

```bash
# Start services
docker-compose up
docker-compose up -d  # background

# Build และ start
docker-compose up --build

# Stop services
docker-compose stop

# Stop และลบ containers
docker-compose down

# Stop, ลบ containers และ volumes
docker-compose down -v

# ดู services
docker-compose ps

# ดู logs
docker-compose logs
docker-compose logs -f
docker-compose logs service-name

# รันคำสั่งใน service
docker-compose exec service-name command

# Build services
docker-compose build
docker-compose build --no-cache

# Restart services
docker-compose restart
docker-compose restart service-name

# Scale services
docker-compose up -d --scale service-name=3
```

## 🧹 System Commands

```bash
# ดูพื้นที่ที่ใช้
docker system df

# ทำความสะอาดทั้งหมด
docker system prune

# ทำความสะอาดทุกอย่าง (รวม volumes)
docker system prune -a --volumes

# ดูข้อมูลระบบ
docker info

# ดู Docker version
docker version
docker --version
```

## 🔍 Debugging Commands

```bash
# ดู events
docker events

# ดู processes ใน container
docker top container-name

# ดู changes ใน filesystem
docker diff container-name

# Copy files
docker cp container-name:/path/to/file ./local-path
docker cp ./local-file container-name:/path/

# Export container
docker export container-name > container.tar

# Import image
docker import container.tar image-name

# Save image
docker save -o image.tar image-name

# Load image
docker load -i image.tar
```

## 🔐 Registry Commands

```bash
# Login to registry
docker login
docker login registry-url

# Logout
docker logout

# Login to ECR (AWS)
aws ecr get-login-password --region region | \
  docker login --username AWS --password-stdin account-id.dkr.ecr.region.amazonaws.com
```

## 🎯 Useful One-liners

```bash
# หยุดและลบทุก container
docker stop $(docker ps -aq) && docker rm $(docker ps -aq)

# ลบทุก image
docker rmi $(docker images -q)

# ลบ dangling images
docker rmi $(docker images -f "dangling=true" -q)

# ลบ exited containers
docker rm $(docker ps -a -f status=exited -q)

# Follow logs ของทุก container
docker ps -q | xargs -L 1 docker logs -f

# ดู IP address ของ container
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container-name

# รัน command ในทุก running container
docker ps -q | xargs -L 1 docker exec -it {} sh
```

## 📊 Format Output

```bash
# Custom format สำหรับ ps
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"

# Custom format สำหรับ images
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# JSON output
docker inspect --format='{{json .}}' container-name | jq

# Get specific field
docker inspect --format='{{.State.Status}}' container-name
```

## 🔧 Build Arguments

```bash
# Build ด้วย args
docker build --build-arg NODE_VERSION=18 -t app .

# Build ไม่ใช้ cache
docker build --no-cache -t app .

# Build target stage
docker build --target production -t app .

# Build แบบ quiet
docker build -q -t app .
```

## 🌟 Tips & Tricks

### Aliases ที่มีประโยชน์
```bash
# เพิ่มใน ~/.bashrc หรือ ~/.zshrc

alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'
alias dprune='docker system prune -af --volumes'
```

### Docker Compose Aliases
```bash
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dclogs='docker-compose logs -f'
alias dcps='docker-compose ps'
```

## 📖 Environment Variables

```bash
# Docker daemon
DOCKER_HOST=unix:///var/run/docker.sock
DOCKER_CERT_PATH=/path/to/certs
DOCKER_TLS_VERIFY=1

# Build
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1

# Registry
DOCKER_CONTENT_TRUST=1
DOCKER_REGISTRY_URL=registry.example.com
```

## 🎓 Learning Resources

- [Official Docker Docs](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Play with Docker](https://labs.play-with-docker.com/)

---

**💡 Tip:** บันทึก cheat sheet นี้ไว้เพื่ออ้างอิงได้ตลอดเวลา!

**Happy Docker! 🐳**
