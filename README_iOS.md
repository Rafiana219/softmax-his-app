# Softmax HIS – คู่มือ build iOS

App Flutter ที่เปิดเว็บ HIS (`https://his.softmax-one.com/user/login`) แบบเต็มจอผ่าน WebView
code ชุดเดียวกับ Android ที่ build เป็น APK แล้ว (เวอร์ชัน 1.0.0) และใช้โครงเดียวกับ app Softmax ERP **ยังไม่เคย build หรือทดสอบบน iOS**

## สิ่งที่ต้องมี

- Mac + **Xcode 16** ขึ้นไป (มี iOS Simulator)
- **Flutter 3.38.x** (ตัวที่ใช้ build Android คือ 3.38.4, Dart 3.10.3)
- **CocoaPods** (`sudo gem install cocoapods` หรือ `brew install cocoapods`)
- Apple ID สำหรับลงเครื่องจริง และ **Apple Developer Program** ($99/ปี) ถ้าจะส่งผ่าน TestFlight / App Store

## ขั้นตอน

```bash
cd browser_app
flutter pub get
cd ios && pod install && cd ..

# ลองบน Simulator
open -a Simulator
flutter run

# ลงเครื่องจริง (ต่อ iPhone ด้วยสาย แล้วกด Trust บนมือถือ)
flutter run --release
```

ก่อนลงเครื่องจริงครั้งแรก:
1. เปิด `ios/Runner.xcworkspace` ใน Xcode (ไม่ใช่ `.xcodeproj`)
2. Runner → แท็บ **Signing & Capabilities** → เลือก **Team**
3. ถ้า bundle ID `com.softmax.his` ชนกับของคนอื่น ให้เปลี่ยนเป็น ID ของทีม
4. บน iPhone: Settings → General → VPN & Device Management → Trust developer
   (ถ้าใช้ Apple ID ฟรี app จะใช้ได้ 7 วัน)

ส่งให้ลูกค้าลงเอง (TestFlight):

```bash
flutter build ipa --release
# แล้วอัปโหลด build/ios/ipa/*.ipa ด้วยแอป Transporter หรือ Xcode Organizer
```

## ตั้งค่าที่ทำไว้แล้ว

| อย่าง | ค่า | อยู่ที่ |
|---|---|---|
| ชื่อบนหน้าจอ | Softmax HIS | `ios/Runner/Info.plist` (CFBundleDisplayName) |
| Bundle ID | `com.softmax.his` | `ios/Runner.xcodeproj/project.pbxproj` |
| iOS ขั้นต่ำ | 13.0 | `project.pbxproj` |
| ไอคอน | สร้างไว้แล้ว (ไล่สีฟ้า-เขียวอมฟ้า + ตราสถาบันฯ) | `ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| เวอร์ชัน | 1.0.0 (build 1) | `pubspec.yaml` → `version:` |

## ไฟล์ที่ควรรู้

- `lib/config.dart` – URL ของ HIS, ชื่อระบบ (`systemLabel`), โดเมนที่เปิดใน app, ชื่อสถาบัน, สีของแบรนด์, สวิตช์ `showDebugLog`
- `lib/erp_page.dart` – หน้าจอหลัก (WebView), หน้า error, แผง log
- `lib/splash.dart` – หน้าเปิด app (โลโก้ในวงกลมขอบทอง + ชื่อสถาบัน)
- `lib/app_log.dart` – log บนหน้าจอ
- `tool/make_logo.dart` – สร้างรูปไอคอน/โลโก้จาก `assets/branding/logo_original.jpg`
  ถ้าเปลี่ยนโลโก้: `dart run tool/make_logo.dart` แล้ว `dart run flutter_launcher_icons`

## พฤติกรรมบน iOS ที่ต่างจาก Android

- **ย้อนกลับ:** iPhone ไม่มีปุ่ม Back ใช้ปัดจากขอบซ้ายของจอเพื่อย้อนหน้า (เปิดไว้แล้ว)
- **ปุ่ม "เปิดด้วย Chrome":** บน iOS จะเปิดเป็น Safari (SFSafariViewController) แทน
- **ลิงก์นอกโดเมน `softmax-one.com`** (LINE, โทร, อีเมล) เปิดด้วยแอปของเครื่อง
- **ดาวน์โหลดไฟล์/รายงาน:** ส่งไปเปิดใน Safari ควรทดสอบว่าโหลด PDF/Excel จาก HIS ได้
- **Log บนหน้าจอ:** ปิดอยู่ (`showDebugLog = false`) ถ้าจะ debug ให้เปลี่ยนเป็น `true`

## ควรทดสอบ

1. เปิด app → splash → หน้า login ขึ้น
2. Login แล้วใช้งานหน้าหลัก ๆ ได้
3. ปัดขอบซ้ายเพื่อย้อนกลับ
4. ลากจอลงเพื่อ refresh
5. ปิดเน็ต → ขึ้นหน้า "เปิดหน้า HIS ไม่ได้" → เปิดเน็ต → กด "ลองใหม่"
6. ดาวน์โหลดรายงาน / กดลิงก์โทรศัพท์

## หมายเหตุ

- โฟลเดอร์ `android/` ใช้ Gradle 9.2.1 + Android Gradle Plugin 8.13.1 (เพราะเครื่องที่ build ใช้ Java 25) ไม่เกี่ยวกับ iOS
- ไม่มีโฟลเดอร์ `windows/` (ถอดออกตอน build Android) ถ้าต้องการ: `flutter create --platforms windows .`
