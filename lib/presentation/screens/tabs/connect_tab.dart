import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/scheduled_route_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/ride_repository.dart';
import '../create_scheduled_route_screen.dart';
import '../scheduled_route_detail_screen.dart';

class ConnectTab extends StatelessWidget {
  // Modern Glass & Indigo Colors
  static const Color bgApp = Color(0xFFF8FAFC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFF6366F1);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFF1F5F9);
  static const Color slateLine = Color(0xFFCBD5E1);
  static const Color successGreen = Color(0xFF10B981);
  static const Color amberColor = Color(0xFFF59E0B);

  const ConnectTab({super.key});

  @override
  Widget build(BuildContext context) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final currentUser = authRepo.currentUser;

    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: currentUser != null ? authRepo.getUserStream(currentUser.uid) : Stream.value(null),
          builder: (context, userSnapshot) {
            final userModel = userSnapshot.data;
            final isPremium = true;

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "KẾT NỐI",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tìm lộ trình phù hợp",
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      _buildPremiumBadge(isPremium),
                    ],
                  ),
                ),
                
                // Create Route Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: InkWell(
                    onTap: () => _showCreateRouteOrPremium(context, isPremium),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryIndigo.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_road,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tạo lộ trình mới",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Chia sẻ chuyến đi của bạn",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                
                // Scheduled Routes List
                Expanded(
                  child: StreamBuilder<List<ScheduledRouteModel>>(
                    stream: rideRepo.getActiveScheduledRoutes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryIndigo,
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Lỗi: ${snapshot.error}",
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                        );
                      }

                      final routes = snapshot.data ?? [];
                      
                      if (routes.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          final isMyRoute = route.creatorId == currentUser?.uid;
                          return _buildRouteCard(context, route, isMyRoute, isPremium);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumBadge(bool isPremium) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isPremium
          ? const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
        color: isPremium ? null : amberColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? primaryIndigo : amberColor).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.lock_clock,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isPremium ? "Premium" : "Dùng thử",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRouteOrPremium(BuildContext context, bool isPremium) {
    if (!isPremium) {
      // Show premium upsell dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.workspace_premium, color: Color(0xFF4F46E5), size: 48),
          title: const Text("Tính năng Premium"),
          content: const Text(
            "Tạo lộ trình dự kiến là tính năng Premium.\n\n"
            "Nâng cấp để:\n"
            "• Tạo không giới hạn lộ trình\n"
            "• Liên hệ trực tiếp với tài xế\n"
            "• Ưu tiên hiển thị trong danh sách",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Để sau"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to upgrade screen or show more info
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tính năng nâng cấp sẽ sớm ra mắt!"),
                    backgroundColor: Color(0xFF4F46E5),
                  ),
                );
              },
              child: const Text("Dùng thử miễn phí"),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateScheduledRouteScreen()),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.route_outlined,
              size: 64,
              color: primaryIndigo.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Chưa có lộ trình nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy tạo lộ trình đầu tiên của bạn!",
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, ScheduledRouteModel route, bool isMyRoute, bool isPremium) {
    final timeStr = DateFormat('HH:mm').format(route.departureTime);
    final dateStr = DateFormat('EEEE, dd/MM', 'vi').format(route.departureTime);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduledRouteDetailScreen(route: route),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryIndigo.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header with time and vehicle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: primaryIndigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    route.vehicleType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isMyRoute)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                    onPressed: () => _confirmDelete(context, route),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // Route info - New design with full addresses
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side icons column
                Column(
                  children: [
                    // Origin blue circle
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Dotted line
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) => const SizedBox(
                            width: 2,
                            height: 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: slateLine,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Destination red circle
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Right side addresses - Full text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.pickupPoint,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        route.destinationPoint,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Footer: Seats, Price, Contact
            Row(
              children: [
                // Seats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_seat, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        "${route.availableSeats} ghế",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Price
                Expanded(
                  child: Text(
                    route.formattedPrice,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: route.price > 0 ? successGreen : textSecondary,
                    ),
                  ),
                ),
                
                // Contact button
                if (!isMyRoute)
                  ElevatedButton.icon(
                    onPressed: isPremium 
                        ? () => _contactRouteCreator(context, route)
                        : () => _showPremiumRequired(context),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text("Liên hệ"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryIndigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Notes
            if (route.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          route.notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScheduledRouteModel route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa lộ trình này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final rideRepo = RepositoryProvider.of<RideRepository>(context, listen: false);
              await rideRepo.deleteScheduledRoute(route.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã xóa lộ trình"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  void _showPremiumRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, color: Color(0xFF4F46E5), size: 48),
        title: const Text("Yêu cầu Premium"),
        content: const Text(
          "Liên hệ với người tạo lộ trình là tính năng Premium.\n\n"
          "Nâng cấp để sử dụng đầy đủ tính năng!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Để sau"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tính năng nâng cấp sẽ sớm ra mắt!"),
                  backgroundColor: Color(0xFF4F46E5),
                ),
              );
            },
            child: const Text("Dùng thử miễn phí"),
          ),
        ],
      ),
    );
  }

  Future<void> _contactRouteCreator(BuildContext context, ScheduledRouteModel route) async {
    if (route.creatorPhone?.isNotEmpty == true) {
      final uri = Uri(scheme: 'tel', path: route.creatorPhone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không có thông tin liên hệ"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
