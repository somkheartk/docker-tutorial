# Docker Tutorial - สอน Docker ตั้งแต่เริ่มต้นจนถึงขั้นสูง

คู่มือการเรียนรู้ Docker แบบครบวงจร พร้อม Workshop และตัวอย่างการนำไปใช้จริงจนถึง CI/CD บน AWS

## 📚 เนื้อหาในคอร์ส

### [01. Docker Basics - พื้นฐาน Docker](./01-basics/README.md)
- Docker คืออะไร และทำไมต้องใช้
- การติดตั้ง Docker
- คำสั่งพื้นฐานที่ต้องรู้
- Container vs Virtual Machine
- Workshop: รัน Container แรกของคุณ

### [02. Dockerfile และการสร้าง Image](./02-dockerfile/README.md)
- ทำความรู้จักกับ Dockerfile
- คำสั่งสำคัญใน Dockerfile
- การสร้างและจัดการ Docker Image
- Best Practices สำหรับการเขียน Dockerfile
- Workshop: สร้าง Image สำหรับ Node.js App

### [03. Docker Compose](./03-docker-compose/README.md)
- Docker Compose คืออะไร
- การเขียน docker-compose.yml
- การจัดการ Multi-container Application
- Workshop: ติดตั้ง Web App + Database ด้วย Compose

### [04. Networking และ Volumes](./04-networking-volumes/README.md)
- Docker Networking พื้นฐาน
- ประเภทของ Network ใน Docker
- การจัดการข้อมูลด้วย Volumes
- Named Volumes vs Bind Mounts
- Workshop: การเชื่อมต่อระหว่าง Container

### [05. Optimization และ Multi-stage Builds](./05-optimization/README.md)
- การลดขนาด Image
- Multi-stage Builds
- Layer Caching
- การเพิ่มประสิทธิภาพ Build Time
- Workshop: ปรับปรุง Image ให้เล็กและเร็วขึ้น

### [06. Docker Security](./06-security/README.md)
- Security Best Practices
- การจัดการ Secrets
- Image Scanning
- User Permissions และ Root
- Workshop: ทำให้ Container ปลอดภัยยิ่งขึ้น

### [07. Advanced Topics](./07-advanced/README.md)
- Docker Swarm พื้นฐาน
- Health Checks
- Resource Limits
- Logging และ Monitoring
- Workshop: การจัดการ Production Environment

### [08. CI/CD บน AWS](./08-cicd-aws/README.md)
- การใช้ ECR (Elastic Container Registry)
- การ Deploy ด้วย ECS (Elastic Container Service)
- การตั้งค่า CI/CD Pipeline
- GitHub Actions + AWS
- Workshop: Deploy Application บน AWS แบบ End-to-End

## 🚀 การเริ่มต้นใช้งาน

### ความต้องการเบื้องต้น
- คอมพิউเตอร์ที่รัน Windows, macOS หรือ Linux
- Docker Desktop ติดตั้งแล้ว
- Text Editor (แนะนำ VS Code)
- Git สำหรับ Clone Repository

### การติดตั้ง Docker

**Windows & macOS:**
1. ดาวน์โหลด [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. ติดตั้งและรัน Docker Desktop
3. ตรวจสอบการติดตั้ง: `docker --version`

**Linux (Ubuntu):**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Clone Repository นี้
```bash
git clone https://github.com/somkheartk/docker-tutorial.git
cd docker-tutorial
```

## 📖 วิธีการเรียน

1. **เริ่มจากพื้นฐาน**: เริ่มจาก 01-basics และเรียนไปตามลำดับ
2. **ทำ Workshop**: แต่ละบทมี Workshop ให้ลองทำตาม
3. **ทดลองด้วยตัวเอง**: แก้ไขโค้ดและทดลองเพื่อเข้าใจลึกขึ้น
4. **อ่าน Documentation**: อ่าน [Docker Docs](https://docs.docker.com/) เป็นเสริม

## 🎯 เป้าหมายของคอร์ส

หลังจากเรียนจบคอร์สนี้ คุณจะสามารถ:
- ✅ เข้าใจหลักการทำงานของ Docker
- ✅ สร้างและจัดการ Container ได้
- ✅ เขียน Dockerfile และสร้าง Image
- ✅ ใช้ Docker Compose สำหรับ Multi-container Apps
- ✅ จัดการ Networking และ Volumes
- ✅ เขียน Dockerfile ที่มีประสิทธิภาพและปลอดภัย
- ✅ Deploy Application ด้วย CI/CD บน AWS

## 🛠️ Workshop Projects

Repository นี้มี Workshop Projects ที่ใช้ทำตามในแต่ละบท:
- Simple Web Server (Node.js)
- Full-stack Application (React + Node.js + PostgreSQL)
- Microservices Architecture
- Production Deployment บน AWS

## 📚 แหล่งเรียนรู้เพิ่มเติม

- [Official Docker Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Blog](https://www.docker.com/blog/)
- [Best Practices Guide](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 การมีส่วนร่วม

ยินดีรับ Pull Request และ Issues หากพบข้อผิดพลาดหรือต้องการปรับปรุงเนื้อหา!

## 📝 License

MIT License - ใช้งานและแก้ไขได้ตามต้องการ

---

**Happy Learning! 🐳**