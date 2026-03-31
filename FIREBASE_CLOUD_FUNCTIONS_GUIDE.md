# Hướng dẫn thiết lập Push Notification tự động qua Firebase Cloud Functions

Để tất cả các tài xế (thiết bị) nhận được thông báo khi có một chuyến xe (ghi chú) mới được tạo, chúng ta cần sử dụng **Firebase Cloud Functions**. Chức năng này sẽ đóng vai trò như một Backend thu nhỏ: tự động lắng nghe khi một dữ liệu mới được thêm vào collection `rides` và gửi lệnh Push Notification thông qua **Firebase Cloud Messaging (FCM)**.

### Yêu cầu tiên quyết:
- Firebase Project của bạn phải được nâng cấp lên gói **Blaze (Pay as you go)** vì Google Cloud yêu cầu thẻ thanh toán cho các dịch vụ Functions. (Tuy nhiên với lượng dùng nhỏ, nó hoàn toàn miễn phí).
- Bạn đã cài đặt [Node.js](https://nodejs.org/) trên máy tính.

---

### Bước 1: Cài đặt Firebase CLI (Công cụ dòng lệnh)
Mở Terminal (hoặc Command Prompt) trên máy tính của bạn và chạy lệnh sau để cài đặt Firebase CLI toàn cầu:
```bash
npm install -g firebase-tools
```

Đăng nhập vào tài khoản Google của bạn (tài khoản chứa Firebase Project):
```bash
firebase login
```

### Bước 2: Khởi tạo thư mục Functions
1. Mở Terminal và điều hướng đến thư mục dự án Flutter của bạn:
   ```bash
   cd C:/Users/nbtha/AndroidStudioProjects/tripnotesapp
   ```
2. Chạy lệnh khởi tạo Functions:
   ```bash
   firebase init functions
   ```
3. Các lựa chọn trong quá trình cài đặt:
   - **Are you ready to proceed?** `Yes`
   - **Please select an option:** `Use an existing project` (Chọn dự án `tripnotesapp` của bạn).
   - **What language would you like to use?** Chọn `JavaScript`.
   - **Do you want to use ESLint to catch probable bugs?** `No`
   - **Do you want to install dependencies with npm now?** `Yes`

### Bước 3: Viết Code Backend gửi thông báo
Sau khi khởi tạo xong, bạn sẽ thấy thư mục `functions/` trong dự án.
Hãy mở file `functions/index.js`, xóa toàn bộ nội dung cũ và dán đoạn code này vào:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Lắng nghe sự kiện TẠO MỚI một chuyến xe trong collection 'rides'
exports.sendNotificationOnNewRide = functions.firestore
  .document('rides/{rideId}')
  .onCreate(async (snap, context) => {
    // Lấy dữ liệu của chuyến xe vừa tạo
    const ride = snap.data();

    // Định nghĩa nội dung thông báo
    const payload = {
      notification: {
        title: 'Có chuyến xe mới! 🚀',
        body: `Từ ${ride.pickupPoint} đến ${ride.destinationPoint}`,
        sound: 'default'
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        rideId: context.params.rideId,
      }
    };

    // Tùy chọn gửi:
    // Vì trong Flutter App (NotificationService), chúng ta đã cho tất cả 
    // thiết bị Subscribe vào topic 'new_rides', nên ta sẽ gửi vào topic này.
    const topic = 'new_rides';

    try {
      const response = await admin.messaging().sendToTopic(topic, payload);
      console.log('Đã gửi thông báo thành công:', response);
      return null;
    } catch (error) {
      console.error('Lỗi khi gửi thông báo:', error);
      return null;
    }
  });
```

### Bước 4: Deploy (Triển khai) lên máy chủ Firebase
Mở Terminal, đảm bảo bạn đang ở thư mục `tripnotesapp` và chạy lệnh sau:
```bash
firebase deploy --only functions
```

Chờ khoảng 1-2 phút. Nếu Terminal báo `Deploy complete!`, bạn đã thành công.

---

### Cách hệ thống hoạt động thực tế (UX Flow):
1. **User Mở App:** File `NotificationService.dart` tự động gọi lệnh xin quyền (đối với Android 13+ hoặc iOS) và tự động đăng ký (Subscribe) thiết bị vào nhóm tên là `"new_rides"`.
2. **Khách / Tổng đài tạo ghi chú mới:** Firestore ghi nhận có Document mới trong collection `rides`.
3. **Cloud Functions kích hoạt:** Nó tóm lấy dữ liệu (Điểm đón, Điểm đến) và cấu trúc lại thành một tin nhắn đẩy (Push Notification).
4. **FCM Gửi đi:** Tin nhắn này được "bắn" ra cho tất cả các thiết bị đang Subscribe `"new_rides"`.
5. **Hiển thị (UX):**
   - *Nếu app đang tắt hoặc chạy ngầm (Background/Terminated):* Thông báo hiện lên thanh trạng thái (Status Bar) của điện thoại. Nhấn vào sẽ mở app.
   - *Nếu app đang mở trên màn hình (Foreground):* Gói `flutter_local_notifications` (đã được cấu hình) sẽ hiển thị bảng thông báo nổi từ cạnh trên màn hình (Heads-up) kèm âm thanh tinh tang, giúp tài xế không bỏ lỡ chuyến dù đang lướt tab khác trong app.
