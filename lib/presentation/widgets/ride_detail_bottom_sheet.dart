import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/ride_repository.dart';
import 'clay_container.dart';
import '../screens/home_screen.dart';

class RideDetailBottomSheet extends StatelessWidget {
  final RideModel ride;
  const RideDetailBottomSheet({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final currentUser = authRepo.currentUser;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F9F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chi tiết ghi chú mới",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 32),
          ClayContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCreatorInfo(ride),
                const Divider(height: 24),
                _buildDetailItem(Icons.calendar_today, "Thời gian",
                    DateFormat('HH:mm - dd/MM/yyyy').format(ride.dateTime)),
                const Divider(height: 24),
                _buildDetailItem(Icons.radio_button_checked, "Điểm đón", ride.pickupPoint, iconColor: Colors.blue),
                const SizedBox(height: 12),
                _buildDetailItem(Icons.location_on, "Điểm đến", ride.destinationPoint, iconColor: Colors.red),
                const SizedBox(height: 12),
                _buildTripTypeItem(ride.type),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _buildDetailItem(Icons.route, "Khoảng cách", ride.distance)),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(ride.price),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Quay lại", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (currentUser != null) {
                      final ongoingRides = await rideRepo.getOngoingRides(currentUser.uid).first;
                      if (ongoingRides.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Bạn đang có ghi chú chưa hoàn thành!"), backgroundColor: Colors.orange),
                          );
                        }
                        return;
                      }

                      // CẬP NHẬT: Truyền thêm driver info
                      await rideRepo.acceptRide(
                        ride.id, 
                        currentUser.uid, 
                        currentUser.displayName ?? 'Thành viên', 
                        currentUser.phoneNumber ?? ''
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đã nhận ghi chú thành công!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        HomeScreen.homeKey.currentState?.setIndex(1);
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  child: const Text("Nhận ghi chú", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorInfo(RideModel ride) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.purple, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("NGƯỜI ĐĂNG", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Text(
                (ride.creatorName ?? "Thành viên ẩn danh").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color iconColor = Colors.grey}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          size: 20,
          color: isRoundTrip ? Colors.purple[700] : Colors.blue[700],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Loại chuyến",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRoundTrip ? Colors.purple[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isRoundTrip ? 'Khứ hồi' : '1 chiều',
                style: TextStyle(
                  color: isRoundTrip ? Colors.purple[700] : Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
