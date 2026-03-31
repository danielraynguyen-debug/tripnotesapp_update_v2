import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../widgets/create_ride_dialog.dart';
import 'home_screen.dart';
import 'tabs/activity_tab.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;
  const RideDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final currentUser = authRepo.currentUser;

    return StreamBuilder<RideModel?>(
      stream: rideRepo.getRideStream(ride.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text("Chi tiết ghi chú")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentRide = snapshot.data!;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentRide.status != 'pending' && currentRide.driverId != currentUser?.uid && currentRide.creatorId != currentUser?.uid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ghi chú này đã được người khác nhận!"),
                backgroundColor: Colors.redAccent,
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });

        final isPending = currentRide.status == 'pending';
        final isMyOngoing = currentRide.status == 'ongoing' && currentRide.driverId == currentUser?.uid;
        final bool isCreator = currentUser?.uid == currentRide.creatorId;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("Chi tiết ghi chú", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with creator info
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: _buildCreatorInfo(currentRide)),
                              if (isCreator && isPending)
                                IconButton(
                                  onPressed: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierLabel: "EditRide",
                                      pageBuilder: (context, _, __) => CreateRideDialog(editRide: currentRide),
                                    );
                                  },
                                  icon: Icon(Icons.edit_note, color: Colors.grey[600]),
                                  tooltip: "Sửa ghi chú",
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    hoverColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                  ),
                                ),
                              if (isCreator)
                                IconButton(
                                  onPressed: () => _confirmDelete(context, rideRepo),
                                  icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                                  tooltip: "Xóa ghi chú",
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    hoverColor: Colors.red.withOpacity(0.1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem(Icons.calendar_today, "Thời gian", 
                                  DateFormat('HH:mm - EEEE, dd/MM/yyyy').format(currentRide.dateTime)),
                              const Divider(height: 32, color: Color(0xFFF1F5F9)),
                              
                              // New route display with two-line addresses
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left icons column with dotted line
                                  Column(
                                    children: [
                                      // Origin blue circle
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[700],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Dotted line - Slate gray
                                      Container(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        height: 50,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: List.generate(
                                            6,
                                            (index) => Container(
                                              width: 2,
                                              height: 2,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFCBD5E1),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Destination red circle
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.red[700],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  // Right side: addresses
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Pickup
                                        _buildTwoLineAddressContent("Điểm đón", currentRide.pickupPoint),
                                        const SizedBox(height: 20),
                                        // Destination
                                        _buildTwoLineAddressContent("Điểm đến", currentRide.destinationPoint),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTripTypeItem(currentRide.type),
                              const Divider(height: 32, color: Color(0xFFF1F5F9)),
                              
                              if (isMyOngoing) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildDetailItem(Icons.phone, "Số điện thoại khách", "******", iconColor: const Color(0xFF4F46E5)),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final Uri launchUri = Uri(scheme: 'tel', path: currentRide.customerPhone);
                                        await launchUrl(launchUri);
                                      },
                                      icon: const Icon(Icons.call, color: Color(0xFF4F46E5)),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32, color: Color(0xFFF1F5F9)),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: _buildDetailItem(Icons.route, "Khoảng cách", currentRide.distance),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(currentRide.price),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                          child: const Text(
                            "Hủy bỏ",
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!isCreator)
                        Expanded(
                          child: _buildActionButton(
                            label: "Nhận ghi chú",
                            color: const Color(0xFF4F46E5),
                            onPressed: () async {
                              if (currentUser != null) {
                                final ongoingRides = await rideRepo.getOngoingRides(currentUser.uid).first;
                                if (ongoingRides.isNotEmpty) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Bạn đang có một ghi chú chưa hoàn thành. Vui lòng hoàn tất trước khi nhận mới!"), backgroundColor: Colors.orange),
                                    );
                                  }
                                  return;
                                }

                                await rideRepo.acceptRide(
                                  currentRide.id, 
                                  currentUser.uid, 
                                  currentUser.displayName ?? 'Thành viên', 
                                  currentUser.phoneNumber ?? ''
                                );

                                debugPrint('✅ acceptRide completed, navigating...');
                                debugPrint('HomeScreen.homeKey: ${HomeScreen.homeKey.currentState}');
                                debugPrint('ActivityTab.activityKey: ${ActivityTab.activityKey.currentState}');

                                // Chuyển đến Hoạt động -> Đang diễn ra
                                HomeScreen.homeKey.currentState?.setIndex(1);
                                ActivityTab.activityKey.currentState?.setTabIndex(0);
                                
                                if (context.mounted) {
                                  Navigator.popUntil(context, (route) => route.isFirst);
                                  // Hiện SnackBar sau khi navigation hoàn tất
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    HomeScreen.homeKey.currentState?.showSnackBar(
                                      "Đã nhận ghi chú thành công!",
                                      backgroundColor: Colors.green,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  )
                else if (isMyOngoing)
                  _buildActionButton(
                    label: "Hủy nhận chuyến",
                    color: Colors.redAccent,
                    onPressed: () => _showCancelDialog(context, rideRepo, currentRide, currentUser?.uid ?? ''),
                    isOutlined: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, RideRepository rideRepo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn xóa ghi chú này không? Thao tác này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              try {
                debugPrint('🗑️ Đang xóa ghi chú: ${ride.id}');
                await rideRepo.deleteRide(ride.id);
                debugPrint('✅ Đã xóa ghi chú thành công');
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); 
                }
                if (context.mounted) {
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã xóa ghi chú thành công!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                debugPrint('❌ Lỗi xóa ghi chú: $e');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi xóa: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("XÓA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, RideRepository rideRepo, RideModel ride, String driverId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text("Xác nhận hủy chuyến"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vui lòng nhập lý do hủy chuyến:",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ví dụ: Khách hàng đổi lịch, xe gặp sự cố...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "⚠️ Lưu ý:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Vui lòng nhập lý do hủy chuyến để chúng tôi cải thiện dịch vụ.",
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("ĐÓNG", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton.icon(
            onPressed: () async {
              final reason = reasonController.text.trim();
              
              final result = await rideRepo.cancelRide(ride.id, driverId, reason: reason.isNotEmpty ? reason : null);
              
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                
                if (result['success']) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                } else {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        icon: const Icon(Icons.error_outline, color: Colors.red),
                        title: const Text("Không thể hủy"),
                        content: Text(result['message']),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("ĐÓNG"),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text("HỦY CHUYẾN"),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorInfo(RideModel ride) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE0E7FF),
          child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("NGƯỜI ĐĂNG", style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(
                (ride.creatorName ?? "Thành viên ẩn danh"),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
              ),
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color iconColor = const Color(0xFF64748B)}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value, 
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeItem(String type) {
    final isRoundTrip = type == 'round_trip';
    return Row(
      children: [
        Icon(
          isRoundTrip ? Icons.swap_calls : Icons.arrow_forward,
          size: 24,
          color: const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Loại chuyến",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isRoundTrip ? 'Khứ hồi' : '1 chiều',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Parse address to get street/route (bold line) and full address (regular line)
  (String, String) _parseAddress(String fullAddress) {
    if (fullAddress.isEmpty) return ('', '');
    
    final parts = fullAddress.split(',');
    if (parts.isEmpty) return (fullAddress, '');
    
    // First part usually contains street number and route
    final streetRoute = parts[0].trim();
    
    // Rest is the full context (ward, district, city, etc.)
    final remainingParts = parts.skip(1).map((p) => p.trim()).join(', ');
    
    return (streetRoute, remainingParts);
  }

  Widget _buildTwoLineAddressContent(String label, String address) {
    final (streetRoute, fullContext) = _parseAddress(address);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        // Bold line: street_number + route
        Text(
          streetRoute.isEmpty ? address : streetRoute,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1E293B),
            height: 1.2,
          ),
        ),
        // Regular line: full context
        if (fullContext.isNotEmpty)
          Text(
            fullContext,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
      ],
    );
  }
}
