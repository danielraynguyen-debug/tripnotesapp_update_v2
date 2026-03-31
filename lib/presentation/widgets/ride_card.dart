import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ride_model.dart';
import '../screens/ride_detail_screen.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  const RideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    // Premium clean design colors
    const Color cardBgColor = Color(0xFFFFFFFF); // White
    const Color textPrimary = Color(0xFF1E293B); // Dark blue-black
    const Color textSecondary = Color(0xFF64748B); // Slate gray
    const Color shadowColor = Color(0xFF4F46E5); // Indigo

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.05),
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DateFormat('HH:mm - dd/MM').format(ride.dateTime),
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(ride.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Route info - Premium design with full addresses
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
                                  (index) => Container(
                                    width: 2,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: textSecondary.withOpacity(0.3),
                                      shape: BoxShape.circle,
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
                        // Right side addresses - Full text with premium colors
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Origin address
                              Text(
                                "Điểm đón",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                ride.pickupPoint,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Destination address
                              Text(
                                "Điểm đến",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                ride.destinationPoint,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
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
                    Row(
                      children: [
                        Icon(Icons.route, size: 16, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          "Khoảng cách: ${ride.distance}",
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ride.type == 'round_trip' ? Colors.purple[100] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ride.type == 'round_trip' ? Icons.swap_calls : Icons.arrow_forward,
                                size: 14,
                                color: ride.type == 'round_trip' ? Colors.purple[700] : Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ride.type == 'round_trip' ? 'Khứ hồi' : '1 chiều',
                                style: TextStyle(
                                  color: ride.type == 'round_trip' ? Colors.purple[700] : Colors.blue[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
