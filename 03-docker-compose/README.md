# 03. Docker Compose

## Docker Compose คืออะไร?

Docker Compose เป็นเครื่องมือสำหรับจัดการ Multi-container Docker Applications ให้เราสามารถกำหนดการตั้งค่าทั้งหมดในไฟล์ YAML เดียว และรันทุกอย่างด้วยคำสั่งเดียว

**ปัญหาเดิม:**
```bash
# รัน database
docker run -d --name postgres -e POSTGRES_PASSWORD=secret postgres

# รัน redis
docker run -d --name redis redis

# รัน app (ต้องรอ db พร้อม, ตั้ง env, link network)
docker run -d --name app --link postgres --link redis -e DB_HOST=postgres -p 3000:3000 myapp
```

**ใช้ Docker Compose:**
```bash
docker-compose up
```

## การติดตั้ง

Docker Desktop มี Docker Compose มาให้อยู่แล้ว สำหรับ Linux:

```bash
# ติดตั้ง Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# ตรวจสอบ
docker-compose --version
```

## docker-compose.yml พื้นฐาน

### โครงสร้างไฟล์
```yaml
version: '3.8'

services:
  # Service 1
  web:
    image: nginx:alpine
    ports:
      - "80:80"
  
  # Service 2
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - db
  
  # Service 3
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:

networks:
  default:
    driver: bridge
```

## คำสั่ง Docker Compose

### คำสั่งพื้นฐาน
```bash
# Start services
docker-compose up

# Start ในโหมด background
docker-compose up -d

# Build images ก่อน start
docker-compose up --build

# Stop services
docker-compose stop

# Stop และลบ containers
docker-compose down

# Stop และลบ containers + volumes
docker-compose down -v

# ดู services ที่กำลังรัน
docker-compose ps

# ดู logs
docker-compose logs
docker-compose logs -f
docker-compose logs -f web

# รันคำสั่งใน service
docker-compose exec web sh
docker-compose exec db psql -U postgres

# Build images
docker-compose build
docker-compose build --no-cache

# Pull images
docker-compose pull

# Restart services
docker-compose restart
docker-compose restart web
```

## การกำหนด Services

### 1. ใช้ Image สำเร็จรูป
```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
  
  redis:
    image: redis:7-alpine
```

### 2. Build จาก Dockerfile
```yaml
services:
  app:
    build: .
    # หรือ
    build:
      context: .
      dockerfile: Dockerfile
      args:
        NODE_VERSION: 18
```

### 3. Ports Mapping
```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"        # host:container
      - "443:443"
      - "127.0.0.1:3000:3000"  # bind to localhost only
```

### 4. Environment Variables
```yaml
services:
  app:
    image: myapp
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DB_HOST=postgres
    # หรือใช้ไฟล์
    env_file:
      - .env
```

### 5. Volumes
```yaml
services:
  app:
    image: myapp
    volumes:
      # Named volume
      - app-data:/app/data
      
      # Bind mount
      - ./src:/app/src
      - ./config:/app/config:ro  # read-only
      
      # Anonymous volume
      - /app/node_modules

volumes:
  app-data:
```

### 6. Networks
```yaml
services:
  web:
    image: nginx
    networks:
      - frontend
  
  app:
    image: myapp
    networks:
      - frontend
      - backend
  
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
  backend:
```

### 7. Dependencies
```yaml
services:
  app:
    image: myapp
    depends_on:
      - db
      - redis
  
  db:
    image: postgres
  
  redis:
    image: redis
```

### 8. Health Checks
```yaml
services:
  app:
    image: myapp
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

### 9. Restart Policies
```yaml
services:
  app:
    image: myapp
    restart: always  # no, always, on-failure, unless-stopped
```

### 10. Resource Limits
```yaml
services:
  app:
    image: myapp
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## 🎯 Workshop 3: Full-stack Application

### Mission: สร้าง Web App + API + Database

#### 1. โครงสร้างโปรเจค
```bash
mkdir fullstack-app
cd fullstack-app
mkdir backend frontend
```

#### 2. Backend (Node.js + Express)

**backend/package.json**
```json
{
  "name": "backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.0"
  }
}
```

**backend/server.js**
```javascript
const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'mydb',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'secret'
});

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Get all tasks
app.get('/api/tasks', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tasks ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Create task
app.post('/api/tasks', async (req, res) => {
  const { title } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO tasks (title, completed) VALUES ($1, false) RETURNING *',
      [title]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Initialize database
async function initDB() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        completed BOOLEAN DEFAULT false
      )
    `);
    console.log('Database initialized');
  } catch (err) {
    console.error('Database init error:', err);
  }
}

app.listen(port, async () => {
  console.log(`Server running on port ${port}`);
  await initDB();
});
```

**backend/Dockerfile**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY server.js ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "server.js"]
```

#### 3. Frontend (Simple HTML)

**frontend/index.html**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Todo App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
        }
        input, button {
            padding: 10px;
            margin: 5px;
        }
        #tasks {
            margin-top: 20px;
        }
        .task {
            padding: 10px;
            margin: 5px 0;
            background: #f0f0f0;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <h1>Todo App with Docker Compose</h1>
    
    <div>
        <input type="text" id="taskInput" placeholder="Enter task">
        <button onclick="addTask()">Add Task</button>
    </div>
    
    <div id="tasks"></div>

    <script>
        const API_URL = 'http://localhost:3000/api';

        async function loadTasks() {
            const response = await fetch(`${API_URL}/tasks`);
            const tasks = await response.json();
            
            const tasksDiv = document.getElementById('tasks');
            tasksDiv.innerHTML = tasks.map(task => `
                <div class="task">
                    ${task.id}. ${task.title}
                </div>
            `).join('');
        }

        async function addTask() {
            const input = document.getElementById('taskInput');
            const title = input.value.trim();
            
            if (!title) return;
            
            await fetch(`${API_URL}/tasks`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title })
            });
            
            input.value = '';
            loadTasks();
        }

        loadTasks();
    </script>
</body>
</html>
```

**frontend/nginx.conf**
```nginx
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://backend:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**frontend/Dockerfile**
```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

#### 4. Docker Compose Configuration

**docker-compose.yml**
```yaml
version: '3.8'

services:
  # Frontend
  frontend:
    build: ./frontend
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - app-network

  # Backend API
  backend:
    build: ./backend
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=tododb
      - DB_USER=postgres
      - DB_PASSWORD=secret123
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped

  # Database
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=tododb
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=secret123
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres-data:

networks:
  app-network:
    driver: bridge
```

**docker-compose.dev.yml** (สำหรับ development)
```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: node server.js

  postgres:
    ports:
      - "5432:5432"  # เปิด port ให้เข้าถึงได้จากภายนอก
```

#### 5. .dockerignore
```
node_modules
npm-debug.log
.git
.env
*.md
.DS_Store
```

#### 6. รันและทดสอบ

```bash
# Start all services
docker-compose up -d

# ดู logs
docker-compose logs -f

# ตรวจสอบ services
docker-compose ps

# เปิดเบราว์เซอร์ไปที่ http://localhost:8080

# ทดสอบ API โดยตรง
curl http://localhost:3000/api/tasks

# เข้าไปใน database
docker-compose exec postgres psql -U postgres -d tododb
# \dt
# SELECT * FROM tasks;
# \q

# หยุดและลบ
docker-compose down

# ลบพร้อม volumes
docker-compose down -v
```

#### 7. Development Mode
```bash
# รันด้วย dev configuration
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# หรือ
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## Best Practices

### 1. ใช้ .env File
```bash
# .env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secret123
POSTGRES_DB=tododb
NODE_ENV=production
```

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15
    env_file:
      - .env
```

### 2. Override สำหรับ Environments ต่างๆ
```yaml
# docker-compose.override.yml (auto load)
# docker-compose.dev.yml (manual load)
# docker-compose.prod.yml (manual load)
```

### 3. Health Checks
```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 4. Resource Limits
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
```

### 5. Logging
```yaml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ Docker Compose คืออะไรและทำไมต้องใช้
- ✅ โครงสร้างของ docker-compose.yml
- ✅ คำสั่ง Docker Compose พื้นฐาน
- ✅ การกำหนด Services, Networks, Volumes
- ✅ Environment Variables และ Configuration
- ✅ Health Checks และ Dependencies
- ✅ การสร้าง Full-stack Application
- ✅ Best Practices

## 🎓 แบบฝึกหัด

1. เพิ่ม Redis cache เข้าไปใน stack
2. เพิ่ม Nginx reverse proxy
3. สร้าง docker-compose สำหรับ WordPress + MySQL
4. เพิ่ม monitoring ด้วย Prometheus + Grafana

## ➡️ บทถัดไป

[04. Networking และ Volumes](../04-networking-volumes/README.md)

---

**Happy Docker! 🐳**
