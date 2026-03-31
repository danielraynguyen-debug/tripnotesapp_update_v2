# Force Update (Bắt Buộc Cập Nhật) - Hướng Dẫn Thiết Lập

Tài liệu này hướng dẫn cách thiết lập và sử dụng tính năng Force Update cho ứng dụng Trip Notes.

## 📁 Cấu Trúc File

```
lib/
├── core/services/
│   └── update_service.dart      # Service kiểm tra và xử lý cập nhật
├── presentation/screens/
│   └── splash_screen.dart        # Màn hình splash có kiểm tra update
├── main.dart                     # Đã cập nhật để sử dụng SplashScreen
└── ...
version.json                      # File cấu hình trên Google Drive
```

## 🚀 Hướng Dẫn Thiết Lập

### Bước 1: Chuẩn Bị File version.json trên Google Drive

1. **Tạo file version.json** với nội dung mẫu:

```json
{
  "latest_version": "1.1.0",
  "build_number": 493028,
  "force_update": true,
  "update_url": "https://drive.google.com/file/d/YOUR_FILE_ID/view?usp=sharing",
  "release_notes": "🚀 Cập nhật tính năng Kết nối tiện chuyến\n✨ Giao diện Indigo mới hiện đại\n🔧 Tối ưu hiệu suất ứng dụng"
}
```

2. **Upload lên Google Drive**:
   - Upload file `version.json` lên Google Drive
   - Đặt quyền truy cập "Anyone with the link can view"
   - Copy File ID từ link share (dạng: `https://drive.google.com/file/d/FILE_ID/view`)

3. **Cập nhật URL trong code**:
   - Mở file `lib/core/services/update_service.dart`
   - Thay `YOUR_FILE_ID` bằng File ID thực tế:

```dart
static const String versionUrl = 'https://drive.google.com/uc?export=download&id=YOUR_FILE_ID';
```

### Bước 2: Chuẩn Bị File APK trên Google Drive

1. Build APK release:
```bash
flutter build apk --release
```

2. Upload file APK lên Google Drive
3. Đặt quyền truy cập "Anyone with the link can view"
4. Copy link và cập nhật vào `version.json` trong trường `update_url`

### Bước 3: Cập Nhật Build Number

Trong file `pubspec.yaml`, cập nhật build number (số sau dấu +):

```yaml
version: 1.0.0+1        # version_name + build_number
#                    ↑ Đây là build_number
```

**Lưu ý**: `build_number` trong `version.json` phải **lớn hơn** build number hiện tại của app để trigger force update.

## ⚙️ Cách Hoạt Động

### 1. Luồng Kiểm Tra Cập Nhật

```
[Mở App] → [Splash Screen] → [Gọi UpdateService.checkForUpdate()]
                                      ↓
                              [Fetch version.json]
                                      ↓
                    [So sánh build_number]
                                      ↓
           ┌──────────┴──────────┐
           ↓                     ↓
    [Có update]             [Không có update]
           ↓                     ↓
    [Show Force Update      [Tiếp tục vào app]
     Dialog]
           ↓
    [Chặn user tới khi      
     nhấn Cập Nhật]
```

### 2. Cấu Hình Force Update

Trong file `version.json`:

| Field | Mô tả | Ví dụ |
|-------|-------|-------|
| `latest_version` | Phiên bản hiển thị | "1.1.0" |
| `build_number` | Số build (int) | 493028 |
| `force_update` | Bắt buộc cập nhật | true/false |
| `update_url` | Link tải APK | Google Drive link |
| `release_notes` | Nội dung cập nhật | Có thể xuống dòng bằng `\n` |

### 3. Tắt Force Update (Khẩn Cấp)

Nếu cần tắt force update ngay lập tức, chỉ cần đổi `force_update` thành `false`:

```json
{
  "latest_version": "1.1.0",
  "build_number": 493028,
  "force_update": false,
  "update_url": "...",
  "release_notes": "..."
}
```

## 🎨 Giao Diện Force Update Dialog

### Tính Năng UI:
- ✅ **Không cho đóng** bằng cách chạm ngoài (`barrierDismissible: false`)
- ✅ **Chặn nút Back** của Android (`WillPopScope`)
- ✅ **Indigo Gradient** cho nút Cập Nhật
- ✅ **Icon app** với shadow hiện đại
- ✅ **Release notes** có icon check xanh
- ✅ **Nút Cập Nhật Ngay** to, dễ bấm (one-handed)

### Màu Sắc:
| Element | Màu | Mã màu |
|---------|-----|--------|
| Primary Indigo | Tím đậm | `#4F46E5` |
| Indigo Light | Tím nhạt | `#6366F1` |
| Background | Trắng | `#FFFFFF` |
| Text Primary | Xanh đen | `#1E293B` |
| Text Secondary | Xám | `#64748B` |
| Success Green | Xanh lá | `#10B981` |

## 🧪 Test Force Update

### Cách 1: Test Local (Trước khi deploy)

1. Tạo file `version.json` test với build number cao hơn app:
```json
{
  "latest_version": "99.99.99",
  "build_number": 999999,
  "force_update": true,
  "update_url": "https://example.com/test",
  "release_notes": "Test update"
}
```

2. Host file tạm (có thể dùng [ngrok](https://ngrok.com/) hoặc [jsonbin.io](https://jsonbin.io/))
3. Đổi URL trong `update_service.dart` tạm thời
4. Chạy app và kiểm tra dialog hiển thị

### Cách 2: Test với Google Drive Thật

1. Build APK với build number thấp (ví dụ: `+1`)
2. Cài APK lên device
3. Cập nhật `version.json` trên Drive với build number cao hơn (ví dụ: `999`)
4. Mở app → Kiểm tra dialog xuất hiện

## 🔧 Xử Lý Lỗi Thường Gặp

### 1. Dialog không hiển thị
- ✅ Kiểm tra URL `version.json` có đúng không
- ✅ Kiểm tra `build_number` trong JSON có > build number app
- ✅ Kiểm tra `force_update` = `true`
- ✅ Xem log console để debug

### 2. Không mở được link APK
- ✅ Link phải là direct link hoặc view link của Google Drive
- ✅ File APK phải để public access
- ✅ Kiểm tra `url_launcher` đã config đúng trong AndroidManifest.xml

### 3. CORS error (nếu host trên web server)
- ✅ Google Drive không có vấn đề CORS
- ✅ Nếu dùng server khác, cần enable CORS cho domain

## 📋 Checklist Trước Khi Release

- [ ] Đã cập nhật `version` trong `pubspec.yaml`
- [ ] Đã build APK release (`flutter build apk --release`)
- [ ] Đã upload APK lên Google Drive và để public
- [ ] Đã cập nhật `update_url` trong `version.json`
- [ ] Đã cập nhật `build_number` trong `version.json` (lớn hơn app cũ)
- [ ] Đã cập nhật `release_notes` mô tả thay đổi
- [ ] Đã để `force_update` = `true` nếu muốn bắt buộc
- [ ] Đã upload `version.json` lên Google Drive
- [ ] Đã cập nhật File ID trong `update_service.dart`
- [ ] Đã test trên device thật

## 📚 Dependencies Thêm Vào

```yaml
dependencies:
  package_info_plus: ^9.0.0    # Lấy version app
  http: ^1.2.0                  # Gọi API version.json
  url_launcher: ^6.3.1          # Mở link download (đã có sẵn)
```

## 🔗 Resources

- [Package Info Plus](https://pub.dev/packages/package_info_plus)
- [HTTP Package](https://pub.dev/packages/http)
- [URL Launcher](https://pub.dev/packages/url_launcher)
- [Google Drive Direct Link Generator](https://sites.google.com/site/gdocs2direct/)

---

**Lưu ý quan trọng**: File `version.json` trên Google Drive có thể bị cache. Nếu cập nhật không thấy thay đổi, thêm `?nocache=1` vào cuối URL hoặc đợi 1-2 phút.
