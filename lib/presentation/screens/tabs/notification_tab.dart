import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/ride_repository.dart';
import '../../widgets/ride_detail_bottom_sheet.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  String _notificationFilter = 'all';

  // Modern Glass & Indigo Colors
  static const Color bgApp = Color(0xFFF8FAFC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFF6366F1);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFF1F5F9);
  static const Color successGreen = Color(0xFF10B981);
  static const Color amberColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final currentUserId = authRepo.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: const Text(
          "THÔNG BÁO",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textPrimary,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: bgApp,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterPill('Tất cả', 'all'),
                _buildFilterPill('Của tôi', 'mine'),
                _buildFilterPill('Công cộng', 'public'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Notification List
          Expanded(
            child: StreamBuilder<List<RideModel>>(
              stream: rideRepo.getPendingRides(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryIndigo,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: primaryIndigo.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Không có thông báo mới",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter data based on _notificationFilter
                List<RideModel> filteredRides = snapshot.data!.where((ride) {
                  final isMine = ride.creatorId == currentUserId;
                  if (_notificationFilter == 'mine') {
                    return isMine;
                  } else if (_notificationFilter == 'public') {
                    return !isMine;
                  }
                  return true;
                }).toList();

                if (filteredRides.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không có thông báo nào trong mục này",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                  itemCount: filteredRides.length,
                  itemBuilder: (context, index) {
                    final ride = filteredRides[index];
                    final isMyRide = ride.creatorId == currentUserId;
                    
                    return _buildNotificationCard(ride, isMyRide);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(RideModel ride, bool isMyRide) {
    final iconColor = isMyRide ? primaryIndigo : amberColor;
    final iconBgColor = isMyRide ? const Color(0xFFE0E7FF) : const Color(0xFFFEF3C7);
    final titleText = isMyRide ? "Ghi chú của bạn" : "Chuyến mới được đăng";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RideDetailBottomSheet(ride: ride),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isMyRide ? Icons.assignment_ind : Icons.notifications_active,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                titleText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isMyRide ? primaryIndigo : textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Trip type badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ride.type == 'round_trip' 
                                  ? const Color(0xFFE0E7FF)
                                  : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    ride.type == 'round_trip' ? Icons.swap_horiz : Icons.arrow_forward,
                                    size: 12,
                                    color: ride.type == 'round_trip' ? primaryIndigo : const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ride.type == 'round_trip' ? 'Khứ hồi' : '1 chiều',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: ride.type == 'round_trip' ? primaryIndigo : const Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Route info
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRouteInfoRow(Icons.trip_origin, ride.pickupPoint, Colors.blue[700]!),
                                  const SizedBox(height: 6),
                                  _buildRouteInfoRow(Icons.place, ride.destinationPoint, Colors.red[700]!),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Footer info
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: textSecondary.withOpacity(0.7)),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('HH:mm - dd/MM/yyyy').format(ride.dateTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(ride.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: successGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 24, color: textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String text, String value) {
    final isSelected = _notificationFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _notificationFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          color: isSelected ? null : bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryIndigo.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: primaryIndigo.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
