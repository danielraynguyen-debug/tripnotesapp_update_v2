# Hướng dẫn bảo mật và triển khai Push Notification bằng Firebase Cloud Messaging (FCM) API V1

Từ ngày **20/06/2024**, Google đã chính thức ngừng hỗ trợ API Firebase Cloud Messaging thế hệ cũ (Legacy HTTP API) và bắt buộc tất cả ứng dụng phải chuyển sang sử dụng **FCM HTTP v1 API**.

Việc gửi thông báo Push Notification theo chuẩn FCM V1 đòi hỏi một Access Token OAuth 2.0 tồn tại trong thời gian ngắn, được tạo ra từ một File Service Account (tệp JSON bảo mật của Google Cloud).

**LƯU Ý CỰC KỲ QUAN TRỌNG VỀ BẢO MẬT:**
Bạn **TUYỆT ĐỐI KHÔNG ĐƯỢC** nhúng file Service Account JSON hoặc tự tạo Token HTTP v1 trực tiếp bên trong code của ứng dụng Flutter (phía Client). Nếu hacker dịch ngược file APK của bạn và lấy được file JSON này, họ sẽ chiếm toàn quyền điều khiển Firebase Database, Storage, Auth và gửi thông báo spam đến toàn bộ khách hàng của bạn.

**GIẢI PHÁP CHUẨN:**
Luôn sử dụng Backend riêng hoặc **Firebase Cloud Functions** (như ứng dụng của chúng ta đang làm) để gửi thông báo. `firebase-admin` Node.js SDK bên trong Cloud Functions đã được Google tích hợp sẵn **FCM v1 API**, tự động sinh Token an toàn mà không cần quản lý File Service Account thủ công.

---

### Hướng dẫn kiểm tra và Cập nhật Cloud Function lên FCM V1

Trong thư mục dự án của bạn, tôi đã cập nhật file `functions/index.js` tuân thủ nghiêm ngặt **chuẩn cấu trúc Payload của FCM v1**.

#### 1. Cấu trúc Payload FCM v1 mới:
```javascript
const message = {
  notification: {
    title: 'Có chuyến xe mới! 🚀',
    body: `Từ A đến B`,
  },
  data: {
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    rideId: '...',
  },
  topic: 'new_rides', // Topic nhận
  
  // Custom cho Android 8.0+ (Phải có nếu muốn thông báo đẩy nổi lên - Heads-up)
  android: {
    priority: 'high',
    notification: {
      channelId: 'high_importance_channel',
      defaultSound: true,
      defaultVibrateTimings: true,
    }
  },
  
  // Custom cho Apple Push Notification (APNs) trên iOS
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1,
        contentAvailable: true, // Wake-up ứng dụng chạy ngầm
      }
    }
  }
};
```

#### 2. Hàm gọi (Gửi thông báo):
Thay vì sử dụng lệnh cũ `admin.messaging().sendToTopic(topic, payload);` vốn chạy ngầm qua API cũ. 
Chúng ta chuyển sang lệnh mới nhất kết nối thẳng vào FCM v1:
```javascript
const response = await admin.messaging().send(message);
```

#### 3. Cách triển khai cập nhật (Deploy lại Server):
Sau khi bạn kiểm tra đoạn mã mới trong file `functions/index.js`, hãy chạy lệnh sau trong Terminal của Android Studio để đẩy (Deploy) đoạn mã backend này lên Google Cloud:

```bash
firebase deploy --only functions
```

### Cách thức hoạt động của luồng FCM V1 trong ứng dụng của bạn:
1. User nhấn "Đăng Ghi chú".
2. Dữ liệu được đẩy lên **Firestore** `rides`.
3. Firebase Cloud Functions (đang chạy độc lập trên máy chủ Google) lắng nghe sự kiện này, nó xây dựng payload chuẩn **FCM V1** (bao gồm `channelId` và các thiết lập ưu tiên cao cho Android/iOS).
4. Hàm gửi yêu cầu lên máy chủ FCM (đã được xác thực an toàn ở cấp độ backend).
5. Máy chủ FCM đẩy thông báo xuống tất cả các điện thoại Android/iOS đang "subscribe" topic `new_rides`.
6. Trên thiết bị của các tài xế khác, ngay cả khi màn hình đang tắt hoặc lướt web, một thông báo "Có chuyến xe mới!" sẽ nảy lên kèm theo tiếng bíp.

Thiết kế này đảm bảo ứng dụng của bạn được **bảo mật tuyệt đối, hoàn toàn tuân thủ tiêu chuẩn FCM V1 hiện tại của Google** và sẵn sàng hoạt động trong dài hạn mà không lo lỗi ngưng hỗ trợ API!
