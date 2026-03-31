const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// Hàm định dạng số tiền VND (VD: 100000 -> 100.000)
function formatCurrency(amount) {
  return new Intl.NumberFormat('vi-VN').format(amount);
}

// 1. Thông báo cho tất cả tài xế khi có ghi chú mới
exports.sendNotificationOnNewRide = functions.firestore
  .document('rides/{rideId}')
  .onCreate(async (snap, context) => {
    const ride = snap.data();
    const formattedPrice = ride.price ? formatCurrency(ride.price) : 'Thỏa thuận';
    const tripTypeLabel = ride.type === 'round_trip' ? ' (Khứ hồi)' : '';

    const message = {
      notification: {
        title: '🔥 Có chuyến xe mới!',
        body: `Giá: ${formattedPrice} VNĐ${tripTypeLabel}\nĐón tại: ${ride.pickupPoint}\nTrả tại: ${ride.destinationPoint}`,
      },
      data: {
        rideId: context.params.rideId,
      },
      topic: 'new_rides',
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
        }
      },
    };

    try {
      await admin.messaging().send(message);
      return null;
    } catch (error) {
      console.error('Lỗi gửi thông báo chuyến mới:', error);
      return null;
    }
  });

// 2. Thông báo riêng cho Người đăng khi có người nhận chuyến
exports.sendNotificationToCreator = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Kiểm tra nếu chuyến xe vừa được nhận (trước chưa có driverId, giờ đã có)
    if (!oldData.driverId && newData.driverId) {
      const creatorId = newData.creatorId;
      if (!creatorId) return null;

      // Lấy thông tin FCM Token của người tạo chuyến từ collection 'users'
      const userDoc = await admin.firestore().collection('users').doc(creatorId).get();
      if (!userDoc.exists) return null;

      const fcmToken = userDoc.data().fcmToken;

      if (fcmToken) {
        const message = {
          token: fcmToken,
          notification: {
            title: '🎉 Đã có người nhận chuyến!',
            body: `Tài xế ${newData.driverName} đã nhận chuyến của bạn.`,
          },
          data: {
            rideId: context.params.rideId,
            type: 'ride_accepted'
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
            }
          },
        };

        try {
          await admin.messaging().send(message);
          console.log('Đã gửi thông báo cho người đăng:', newData.creatorName);
          return null;
        } catch (error) {
          console.error('Lỗi gửi thông báo cho người đăng:', error);
          return null;
        }
      }
    }
    return null;
  });