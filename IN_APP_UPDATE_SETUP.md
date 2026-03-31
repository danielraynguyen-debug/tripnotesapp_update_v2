# 🚀 Trip Notes App - In-App Update Setup Guide

## Tổng quan
Hệ thống In-App Update tự động kiểm tra và cài đặt phiên bản mới từ GitHub Releases.

## 📋 Yêu cầu

- GitHub Repository (public hoặc private)
- Keystore cho Android signing
- GitHub Actions enabled

---

## 🔧 Bước 1: Cấu hình GitHub Repository

### 1.1. Sửa file `lib/services/update_service.dart`

Thay thế placeholder bằng thông tin repo của bạn:

```dart
static const String _owner = 'danielraynguyen-debug';  // <-- Sửa
static const String _repo = 'tripnotesapp_update';           // <-- Sửa nếu cần
```

### 1.2. Tạo GitHub Release đầu tiên

```bash
# Tag version đầu tiên
git tag -a v0.8.0 -m "Initial release"
git push origin v0.8.0
```

---

## 🔐 Bước 2: Tạo Android Keystore

### 2.1. Tạo keystore mới (nếu chưa có)

```bash
cd android/app

# Tạo keystore
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# Thông tin cần nhớ:
# - Keystore password: (nhập mật khẩu)
# - Key alias: release
# - Key password: (nhập mật khẩu)
```

### 2.2. Mã hóa keystore cho GitHub Actions

```bash
# Encode keystore thành base64
base64 -i release-key.jks -o keystore-base64.txt

# Hoặc trên Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release-key.jks")) | Set-Content keystore-base64.txt
```

---

## 🔑 Bước 3: Thêm GitHub Secrets

Vào **GitHub Repository** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Thêm các secrets sau:

| Secret Name | Value | Mô tả |
|------------|-------|-------|
| `KEYSTORE_BASE64` | Content của `keystore-base64.txt` | Keystore đã mã hóa base64 |
| `KEYSTORE_PASSWORD` | Mật khẩu keystore | Password bảo vệ file keystore |
| `KEY_ALIAS` | `release` | Tên alias trong keystore |
| `KEY_PASSWORD` | Mật khẩu key | Password của key alias |

---

## 🚀 Bước 4: Build và Release

### 4.1. Chạy GitHub Actions

Có 2 cách:

**Cách 1: Tự động (khuyên dùng)**
```bash
# Push tag mới sẽ tự động trigger build
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

**Cách 2: Manual trigger**
- Vào **Actions** tab trong GitHub repo
- Chọn workflow "Build and Release APK"
- Click **Run workflow**
- Nhập version tag (e.g., `v1.0.0`)
- Click **Run workflow**

### 4.2. Kiểm tra Release

- Vào **Releases** trong GitHub repo
- Xác nhận APK đã được upload

---

## 📱 Bước 5: Test In-App Update

### 5.1. Cài đặt app version cũ

```bash
# Build debug version để test
flutter build apk --debug

# Hoặc cài từ release cũ
```

### 5.2. Release version mới

```bash
# Cập nhật version trong pubspec.yaml
# Từ: version: 0.8.0+1
# Thành: version: 1.0.0+2

# Commit và push tag
git add pubspec.yaml
git commit -m "Bump version to 1.0.0"
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```

### 5.3. Kiểm tra update trong app

1. Mở app (version cũ)
2. Chờ 5 giây sau khi app khởi động
3. Kiểm tra logs: `flutter logs`
4. Nếu có version mới, hệ thống sẽ tự động download và cài đặt

---

## 🐛 Troubleshooting

### Lỗi "Repository not found"
```
Solution: Kiểm tra _owner và _repo trong update_service.dart
```

### Lỗi "API rate limit exceeded"
```
Solution: Chờ 1 giờ hoặc thêm GitHub Token (cho private repo)
```

### Lỗi signing trong GitHub Actions
```
Solution: Kiểm tra KEYSTORE_BASE64 đã đúng format chưa
          Đảm bảo không có ký tự xuống dòng trong secret
```

### App không tự động cài đặt
```
Solution: Kiểm tra đã thêm REQUEST_INSTALL_PACKAGES permission
          Kiểm tra APK signing có hợp lệ không
```

---

## 📁 Cấu trúc files đã tạo

```
tripnotesapp/
├── lib/
│   ├── services/
│   │   └── update_service.dart      # ✅ GitHub Update Service
│   └── main.dart                     # ✅ Tích hợp update check
├── android/
│   ├── app/
│   │   ├── build.gradle.kts         # ✅ Signing config
│   │   └── src/main/
│   │       └── AndroidManifest.xml  # ✅ Install permission
│   └── gradle.properties            # ✅ Kotlin config
├── .github/
│   └── workflows/
│       └── release.yml               # ✅ CI/CD workflow
└── IN_APP_UPDATE_SETUP.md           # ✅ File này
```

---

## 🔒 Security Notes

- **KE KHÔNG** commit keystore file vào git
- **KE KHÔNG** để lộ KEYSTORE_BASE64 trong code
- **CHỈ** sử dụng GitHub Secrets để lưu thông tin nhạy cảm
- **NÊN** đặt keystore file trong `.gitignore`

---

## 📝 Next Steps

1. ✅ Chạy `flutter pub get` để cài dependencies
2. ✅ Cấu hình GitHub Secrets
3. ✅ Push tag đầu tiên
4. ✅ Test In-App Update trên thiết bị thật

## 🆘 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs trong `flutter logs`
2. Xem GitHub Actions logs trong Actions tab
3. Kiểm tra file `update_service.dart` đã đúng owner/repo chưa

---

## 📚 Tham khảo

- [in_app_update_me package](https://pub.dev/packages/in_app_update_me)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Release Documentation](https://docs.flutter.dev/deployment/android)
