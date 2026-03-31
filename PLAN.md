# Project Plan: Trip Notes App

## 1. Cấu trúc Project (Clean Architecture)
- `lib/core/services/`: Chứa các dịch vụ dùng chung (NotificationService).
- `lib/data/models/`: Định nghĩa các thực thể (RideModel, UserModel).
- `lib/data/repositories/`: Xử lý dữ liệu Firebase (AuthRepository, RideRepository).
- `lib/presentation/bloc/`: Quản lý trạng thái (AuthBloc).
- `lib/presentation/screens/`: Giao diện các màn hình chính (Tabs, Details, Auth).
- `lib/presentation/widgets/`: Các widget UI dùng chung (ClayContainer, RideCard, CreateRideDialog).

## 2. Các chức năng đã triển khai
- **Hệ thống Thiết kế (Design System)**: Indigo/Master Designer Palette (#4F46E5), Typography phân cấp rõ ràng, Soft Shadows.
- **Auth**: Firebase Auth (Số điện thoại), tự động lấy/cập nhật FCM Token (cả user mới và cũ), lưu profile người dùng realtime.
- **Tạo & Quản lý ghi chú**:
    - Tạo chuyến xe 1 chiều / khứ hồi.
    - Autocomplete địa chỉ (Goong API) tích hợp mục "Vị trí của tôi" (Target Icon).
    - Chọn SĐT khách hàng trực tiếp từ Danh bạ điện thoại.
    - Tính toán khoảng cách di chuyển thực tế (Distance Matrix).
    - **Sửa/Xóa ghi chú**: Người đăng có quyền chỉnh sửa thông tin hoặc xóa ghi chú của mình.
- **Trang chủ**: Danh sách chuyến xe `pending` sắp xếp mới nhất lên đầu, tự động ẩn SĐT khách bảo mật.
- **Hoạt động (Activity)**:
    - **Đang diễn ra**: Dẫn đường thông minh (Đón khách -> Đường đến -> Đường về cho khứ hồi), Tự động hoàn thành/ẩn nút qua GPS.
    - **Quản lý ghi chú**: Tab quản lý với Filter Pill (Tất cả, Ghi chú của tôi, Đã hoàn thành).
- **Tài khoản**: Cập nhật ảnh đại diện (Storage nén dung lượng), hiển thị Hạng thành viên (Hạng Chì), đăng xuất an toàn.
- **Thông báo**: Push Notification (FCM v1) đa dòng, điều hướng sâu (Deep link) từ thông báo vào chi tiết chuyến xe. Đã fix lỗi `style`/`bigText` invalid JSON payload.
- **Cập nhật ứng dụng**: Chuyển từ Firebase App Distribution sang Google Drive (tự động build, upload APK và version.json).

## 3. Danh sách các file cần bảo trì
| File | Chức năng chính |
| :--- | :--- |
| `lib/main.dart` | Theme Indigo, Việt hóa (Localization), khởi tạo FCM. |
| `lib/data/models/ride_model.dart` | Model mở rộng (Type, Creator, Driver info). |
| `lib/data/repositories/ride_repository.dart` | Logic CRUD, Realtime Streams, Filters. |
| `lib/presentation/screens/home_screen.dart` | GlobalKey navigation, Tab management. |
| `lib/presentation/screens/ride_detail_screen.dart` | StreamBuilder theo dõi trạng thái realtime. |
| `lib/presentation/widgets/create_ride_dialog.dart` | Form thông minh (Contact picker, My Location, Edit mode). |
| `lib/presentation/screens/tabs/activity_tab.dart` | GPS Tracking, Return trip logic, Manage Notes UI. |
| `lib/core/services/notification_service.dart` | Xử lý Deep Linking và Foreground notifications. |
| `tools/build_and_upload.py` | Build APK release và upload lên Google Drive (APK + version.json). |
| `functions/index.js` | Cloud Functions gửi thông báo 2 chiều (New Ride & Accepted). Đã fix lỗi FCM payload. |

## 4. Các công việc cần làm tiếp theo
- [ ] Tối ưu hóa hiệu năng Background Location để tiết kiệm pin tối đa bằng cách tắt các service khi không có chuyến xe ongoing.
- [ ] Xây dựng bảng xếp hạng thành viên dựa trên số chuyến hoàn thành.
- [ ] Cấu hình Firebase App Check (Device Check / Play Integrity) để bảo mật API tối đa.
- [ ] Xử lý lỗi mất kết nối mạng (Retry logic) khi đang gọi Google/Goong API.
- [ ] Tích hợp ví tiền điện tử hoặc hệ thống điểm thưởng nội bộ.

## 5. Cấu hình Firebase & Google Drive
- **Firestore**: Collections `rides`, `users`. Đã thiết lập Rule bảo mật theo UID.
- **Firebase Messaging**: Topic `new_rides` cho tài xế và Token riêng cho người đăng.
- **Firebase Storage**: Thư mục `avatars/` với Rule giới hạn kích thước < 2MB.
- **Google Drive**: Thư mục chứa `app-release.apk` và `version.json` cho Force Update. Service Account cần `credentials.json`.
- **VS Code Task**: Task "🚀 Build & Upload to Google Drive" để tự động hóa.
