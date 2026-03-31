import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/ride_repository.dart';
import '../../presentation/screens/ride_detail_screen.dart';

class NotificationService {
  // Cấu hình Google Drive cho Force Update
  // Thay YOUR_GOOGLE_DRIVE_FILE_ID bằng ID file version.json thực tế
  static const String _versionFileId = '12YLzz625s36hd0WYHQ6PwEnbysiDOV-r';
  
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? pendingRideId;

  static Future<void> initialize() async {
    // Kiểm tra cập nhật bắt buộc khi app khởi động
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForceUpdate(navigatorKey.currentContext);
    });

    // 1. Yêu cầu quyền thông báo (iOS & Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('⚠️ Người dùng chưa cấp quyền thông báo!');
    }

    // 2. Cấu hình Local Notifications để hiện thông báo khi app đang mở (Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          handleNotificationTap(response.payload!);
        }
      },
    );

    // 3. Đăng ký nhận thông báo theo chủ đề (Topic)
    try {
      await _messaging.subscribeToTopic('new_rides');
      debugPrint('✅ Đã đăng ký topic new_rides thành công');
    } catch (e) {
      debugPrint('❌ Lỗi đăng ký topic new_rides: $e');
    }

    // 3.1. Lắng nghe khi FCM Token được refresh và lưu vào Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token đã refresh: $newToken');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('✅ Đã cập nhật FCM Token mới vào Firestore');
        } catch (e) {
          debugPrint('❌ Lỗi cập nhật FCM Token: $e');
        }
      }
    });

    // 3.2. Cập nhật FCM Token cho user cũ (chưa có token) khi khởi động app
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists || userDoc.data()?['fcmToken'] == null) {
          debugPrint('⚠️ User chưa có fcmToken, đang cập nhật...');
          String? token = await _messaging.getToken();
          if (token != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            debugPrint('✅ Đã cập nhật FCM Token cho user cũ');
          }
        } else {
          debugPrint('✅ User đã có fcmToken: ${userDoc.data()?['fcmToken'].substring(0, 20)}...');
        }
      } catch (e) {
        debugPrint('❌ Lỗi kiểm tra/cập nhật FCM Token cho user cũ: $e');
      }
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'Thông báo chuyến mới',
      description: 'Nhận thông báo khẩn cấp về chuyến xe mới được đăng',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Xử lý khi nhận thông báo lúc app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Nhận thông báo foreground: ${message.notification?.title}');
      debugPrint('📨 Data: ${message.data}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          payload: message.data['rideId'], // Chuyền dữ liệu ID vào payload
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 5. Xử lý khi nhấn vào thông báo lúc app chạy ngầm (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Nhấn vào thông báo (background): ${message.data}');
      if (message.data['rideId'] != null) {
        handleNotificationTap(message.data['rideId']);
      }
    });

    // 6. Xử lý khi nhấn vào thông báo lúc app đã bị tắt (Terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data['rideId'] != null) {
      pendingRideId = initialMessage.data['rideId'];
    }
  }

  // Hàm kiểm tra và ép cập nhật bắt buộc qua version.json trên Google Drive
  static Future<void> _checkForceUpdate(BuildContext? context) async {
    if (context == null) return;
    
    // Bỏ qua nếu chưa cấu hình file ID
    if (_versionFileId == '1zx1CRD8yqi6lzD46ZzcIYuelTqpJ2aWB' || _versionFileId.isEmpty) {
      debugPrint('🔧 Force Update: Chưa cấu hình Google Drive File ID');
      return;
    }
    
    debugPrint('🔍 Đang kiểm tra cập nhật từ Google Drive...');
    
    try {
      final url = 'https://drive.google.com/uc?export=download&id=$_versionFileId';
      debugPrint('📥 Download URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version']?.toString() ?? '';
        final updateUrl = data['update_url']?.toString() ?? '';
        final forceUpdate = data['force_update'] ?? false;
        final releaseNotes = data['release_notes']?.toString() ?? 'Có phiên bản mới!';
        
        final info = await PackageInfo.fromPlatform();
        final currentVersion = info.version;
        
        debugPrint('📊 Current: $currentVersion | Latest: $latestVersion | Force: $forceUpdate');
        
        // So sánh version (hỗ trợ semantic versioning: 1.0.0 vs 1.0.1)
        final needsUpdate = _compareVersions(currentVersion, latestVersion) < 0;
        
        if (needsUpdate) {
          debugPrint('🚨 Cần cập nhật! Force: $forceUpdate');
          _showUpdateDialog(context, currentVersion, latestVersion, updateUrl, releaseNotes, forceUpdate);
        } else {
          debugPrint('✅ Đang dùng phiên bản mới nhất');
        }
      } else {
        debugPrint('❌ Lỗi tải version.json: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi kiểm tra cập nhật: $e');
      debugPrint('📋 Stack trace: $stackTrace');
    }
  }
  
  // So sánh semantic version (1.0.0 vs 1.0.1)
  // Trả về: -1 nếu v1 < v2, 0 nếu bằng, 1 nếu v1 > v2
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();
    
    for (int i = 0; i < 3; i++) {
      final p1 = parts1.length > i ? (parts1[i] ?? 0) : 0;
      final p2 = parts2.length > i ? (parts2[i] ?? 0) : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }
  
  static void _showUpdateDialog(BuildContext context, String currentVersion, String latestVersion, 
      String updateUrl, String releaseNotes, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // Chỉ cho phép dismiss nếu không bắt buộc
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => !forceUpdate, // Không cho back nếu bắt buộc
        child: AlertDialog(
          icon: const Icon(Icons.system_update, color: Colors.indigo, size: 48),
          title: Text(forceUpdate ? '⚠️ Cập nhật bắt buộc' : '🎉 Có bản cập nhật mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildVersionChip('Hiện tại', currentVersion, Colors.grey),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.indigo),
                    Expanded(
                      child: _buildVersionChip('Mới nhất', latestVersion, Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Cập nhật:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(releaseNotes, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Để sau'),
              ),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse(updateUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint('❌ Không thể mở URL: $updateUrl');
                }
              },
              icon: const Icon(Icons.download),
              label: Text(forceUpdate ? 'Cập nhật ngay' : 'Tải ngay'),
            ),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildVersionChip(String label, String version, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(version, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static void handleNotificationTap(String rideId) async {
    pendingRideId = rideId;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Đã đăng nhập -> Chuyển đến chi tiết ngay lập tức
      await _navigateToRideDetail(rideId);
    }
    // Nếu chưa đăng nhập, pendingRideId sẽ được giữ lại,
    // khi HomeScreen khởi tạo sau khi đăng nhập thành công, nó sẽ kiểm tra pendingRideId.
  }

  static Future<void> _navigateToRideDetail(String rideId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final rideRepo = RepositoryProvider.of<RideRepository>(context, listen: false);
    final ride = await rideRepo.getRideById(rideId);
    
    if (ride != null && context.mounted) {
      pendingRideId = null; // Xóa sau khi đã xử lý
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
      );
    }
  }
}
