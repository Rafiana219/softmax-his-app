# Softmax HIS – build iOS บน cloud แล้วเปิดบน iPhone/iPad จำลอง

ไม่ต้องมี Mac และไม่ต้องมี Apple Developer account

```
GitHub (เก็บ code) → Codemagic (Mac บน cloud build app) → Appetize.io (iPhone/iPad จำลองในเบราว์เซอร์) → ส่ง link ทาง LINE
```

ผลที่ได้: link ที่เปิดบน iPad, iPhone หรือคอมก็ได้ ข้างในเป็น **iOS Simulator จริง** ที่รัน app Flutter ตัวเดียวกับ Android
(เห็นไอคอน, หน้า splash, login และใช้งาน HIS ได้) แต่ไม่ได้ติดตั้งลงเครื่องจริง ถ้าจะลงเครื่องจริงดู "ขั้นต่อไป" ท้ายไฟล์

ไฟล์ตั้งค่าคือ `codemagic.yaml` ในโฟลเดอร์นี้ (มีให้แล้ว ไม่ต้องแก้)

---

## 1. เอา code ขึ้น GitHub

1. เข้า https://github.com/new
   - Repository name: `softmax-his-app`
   - เลือก **Private**
   - ไม่ต้องติ๊ก README / .gitignore (โปรเจกต์มีแล้ว)
   - กด **Create repository**
2. เปิด PowerShell **ในโฟลเดอร์โปรเจกต์นี้** (โฟลเดอร์ที่มี `pubspec.yaml`) แล้วรันทีละบรรทัด
   (เปลี่ยน `<GITHUB-USER>` เป็นชื่อ account หรือ organization ของคุณ)

```powershell
git init -b main
```

```powershell
git add .
```

```powershell
git commit -m "Softmax HIS app"
```

```powershell
git remote add origin https://github.com/<GITHUB-USER>/softmax-his-app.git
```

```powershell
git push -u origin main
```

> ต้องรัน `git init` ในโฟลเดอร์โปรเจกต์เท่านั้น ห้ามรันที่ `C:\Users\ASUS`
> ไฟล์ APK, `build/` และ `.dart_tool/` ไม่ขึ้น GitHub (ตั้งไว้ใน `.gitignore` แล้ว)

## 2. Build บน Codemagic

1. เข้า https://codemagic.io → **Sign up with GitHub** แล้วอนุญาตให้เห็น repo `softmax-his-app`
2. **Add application** → เลือก GitHub → เลือก `softmax-his-app` → ประเภท **Flutter App**
3. Codemagic จะเจอ `codemagic.yaml` เอง
4. กด **Start new build** → branch `main` → workflow **iOS Simulator (Appetize, manual upload)** (`ios-simulator`)
5. รอประมาณ 10–20 นาที
6. build เสร็จ ไปที่ **Artifacts** → ดาวน์โหลด `SoftmaxHIS-ios-simulator.zip`

> workflow `android-apk` ใช้ build APK บน cloud ได้ด้วย ได้ไฟล์แบบเดียวกับที่ build บน Windows

## 3. เปิดบน Appetize.io

1. เข้า https://appetize.io → สมัคร (ใช้ GitHub หรือ email ก็ได้)
2. **Upload** → เลือกไฟล์ `SoftmaxHIS-ios-simulator.zip` → Platform **iOS**
3. ได้หน้า app พร้อม link ในตั้งค่า (Settings) ของ app ให้เลือก:
   - Device: **iPad** หรือ **iPhone** รุ่นที่ลูกค้าใช้
   - เปิดการเข้าถึงให้คนที่มี link เปิดได้ (Public / Anyone with the link)
4. Copy link ส่งทาง LINE ลูกค้ากดแล้วกด **Tap to play** เพื่อเริ่ม

## 4. (ไม่บังคับ) ให้ Codemagic upload ขึ้น Appetize เอง

ไม่ต้องดาวน์โหลดและ upload เองทุกครั้ง และ link เดิมจะได้ app ตัวใหม่อัตโนมัติ

1. Appetize → Account → **API Token** → สร้าง token แล้ว copy
2. Codemagic → app นี้ → **Environment variables**
   - Variable name: `APPETIZE_API_TOKEN`  ค่า: token ที่ copy มา  ติ๊ก **Secure**
   - Group: `appetize`
3. หลัง upload ครั้งแรก เอา **public key** ของ app ใน Appetize (ตัวอักษรท้าย link) มาเพิ่มเป็น
   `APPETIZE_PUBLIC_KEY` ใน group `appetize` (ถ้าไม่ใส่ จะได้ link ใหม่ทุกครั้งที่ build)
4. Build ด้วย workflow **iOS Simulator -> Appetize.io** (`ios-simulator-appetize`)
   link จะอยู่ใน log ขั้น "Upload to Appetize.io" และในไฟล์ `appetize.json`

## ค่าใช้จ่าย

- Codemagic และ Appetize มีโควตาใช้ฟรีรายเดือน (เวลา build / เวลาเปิดใช้งาน) ดูตัวเลขล่าสุดในหน้า Pricing ของแต่ละเจ้า
- ถ้าโชว์ลูกค้าบ่อยหรือหลายคน โควตาของ Appetize อาจไม่พอ ต้องอัปเกรด

## ถ้า build ไม่ผ่าน

- ดู log ขั้นที่ขึ้นสีแดงใน Codemagic
- **Run tests แดง:** มี test ไม่ผ่าน รัน `flutter test` บนเครื่องดูก่อน
- **Build iOS Simulator app แดงช่วง `pod install`:** กด build ใหม่อีกครั้ง (บางครั้ง CocoaPods โหลดไม่สำเร็จ)
- ถ้ายังไม่ผ่าน ส่ง log มาดูได้

## ข้อจำกัดของ Simulator

- เป็น build แบบ debug ทำงานช้ากว่าเครื่องจริงเล็กน้อย
- ไม่มีกล้อง, Face ID และ push notification
- ใช้โชว์หน้าตาและทดสอบการใช้งานได้ แต่ก่อนส่งงานจริงควรทดสอบบนเครื่องจริงผ่าน TestFlight

## ขั้นต่อไป: ลงเครื่องจริงผ่าน TestFlight

เมื่อมี Apple Developer Program ($99/ปี):
1. สร้าง App Store Connect API key แล้วเพิ่มใน Codemagic → Team settings → Integrations
2. ใน `codemagic.yaml` เอา `#` หน้า workflow `ios-testflight` ออก แล้วใส่ชื่อ key ให้ตรง
3. build workflow นั้น → app ขึ้น TestFlight → ส่ง link เชิญทาง LINE ให้ลูกค้าลงใน iPad/iPhone ได้
