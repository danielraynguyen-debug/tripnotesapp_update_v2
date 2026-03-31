# In-App Update với Google Drive

Hướng dẫn cài đặt tính năng tự động cập nhật ứng dụng qua Google Drive.

## 🎯 Tổng quan

Thay vì dùng GitHub Releases, bạn có thể host APK trên Google Drive và tự động cập nhật.

**Ưu điểm:**
- Không cần GitHub Actions build (tránh lỗi dependency)
- Build local và upload thủ công
- Hoạt động tốt ở Việt Nam

**Nhược điểm:**
- Phải upload APK thủ công mỗi lần release
- Cần Google Service Account

---

## 📋 Bước 1: Tạo Google Service Account

1. Vào [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Vào **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
   - Name: `tripnotesapp-uploader`
   - Role: **Storage Admin** hoặc **Storage Object Admin**
5. Click vào service account vừa tạo → **Keys** tab
6. **Add Key** → **Create new key** → chọn **JSON**
7. File JSON sẽ tự động download → Đặt tên `credentials.json` vào thư mục `tools/`

---

## 📦 Bước 2: Enable Google Drive API

1. Trong Google Cloud Console, vào **APIs & Services** → **Library**
2. Tìm "Google Drive API" và click **Enable**
3. Đảm bảo Service Account có quyền truy cập Drive

---

## 🔧 Bước 3: Cài đặt Python Dependencies

```bash
cd tools
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

---

## 🚀 Bước 4: Build và Upload

### Cách 1: Dùng Script tự động

```bash
# Build APK và upload lên Drive
python tools/drive_upload.py --version 1.0.0 --notes "Release notes here"
```

Script sẽ:
1. Build APK release
2. Upload lên Google Drive
3. Tạo file `version.json`
4. Upload `version.json`
5. In ra các URL cần dùng

### Cách 2: Manual Upload

1. Build APK:
   ```bash
   flutter build apk --release
   ```

2. Vào [Google Drive](https://drive.google.com)

3. Upload `build/app/outputs/flutter-apk/app-release.apk`

4. Right-click file → **Share** → **Change to Anyone with the link**

5. Copy File ID từ URL:
   ```
   https://drive.google.com/file/d/FILE_ID/view
   ```

6. Tạo `version.json`:
   ```json
   {
     "version": "1.0.0",
     "apk_url": "https://drive.google.com/uc?export=download&id=FILE_ID",
     "release_notes": "Mô tả bản cập nhật",
     "force_update": false
   }
   ```

7. Upload `version.json` lên Drive và lấy URL

---

## ⚙️ Bước 5: Cập nhật URL trong App

Mở `lib/services/drive_update_service.dart` và sửa:

```dart
static const String versionJsonUrl = 
    'https://drive.google.com/uc?export=download&id=YOUR_VERSION_JSON_ID';
```

Thay `YOUR_VERSION_JSON_ID` bằng File ID của `version.json` trên Drive.

---

## 📱 Bước 6: Test trên thiết bị

1. Cài đặt app phiên bản cũ:
   ```bash
   flutter install
   ```

2. Thay đổi version trong `pubspec.yaml` (ví dụ: 0.9.0 → 1.0.0)

3. Build APK mới và upload lên Drive

4. Cập nhật `version.json` trên Drive

5. Mở app cũ → Chờ 5 giây → Dialog cập nhật sẽ hiện

6. Click "Cập nhật ngay" → Tải và cài đặt APK mới

---

## 🔄 Workflow cập nhật

Mỗi lần release mới:

```bash
# 1. Cập nhật version trong pubspec.yaml
version: 1.0.1+2

# 2. Build
flutter build apk --release

# 3. Upload (tự động)
python tools/drive_upload.py --version 1.0.1 --notes "Sửa lỗi XYZ"

# 4. Copy URL từ output và cập nhật trong drive_update_service.dart (nếu version.json URL thay đổi)
```

---

## 🔗 Quan trọng: File ID vs Direct Link

**File ID:** Chuỗi ký tự trong URL Drive
```
https://drive.google.com/file/d/1AbCdEfGhIjKlMnOpQrStUvWxYz/view
                         ^^^^^^^^^^^^^^^^^^^^^^^^
                              File ID
```

**Direct Download URL:**
```
https://drive.google.com/uc?export=download&id=1AbCdEfGhIjKlMnOpQrStUvWxYz
```

**Lưu ý:**
- File phải được Share với "Anyone with the link"
- Nếu file bị xóa/tạo lại, File ID sẽ thay đổi → Phải cập nhật code

---

## 🐛 Troubleshooting

### Lỗi: "API not enabled"
```
Google Drive API chưa được enable trong Google Cloud Console
```
→ Vào API Library và enable Google Drive API

### Lỗi: "Insufficient permissions"
```
Service Account không có quyền upload
```
→ Thêm quyền **Storage Admin** hoặc share folder Drive với service account

### Lỗi: Download failed trên app
```
File chưa được share public
```
→ Right-click file → Share → Anyone with the link

### Lỗi: "The current Dart SDK version is X"
```
Version package không tương thích
```
→ Hạ version package trong `pubspec.yaml` để tương thích Dart SDK của GitHub Actions (nếu dùng), hoặc build local thì không vấn đề

---

## 📁 Cấu trúc Files

```
lib/
  services/
    drive_update_service.dart    # Service check & download update
tools/
  drive_upload.py              # Script upload lên Drive
  version.json                 # Template version.json
  credentials.json             # Google Service Account (không commit!)
```

---

## ✅ Checklist trước khi release

- [ ] Cập nhật version trong `pubspec.yaml`
- [ ] Test build local: `flutter build apk --release`
- [ ] Upload APK lên Google Drive
- [ ] Tạo/cập nhật `version.json` trên Drive
- [ ] Cập nhật `versionJsonUrl` trong `drive_update_service.dart` (nếu cần)
- [ ] Test trên thiết bị thật
- [ ] Commit và push code (không cần tag với Google Drive)

---

## 📞 Cần hỗ trợ?

- Xem log trong app: `adb logcat | grep DriveUpdate`
- Kiểm tra URL có truy cập được không: Mở trong browser
- Test download URL: `curl -I "https://drive.google.com/uc?export=download&id=FILE_ID"`
