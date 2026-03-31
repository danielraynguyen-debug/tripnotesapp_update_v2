# Trip Notes - Tài liệu Đặc tả UI/UX (UI/UX Documentation)

Dự án **Trip Notes** là một ứng dụng di động (Flutter) dành cho việc kết nối và quản lý các chuyến xe (ghi chú) giữa các thành viên (tài xế/người đăng). Ứng dụng được thiết kế theo phong cách hiện đại **3D / Claymorphism**, tập trung vào trải nghiệm mượt mà, trực quan và tối ưu luồng thao tác (UX).

Dưới đây là mô tả chi tiết toàn bộ UI và UX của dự án:

---

## 1. Phong cách Thiết kế (Design Language)
*   **Claymorphism (3D mềm)**: Các khối thông tin (Card, Container) không phẳng mà được thiết kế nổi lên như những khối đất sét. Hiệu ứng này đạt được nhờ sự kết hợp giữa 2 lớp bóng đổ (Shadow): một lớp bóng tối mờ ở góc dưới bên phải và một lớp bóng sáng/trắng ở góc trên bên trái.
*   **Màu sắc chủ đạo (Theme)**: 
    *   Màu nền ứng dụng: Xanh lơ nhạt (`#F2F9F8`).
    *   Màu nhấn chính (Primary): Tím nhạt (`#7B66FF`) dùng cho các nút bấm, biểu tượng quan trọng và Floating Action Button.
    *   Màu trạng thái: Đỏ (Điểm đến, Hủy, Xóa), Xanh dương (Điểm đón, Đường đến), Cam (Khoảng cách, Đón khách), Xanh lá (Tiền bạc, Gọi điện).
*   **Typography**: Sử dụng font chữ **Google Sans** với tiếng Việt, mang lại cảm giác thân thiện, dễ đọc và hiện đại.

---

## 2. Kiến trúc Điều hướng (Navigation)

### 2.1. Bottom Navigation Bar
Ứng dụng sử dụng thanh điều hướng dưới cùng (BottomAppBar) với thiết kế khoét lỗ (Notched Shape) ở giữa:
*   **Trang chủ (Home)**: Danh sách các chuyến xe mới.
*   **Hoạt động (Activity)**: Quản lý các chuyến xe đang thực hiện và lịch sử.
*   **Thông báo (Notification)**: Danh sách ghi chú mới nhất cập nhật theo thời gian thực.
*   **Tài khoản (Profile)**: Quản lý thông tin cá nhân.

### 2.2. Floating Action Button (Nút Tạo Ghi chú)
*   Nằm ở vị trí trung tâm (`centerDocked`), bo tròn, nổi bật với màu tím chủ đạo.
*   **UX**: Nhấn vào nút này từ bất kỳ tab nào cũng sẽ bật lên giao diện "Tạo ghi chú mới" toàn màn hình.

---

## 3. Phân tích chi tiết các Màn hình (Screens)

### 3.1. Đăng nhập & Đăng ký (Auth)
*   **Đăng nhập bằng Số điện thoại**: 
    *   Sử dụng `intl_phone_field` để tự động hiển thị cờ Việt Nam (+84).
    *   **UX**: Tự động kiểm tra tính hợp lệ của số điện thoại (9 hoặc 10 số). Nút "Gửi OTP" chỉ sáng lên khi nhập đúng định dạng. Tự động loại bỏ số 0 ở đầu khi gửi lên Firebase để tránh lỗi `Invalid Phone Number`.
*   **Xác thực OTP**: 
    *   Giao diện nhập 6 số với hiệu ứng Claymorphism cho từng ô (`pinput`).
*   **Đăng ký thông tin**: Dành cho user mới. Thu thập Họ Tên và Email để lưu vào Firestore.

### 3.2. Tạo ghi chú mới (Create Ride)
Giao diện nhập liệu trơn tru, hạn chế tối đa thao tác thừa của người dùng:
*   **Ngày giờ đi**: Nhấn vào sẽ mở Calendar và Clock Picker (Đã được Việt hóa hoàn toàn). Hiển thị text dạng in đậm, không bị tràn dòng. (Chặn người dùng chọn thời gian trong quá khứ).
*   **SĐT Khách**: Bàn phím số (`phone`), giới hạn tối đa 10 số.
*   **Điểm đón & Điểm đến (Goong Maps Autocomplete)**: 
    *   **UX Debounce**: Đợi người dùng dừng gõ 1000ms mới gọi API gợi ý, giúp tiết kiệm chi phí.
    *   **Inline Suggestion**: Danh sách địa chỉ gợi ý hiện ngay bên dưới ô nhập liệu (Không bật pop-up che khuất màn hình). Nhấn vào gợi ý sẽ tự động điền đầy đủ text vào ô.
    *   **Map Picker**: Bên phải có icon Bản đồ. Nhấn vào sẽ mở Google Maps (có nút định vị trí hiện tại và tự động nhận diện địa chỉ khi kéo bản đồ).
*   **Loại chuyến**: Dropdown chọn "1 chiều" hoặc "Khứ hồi".
*   **Khoảng cách dự kiến**: Tự động gọi API `DistanceMatrix` của Goong Maps sau khi có tọa độ. Nếu chọn "Khứ hồi", khoảng cách sẽ tự động nhân đôi.
*   **Giá tiền**: Tự động định dạng thêm dấu phẩy (VD: `100,000`) khi gõ.

### 3.3. Trang chủ (Home Tab)
*   Hiển thị danh sách các chuyến xe ở trạng thái chờ (`pending`).
*   Các thẻ chuyến xe (RideCard) được thiết kế bo góc, đổ bóng.
*   **Bảo mật UX**: Trên thẻ chỉ hiện Thời gian, Giá tiền, Điểm đón, Điểm đến và Khoảng cách. **Tuyệt đối ẩn Số điện thoại khách hàng** để tránh lộ thông tin trước khi có người nhận chuyến.
*   **UX Scroll**: Danh sách có padding bottom lớn (140px) để đảm bảo thẻ cuối cùng không bị nút Tạo ghi chú che mất.

### 3.4. Chi tiết ghi chú (Ride Detail Screen)
Khi nhấn vào một thẻ ở Trang chủ hoặc Thông báo:
*   Hiển thị đầy đủ thông tin chuyến xe.
*   **Người đăng (Creator)**: Tên người tạo ghi chú được in hoa nổi bật.
    *   Nếu người đang xem chính là Người đăng: Có thêm icon **Thùng rác đỏ** để **Xóa ghi chú**.
*   **Nút chức năng**:
    *   Trạng thái Chờ: Hai nút "Hủy bỏ" (Đóng trang) và "Nhận ghi chú".
    *   Trạng thái Đang nhận (Của mình): Nút "Hủy nhận chuyến" (Màu đỏ).
*   **UX Nhận chuyến**:
    *   Kiểm tra "Chỉ được nhận 1 chuyến": Nếu tài xế đang có chuyến chưa hoàn thành, hệ thống sẽ báo lỗi màu cam và không cho nhận.
    *   Nếu có người khác (User B) đã nhận chuyến này, màn hình của User A sẽ tự động báo lỗi và văng ra ngoài.
    *   Sau khi nhận thành công, màn hình sẽ đóng lại và **Bottom Navigation tự động chuyển sang tab Hoạt động**.

### 3.5. Hoạt động (Activity Tab)
Gồm 2 Tab con: **Đang diễn ra** và **Lịch sử**.

#### Tab Đang diễn ra (Ongoing)
Nơi tài xế thao tác chính trong quá trình chở khách.
*   **Đối với Người nhận (Tài xế)**:
    *   Thẻ ghi chú hiện thêm dòng "TẠO BỞI: [TÊN IN HOA]".
    *   Có nút **"GỌI NGƯỜI ĐĂNG"** để liên hệ chủ chuyến.
    *   **Thanh công cụ điều hướng thông minh (Google Maps Deep Link)**:
        *   Nút **"Gọi khách"** (Màu xanh lá).
        *   Nút **"Đón khách"** (Màu cam): Dẫn đường từ vị trí tài xế đến Điểm đón.
        *   Nút **"Đường đến"** (Màu xanh dương): Dẫn đường từ Điểm đón đến Điểm đến.
    *   **UX Tự động hóa bằng GPS**:
        *   Khi tài xế cách Điểm đón <= 200m: Nút "Đón khách" tự động **ẩn đi**.
        *   Khi tài xế cách Điểm đến <= 500m: 
            *   Nếu là 1 chiều: Chuyến xe tự động hoàn thành và chuyển sang Lịch sử.
            *   Nếu là Khứ hồi: Nút "Đường đến" biến thành nút **"Đường về"** (Màu tím, dẫn đường ngược lại Điểm đón). Khi về đến nơi <= 500m mới tính là hoàn thành.
    *   **UX Hủy chuyến khứ hồi**: Nếu tài xế nhấn Hủy ở chặng về, hệ thống yêu cầu nhập Giá mới. Chặng về đó sẽ biến thành một ghi chú 1 chiều hoàn toàn mới trên Trang chủ.
*   **Đối với Người đăng (Chủ chuyến)**:
    *   Thẻ ghi chú hiện dòng "Người nhận: [TÊN IN HOA]".
    *   (Theo yêu cầu, nút Gọi tài xế đã được tạm ẩn để gọn UI).

#### Tab Lịch sử (History)
*   Hiển thị các chuyến xe đã hoàn thành với thiết kế mờ hơn (`opacity: 0.5`) kèm icon Check màu xanh lá.

### 3.6. Thông báo (Notification Tab)
*   Hiển thị danh sách thông báo các chuyến xe mới (Sắp xếp theo thời gian tạo thực tế, mới nhất ở trên cùng).
*   **UX Push Notification**: Bất cứ khi nào có ghi chú mới, Firebase Cloud Functions (FCM API V1) sẽ bắn thông báo Push cho toàn bộ thiết bị.
    *   *Chưa đăng nhập*: Nhấn vào thông báo -> Mở app -> Bắt đăng nhập -> Xong tự động nhảy thẳng vào trang Chi tiết ghi chú.
    *   *Đã đăng nhập*: Nhấn vào thông báo -> Mở app -> Nhảy thẳng vào trang Chi tiết ghi chú.
*   **Bottom Sheet UX**: Nếu nhấn vào thẻ thông báo bên trong app, thay vì mở trang mới, một bảng `RideDetailBottomSheet` (viền bo tròn 30px) sẽ trượt từ dưới lên. Bảng này đã được tính toán Padding để không bị thanh Home Bar của iPhone/Android che mất nút bấm. Nhấn "Nhận ghi chú" từ đây cũng sẽ tự động chuyển sang tab Hoạt động.

### 3.7. Tài khoản (Profile Tab)
*   Thiết kế thẻ thông tin cá nhân dạng list trong khối Claymorphism.
*   **Hạng thành viên**: Nằm ở vị trí đầu tiên (Mặc định: Hạng Chì, Icon màu xám xanh).
*   **Cập nhật Avatar**: Nhấn vào vòng tròn ảnh đại diện để tải ảnh từ thư viện. Tích hợp tính năng nén dung lượng (Quality 50%) trước khi upload lên Firebase Storage để tiết kiệm băng thông.
*   **Đăng xuất**: Nút màu đỏ. Nhấn vào sẽ xóa toàn bộ bộ nhớ đệm điều hướng và đưa người dùng về trang Đăng nhập.

---

## 4. Tính năng Bảo mật (Security)
*   **Che giấu SĐT**: Số điện thoại khách hàng luôn ở trạng thái `******` đối với những người chưa nhận chuyến, và cả khi đã nhận chuyến (để tránh tài xế lưu số vào danh bạ cá nhân). Chỉ có thể dùng nút "Gọi" để mở trình quay số của hệ thống.
*   **Firestore Rules**: Chỉ người dùng có Token xác thực (`request.auth != null`) mới được đọc/ghi dữ liệu.
*   **Storage Rules**: Avatar tải lên bị giới hạn kích thước < 2MB, bắt buộc phải là file ảnh (`image/*`) và tên file phải trùng khớp với UID của người dùng.
*   **Bảo mật API Key**: Lệnh gọi thông báo Push Notification được chuyển lên Backend (Firebase Cloud Functions) bằng Node.js thay vì để trên ứng dụng Flutter, tuân thủ tuyệt đối giao thức FCM API v1 mới nhất của Google.
