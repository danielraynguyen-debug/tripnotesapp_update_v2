# Hướng dẫn Setup Firebase Phone Auth cho Flutter

## 1. Khởi tạo Project
- Truy cập [Firebase Console](https://console.firebase.google.com).
- Tạo dự án mới và bật **Authentication** > **Sign-in method** > **Phone**.

## 2. Cấu hình Android
- **SHA Fingerprints:** Chạy lệnh `./gradlew signingReport` trong thư mục `android/`. 
- Copy mã **SHA-1** và **SHA-256** dán vào Project Settings trên Firebase.
- Tải `google-services.json` bỏ vào `android/app/`.

## 3. Cấu hình iOS
- **APNs:** Vào Apple Developer Portal, tạo **Auth Key (tệp .p8)** và tải lên Firebase (Project Settings > Cloud Messaging).
- **Capabilities:** Mở Xcode, bật **Push Notifications** và **Background Modes** (chọn *Remote notifications*).
- **URL Schemes:** Copy `REVERSED_CLIENT_ID` từ `GoogleService-Info.plist` dán vào *Info > URL Types*.

## 4. Flutterfire CLI (Khuyên dùng)
Chạy lệnh sau để tự động cấu hình:
```bash
flutterfire configure
```
