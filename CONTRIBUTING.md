# การมีส่วนร่วมในโปรเจค (Contributing)

ขอบคุณที่สนใจมีส่วนร่วมในการพัฒนา Docker Tutorial นี้! 🙏

## วิธีการมีส่วนร่วม

### 1. รายงานข้อผิดพลาด (Bug Reports)

หากพบข้อผิดพลาดในเนื้อหา โค้ด หรือตัวอย่าง กรุณาเปิด Issue โดยระบุ:
- หัวข้อที่พบปัญหา
- คำอธิบายปัญหาอย่างละเอียด
- ขั้นตอนการทำซ้ำ (ถ้ามี)
- Environment (OS, Docker version, etc.)
- Screenshot หรือ error log (ถ้ามี)

### 2. แนะนำการปรับปรุง (Feature Requests)

มีไอเดียดีๆ? เปิด Issue เพื่อแชร์:
- หัวข้อที่อยากเพิ่ม
- เหตุผลที่คิดว่าน่าจะมีประโยชน์
- ตัวอย่างหรือ use case

### 3. ปรับปรุงเนื้อหา (Content Improvements)

#### ขั้นตอนการส่ง Pull Request:

1. **Fork Repository**
   ```bash
   # คลิกปุ่ม Fork บน GitHub
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/docker-tutorial.git
   cd docker-tutorial
   ```

3. **สร้าง Branch ใหม่**
   ```bash
   git checkout -b feature/improve-section-name
   # หรือ
   git checkout -b fix/correct-typo-section-name
   ```

4. **แก้ไขและทดสอบ**
   - แก้ไขเนื้อหาหรือโค้ด
   - ทดสอบ commands และตัวอย่าง
   - ตรวจสอบ markdown formatting

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "✨ เพิ่มตัวอย่าง X ในหัวข้อ Y"
   # หรือ
   git commit -m "🐛 แก้ไขข้อผิดพลาดใน section Z"
   ```

6. **Push Changes**
   ```bash
   git push origin feature/improve-section-name
   ```

7. **เปิด Pull Request**
   - ไปที่ GitHub repository
   - คลิก "Compare & pull request"
   - อธิบายการเปลี่ยนแปลง
   - รอ review

## แนวทางการเขียน

### เนื้อหา
- ✅ ใช้ภาษาไทยที่เข้าใจง่าย
- ✅ ให้ตัวอย่างที่ชัดเจน
- ✅ อธิบายทั้ง "อะไร" และ "ทำไม"
- ✅ ใส่ Workshop ที่ทำตามได้จริง
- ✅ เพิ่ม Tips และ Best Practices

### โค้ด
- ✅ ทดสอบโค้ดทุกตัวอย่างให้รันได้
- ✅ ใส่ comments อธิบายส่วนสำคัญ
- ✅ ใช้ best practices
- ✅ ตั้งค่า security อย่างเหมาะสม

### Markdown
- ✅ ใช้ heading hierarchy ที่ถูกต้อง
- ✅ Format code blocks ด้วย syntax highlighting
- ✅ ใส่ emoji เพื่อความชัดเจน (✅ ❌ ⚠️ 🎯 📝)
- ✅ ใส่ลิงก์ไปยังหัวข้ออื่นๆ ที่เกี่ยวข้อง

## Commit Message Convention

ใช้ emoji และข้อความที่ชัดเจน:

- ✨ `:sparkles:` - เพิ่ม feature ใหม่
- 🐛 `:bug:` - แก้ไข bug
- 📝 `:memo:` - อัพเดท documentation
- 🎨 `:art:` - ปรับปรุง format หรือโครงสร้าง
- ⚡ `:zap:` - ปรับปรุง performance
- 🔒 `:lock:` - แก้ไข security issue
- ➕ `:heavy_plus_sign:` - เพิ่ม dependency
- ➖ `:heavy_minus_sign:` - ลบ dependency
- 🚀 `:rocket:` - Deploy หรือ release

ตัวอย่าง:
```bash
git commit -m "✨ เพิ่มตัวอย่าง Docker Compose สำหรับ Redis"
git commit -m "🐛 แก้ไข command ใน section Networking"
git commit -m "📝 อัพเดท README ให้ชัดเจนขึ้น"
```

## ประเภทของการมีส่วนร่วม

### 📚 เนื้อหา (Content)
- เพิ่มหัวข้อใหม่
- ปรับปรุงคำอธิบาย
- แปลศัพท์เทคนิค
- เพิ่ม Workshop

### 💻 โค้ด (Code)
- เพิ่มตัวอย่างใหม่
- ปรับปรุง Dockerfile
- เพิ่ม docker-compose examples
- แก้ไข bugs

### 🎨 Design
- ปรับปรุง markdown formatting
- เพิ่ม diagrams
- ปรับปรุงโครงสร้าง

### 🧪 Testing
- ทดสอบ commands
- Verify examples
- รายงาน issues

## คำถามหรือต้องการความช่วยเหลือ?

- เปิด Issue เพื่อถามคำถาม
- ติดต่อผ่าน GitHub Discussions
- ส่ง email ถึง maintainer

## Code of Conduct

- เคารพผู้อื่น
- ให้ feedback ที่สร้างสรรค์
- ยอมรับความคิดเห็นที่แตกต่าง
- มุ่งเน้นการเรียนรู้ร่วมกัน

---

**ขอบคุณที่ช่วยทำให้ Docker Tutorial นี้ดีขึ้น! 🚀**
