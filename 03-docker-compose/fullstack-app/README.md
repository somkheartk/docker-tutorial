# Full-stack Application Workshop

โปรเจคตัวอย่างสำหรับ Workshop Docker Compose ที่มี Frontend, Backend และ Database

## โครงสร้างโปรเจค

```
fullstack-app/
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── backend/
│   ├── Dockerfile
│   ├── server.js
│   └── package.json
├── docker-compose.yml
└── README.md
```

## การเริ่มต้นใช้งาน

### 1. Clone หรือสร้างโปรเจค

```bash
cd 03-docker-compose
```

### 2. สร้างไฟล์ตามใน README.md ของ section 03

หรือคัดลอกไฟล์จากตัวอย่างที่ให้มา

### 3. Start Application

```bash
# Start ทุก services
docker-compose up -d

# ดู logs
docker-compose logs -f

# ตรวจสอบสถานะ
docker-compose ps
```

### 4. ทดสอบ Application

- Frontend: http://localhost:8080
- Backend API: http://localhost:3000/api/tasks
- Health Check: http://localhost:3000/health

### 5. ใช้งาน

1. เปิดเบราว์เซอร์ไปที่ http://localhost:8080
2. พิมพ์ task ใน input box
3. คลิก "Add Task"
4. Task จะถูกบันทึกใน PostgreSQL

### 6. เข้าถึง Database

```bash
# เข้าไปใน PostgreSQL
docker-compose exec postgres psql -U postgres -d tododb

# ดู tables
\dt

# Query tasks
SELECT * FROM tasks;

# ออกจาก psql
\q
```

### 7. Development Mode

```bash
# รันด้วย development configuration
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### 8. Stop Application

```bash
# หยุด services
docker-compose stop

# หยุดและลบ containers
docker-compose down

# หยุด ลบ containers และ volumes
docker-compose down -v
```

## Services

### Frontend (Nginx)
- Port: 8080
- Serve static HTML
- Proxy API requests to backend

### Backend (Node.js + Express)
- Port: 3000 (ภายใน network)
- RESTful API
- เชื่อมต่อ PostgreSQL

### PostgreSQL
- ไม่เปิด port ภายนอก (security)
- Database: tododb
- User: postgres
- Password: secret123 (ควรใช้ secrets ใน production)

## API Endpoints

### GET /health
Health check endpoint

**Response:**
```json
{
  "status": "healthy"
}
```

### GET /api/tasks
ดึงรายการ tasks ทั้งหมด

**Response:**
```json
[
  {
    "id": 1,
    "title": "Task 1",
    "completed": false
  }
]
```

### POST /api/tasks
สร้าง task ใหม่

**Request Body:**
```json
{
  "title": "New task"
}
```

**Response:**
```json
{
  "id": 2,
  "title": "New task",
  "completed": false
}
```

## การปรับแต่ง

### เปลี่ยน Port

แก้ไขใน `docker-compose.yml`:
```yaml
services:
  frontend:
    ports:
      - "8080:80"  # เปลี่ยนเป็น port ที่ต้องการ
```

### เปลี่ยน Database Password

1. สร้างไฟล์ `.env`:
```env
POSTGRES_PASSWORD=your-secure-password
```

2. แก้ไข `docker-compose.yml`:
```yaml
postgres:
  environment:
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

backend:
  environment:
    - DB_PASSWORD=${POSTGRES_PASSWORD}
```

### เพิ่ม Redis Cache

เพิ่มใน `docker-compose.yml`:
```yaml
redis:
  image: redis:7-alpine
  networks:
    - backend
```

## Troubleshooting

### Database connection error
```bash
# ตรวจสอบว่า postgres ทำงานปกติ
docker-compose logs postgres

# Restart postgres
docker-compose restart postgres
```

### Port already in use
```bash
# หา process ที่ใช้ port
lsof -i :8080

# หรือเปลี่ยน port ใน docker-compose.yml
```

### Container ไม่ start
```bash
# ดู logs เพื่อหาสาเหตุ
docker-compose logs service-name

# Rebuild images
docker-compose build --no-cache
docker-compose up -d
```

## Best Practices

1. ✅ ใช้ `.env` file สำหรับ configuration
2. ✅ ไม่ commit secrets เข้า git
3. ✅ ใช้ health checks
4. ✅ แยก networks (frontend, backend)
5. ✅ ใช้ named volumes สำหรับ data
6. ✅ กำหนด resource limits

## การพัฒนาต่อ

- เพิ่ม authentication
- เพิ่ม unit tests
- ใช้ TypeScript
- เพิ่ม Redis caching
- ใช้ Nginx rate limiting
- Setup monitoring

---

**Happy Coding! 🐳**
