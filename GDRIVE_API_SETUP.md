# Hướng Dẫn Thiết Lập Google Drive API

## Tổng Quan

Để sử dụng script `build_and_upload.py`, bạn cần thiết lập Google Drive API và tạo credentials. Hướng dẫn này sẽ hướng dẫn từng bước.

## Bước 1: Tạo Project trên Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Đăng nhập bằng tài khoản Google của bạn
3. Click vào **Select a project** (ở góc trên bên trái)
4. Click **New Project**
5. Đặt tên project: `TripNotes Build System`
6. Click **Create**

## Bước 2: Enable Google Drive API

1. Ở menu bên trái, click vào **APIs & Services** > **Library**
2. Tìm kiếm "Google Drive API"
3. Click vào **Google Drive API**
4. Click **Enable**

## Bước 3: Tạo OAuth2 Credentials

1. Ở menu bên trái, click **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Bạn sẽ thấy thông báo cần "Configure consent screen" - click **Configure consent screen**
4. Chọn **External** > Click **Create**
5. Điền thông tin:
   - **App name**: `TripNotes Build`
   - **User support email**: Email của bạn
   - **Developer contact information**: Email của bạn
6. Click **Save and Continue** (3 lần cho đến khi hoàn tất)
7. Quay lại **Credentials** > **Create Credentials** > **OAuth client ID**
8. Chọn **Application type**: `Desktop app`
9. Đặt tên: `TripNotes Desktop Client`
10. Click **Create**
11. Click **Download JSON**
12. Đổi tên file thành `credentials.json`
13. Di chuyển file vào thư mục gốc của project Flutter (cùng cấp với `build_and_upload.py`)

## Bước 4: Cài Đặt Python Dependencies

Mở terminal và chạy:

```bash
# Đảm bảo bạn đang ở thư mục project
cd E:/ANDROID_APP_PROJECTS/tripnotesapp_windsurf

# Cài đặt dependencies
pip install -r requirements.txt
```

## Bước 5: Chạy Script Lần Đầu

Khi chạy script lần đầu, nó sẽ yêu cầu xác thực OAuth2:

```bash
python build_and_upload.py --version 1.1.0 --build-number 2 --force-update
```

Bạn sẽ thấy:
1. Browser tự động mở
2. Chọn tài khoản Google của bạn
3. Click **Continue** để cấp quyền
4. Copy mã xác thực và dán vào terminal

Sau lần đầu, script sẽ lưu token và không cần xác thực lại nữa.

## Cấu Trúc File Sau Khi Thiết Lập

```
tripnotesapp_windsurf/
├── build_and_upload.py       # Script chính
├── credentials.json          # OAuth2 credentials (TẠO Ở BƯỚC 3)
├── token.json               # Access token (tự động tạo sau lần đầu chạy)
├── requirements.txt         # Python dependencies
├── version.json             # Template file
└── lib/
    └── core/
        └── services/
            └── update_service.dart   # Sẽ được cập nhật tự động
```

## Lưu Ý Quan Trọng

### 🔒 Bảo Mật
- **KHÔNG** commit `credentials.json` vào git
- **KHÔNG** commit `token.json` vào git
- Thêm vào `.gitignore`:
  ```
  credentials.json
  token.json
  ```

### 🔄 Refresh Token
Nếu token hết hạn hoặc gặp lỗi xác thực:
1. Xóa file `token.json`
2. Chạy lại script
3. Xác thực lại theo hướng dẫn

### 📁 Quyền Truy Cập
Script sẽ tự động set quyền public cho file upload. Nếu bạn muốn hạn chế quyền truy cập, sửa đổi trong hàm `upload_to_drive()` trong `build_and_upload.py`.

## Troubleshooting

### Lỗi: "credentials.json not found"
- Đảm bảo file `credentials.json` đã được tải từ Google Cloud Console
- Đảm bảo file nằm cùng thư mục với `build_and_upload.py`

### Lỗi: "Google Drive API has not been used"
- Quay lại [Google Cloud Console](https://console.cloud.google.com/)
- Vào **APIs & Services** > **Library**
- Tìm "Google Drive API" và click **Enable**

### Lỗi: "Access blocked: ... has not completed the Google verification process"
- Click **Advanced** (ở màn hình cảnh báo)
- Click **Go to ... (unsafe)**
- Tiếp tục xác thực

### Lỗi: "module 'google' has no attribute 'auth'"
```bash
pip uninstall google google-auth
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
```

## Sử Dụng Script

### Build và Upload Mới
```bash
python build_and_upload.py --version 1.1.0 --build-number 2 --force-update
```

### Chỉ Build Không Upload
```bash
python build_and_upload.py --version 1.1.0 --build-number 2 --build-only
```

### Chỉ Update version.json (nếu APK đã tồn tại)
```bash
python build_and_upload.py --version 1.1.0 --build-number 2 --force-update --update-json-only
```

## Liên Kết Hữu Ích

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Drive API Documentation](https://developers.google.com/drive/api/v3/about-sdk)
- [Python Google API Client](https://github.com/googleapis/google-api-python-client)
