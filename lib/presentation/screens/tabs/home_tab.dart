import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/repositories/ride_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/ride_card.dart';
import '../../widgets/create_ride_dialog.dart';
import '../../widgets/clay_container.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final currentUser = authRepo.currentUser;
    final userName = currentUser?.displayName ?? "Bạn";

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Xin chào, $userName!",
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5D4037), fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Button Tạo ghi chú mới - Style giống Tạo lộ trình mới
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const CreateRideDialog(),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: ClayContainer(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF4F46E5),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
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
                            "Tạo ghi chú mới",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Lên lịch di chuyển của bạn",
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
          // Danh sách chuyến xe
          Expanded(
            child: StreamBuilder<List<RideModel>>(
              stream: rideRepo.getPendingRides(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Chưa có chuyến xe nào mới", style: TextStyle(color: Colors.grey)),
                  );
                }

                final rides = snapshot.data!;
                return ListView.builder(
                  // Tăng padding bottom lên 140 để thẻ cuối cùng không bị nút Floating Button che mất
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    return RideCard(ride: rides[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
