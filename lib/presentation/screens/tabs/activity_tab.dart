import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../data/models/ride_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/ride_repository.dart';
import '../../widgets/clay_container.dart';
import 'package:intl/intl.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({Key? key}) : super(key: ActivityTab.activityKey);

  static final GlobalKey<_ActivityTabState> activityKey = GlobalKey<_ActivityTabState>();

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Position>? _positionStream;
  final Set<String> _arrivedAtPickup = {};
  final Set<String> _arrivedAtDestForRoundTrip = {};
  
  // Biến quản lý Filter của tab Quản lý ghi chú
  String _historyFilter = 'all'; // 'all', 'mine', 'completed'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startLocationTracking();
  }

  void setTabIndex(int index) {
    _tabController.animateTo(index);
  }

  void _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen((Position position) {
      _checkArrival(position);
    });
  }

  void _checkArrival(Position position) async {
    if (!mounted) return;
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final driverId = authRepo.currentUser?.uid;
    
    if (driverId == null) return;

    final snapshot = await rideRepo.getOngoingRides(driverId).first;
    for (var ride in snapshot) {
      if (ride.pickupLat != null && ride.pickupLng != null) {
        double distanceToPickup = Geolocator.distanceBetween(
          position.latitude, position.longitude, ride.pickupLat!, ride.pickupLng!
        );
        if (distanceToPickup <= 200) {
          if (!_arrivedAtPickup.contains(ride.id)) {
            setState(() {
              _arrivedAtPickup.add(ride.id);
            });
          }
        }
      }

      if (ride.destLat != null && ride.destLng != null) {
        double distanceToDest = Geolocator.distanceBetween(
          position.latitude, position.longitude, ride.destLat!, ride.destLng!
        );
        
        if (distanceToDest <= 500) {
          if (ride.type == 'round_trip') {
            if (!_arrivedAtDestForRoundTrip.contains(ride.id)) {
              setState(() {
                _arrivedAtDestForRoundTrip.add(ride.id);
              });
            }
          } else {
            await rideRepo.completeRide(ride.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Chuyến xe đến ${ride.destinationPoint} đã hoàn thành!")),
              );
            }
          }
        }
      }
      
      if (ride.type == 'round_trip' && _arrivedAtDestForRoundTrip.contains(ride.id)) {
        double distanceBackToPickup = Geolocator.distanceBetween(
          position.latitude, position.longitude, ride.pickupLat!, ride.pickupLng!
        );
        if (distanceBackToPickup <= 500) {
          await rideRepo.completeRide(ride.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chuyến xe khứ hồi đã hoàn thành!")),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("HOẠT ĐỘNG", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Đang diễn ra"),
            Tab(text: "Quản lý ghi chú"), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOngoingList(),
          _buildManageNotesList(), 
        ],
      ),
    );
  }

  Widget _buildOngoingList() {
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final userId = authRepo.currentUser?.uid ?? "";

    return StreamBuilder<List<RideModel>>(
      stream: rideRepo.getActiveRidesForUser(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có chuyến xe nào đang thực hiện"));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140), 
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildOngoingCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildOngoingCard(RideModel ride) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final currentUserId = authRepo.currentUser?.uid;
    
    final bool isDriver = currentUserId == ride.driverId;
    final bool isCreator = currentUserId == ride.creatorId;
    final bool isRoundTrip = ride.type == 'round_trip';
    final bool hasReachedDest = _arrivedAtDestForRoundTrip.contains(ride.id);

    final bool showPickupNav = isDriver && !_arrivedAtPickup.contains(ride.id) && ride.pickupLat != null;
    final bool showReturnNav = isDriver && isRoundTrip && hasReachedDest;

    // Modern Clean & Indigo Accent colors
    const Color cardBgColor = Color(0xFFFFFFFF);
    const Color headerBgColor = Color(0xFFF8FAFC);
    const Color textPrimary = Color(0xFF1E293B);
    const Color textSecondary = Color(0xFF64748B);
    const Color indigoColor = Color(0xFF4F46E5);
    const Color indigoLight = Color(0xFFE0E7FF);
    const Color indigoWhite = Color(0xFFEEF2FF);
    const Color emeraldColor = Color(0xFF059669);
    const Color dividerColor = Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: indigoColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header with customer info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: headerBgColor,
                  border: Border(
                    bottom: BorderSide(color: dividerColor, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCreator ? "Người nhận: ${ride.driverName ?? '...'}" : "Khách hàng: ******",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isRoundTrip ? indigoLight : indigoLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isRoundTrip ? "Khứ hồi" : "1 chiều",
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: indigoColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(ride.price),
                          style: const TextStyle(color: emeraldColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(ride.distance, style: const TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Creator info with vertical divider
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isCreator ? "Bạn là người đăng" : "Tạo bởi", 
                                  style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
                                Text(
                                  ride.creatorName ?? 'Thành viên', 
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCreator) ...[
                      const SizedBox(width: 8),
                      const VerticalDivider(width: 1, color: indigoLight, thickness: 2),
                      const SizedBox(width: 8),
                      _buildSmallCallButton("Gọi người đăng", () async {
                        if (ride.creatorPhone != null) {
                          await launchUrl(Uri(scheme: 'tel', path: ride.creatorPhone));
                        }
                      }),
                    ],
                  ],
                ),
              ),

              // Route info section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Divider(height: 1, color: dividerColor),
                    const SizedBox(height: 16),
                    // Route info with white background icons
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left icons column
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
                            // Dotted line - Slate gray
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
                                        color: Color(0xFFCBD5E1),
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
                        // Right side addresses
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Điểm đón",
                                style: TextStyle(color: textSecondary, fontSize: 11),
                              ),
                              Text(
                                ride.pickupPoint,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Điểm đến",
                                style: TextStyle(color: textSecondary, fontSize: 11),
                              ),
                              Text(
                                ride.destinationPoint,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: indigoWhite,
                  border: Border(
                    top: BorderSide(color: dividerColor, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isDriver) ...[
                      _buildActionButton(Icons.phone, "Gọi khách", indigoColor, () async {
                        await launchUrl(Uri(scheme: 'tel', path: ride.customerPhone));
                      }),
                      if (showPickupNav)
                        _buildActionButton(Icons.directions_car, "Đón khách", Colors.orange[700]!, () async {
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=${ride.pickupLat},${ride.pickupLng}';
                          await launchUrl(Uri.parse(url));
                        }),
                      _buildActionButton(
                        showReturnNav ? Icons.keyboard_return : Icons.navigation, 
                        showReturnNav ? "Đường về" : "Đường đến", 
                        indigoColor, 
                        () async {
                          String destination = showReturnNav ? "${ride.pickupLat},${ride.pickupLng}" : ride.destinationPoint;
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=$destination';
                          await launchUrl(Uri.parse(url));
                        }
                      ),
                    ],
                    // Cancel button - Outlined style like "Quay lại"
                    OutlinedButton.icon(
                      onPressed: () {
                        if (isDriver && isRoundTrip && hasReachedDest) {
                          _showConvertToOneWayDialog(ride);
                        } else {
                          rideRepo.cancelRide(ride.id, currentUserId!);
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        "Hủy",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.05),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCallButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF), 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 14, color: Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showConvertToOneWayDialog(RideModel ride) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final priceController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chuyển thành chuyến 1 chiều mới", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Lượt về của chuyến khứ hồi sẽ được đăng thành chuyến 1 chiều mới trên Trang chủ.", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Giá tiền mới (VNĐ)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isNotEmpty) {
                final double newPrice = double.tryParse(priceController.text) ?? 0;
                String newDistance = "0 km";
                try {
                  double totalKm = double.parse(ride.distance.replaceAll(RegExp(r'[^0-9.]'), ''));
                  newDistance = "${(totalKm / 2).toStringAsFixed(1)} km";
                } catch (e) {}

                final newRide = RideModel(
                  id: '',
                  customerPhone: ride.customerPhone,
                  pickupPoint: ride.destinationPoint,
                  destinationPoint: ride.pickupPoint,
                  dateTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute),
                  price: newPrice,
                  distance: newDistance,
                  status: 'pending',
                  type: 'one_way',
                  pickupLat: ride.destLat,
                  pickupLng: ride.destLng,
                  destLat: ride.pickupLat,
                  destLng: ride.pickupLng,
                  creatorId: ride.creatorId,
                  creatorName: ride.creatorName,
                  creatorPhone: ride.creatorPhone,
                  createdAt: DateTime.now(),
                );

                await rideRepo.createRide(newRide);
                await rideRepo.cancelRide(ride.id, ride.driverId!); 
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đăng lượt về thành chuyến 1 chiều mới!")));
                }
              }
            },
            child: const Text("Xác nhận đăng"),
          )
        ],
      ),
    );
  }

  Widget _buildManageNotesList() {
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final userId = authRepo.currentUser?.uid ?? "";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterPill('Tất cả', 'all'),
              _buildFilterPill('Ghi chú của tôi', 'mine'),
              _buildFilterPill('Đã hoàn thành', 'completed'),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<List<RideModel>>(
            stream: rideRepo.getAllRidesForUser(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Chưa có ghi chú nào"));
              }

              List<RideModel> filteredRides = snapshot.data!.where((ride) {
                if (_historyFilter == 'mine') {
                  return ride.creatorId == userId;
                } else if (_historyFilter == 'completed') {
                  return ride.status == 'completed';
                }
                return true;
              }).toList();

              if (filteredRides.isEmpty) {
                return const Center(child: Text("Không tìm thấy ghi chú phù hợp"));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 200), // Increased padding to clear FAB
                itemCount: filteredRides.length,
                itemBuilder: (context, index) => _buildManageNoteCard(filteredRides[index], userId),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String text, String value) {
    final isSelected = _historyFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _historyFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
          boxShadow: isSelected 
            ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildManageNoteCard(RideModel ride, String currentUserId) {
    // Modern Glass & Indigo colors
    const Color cardBgColor = Color(0xFFFFFFFF);
    const Color headerBgColor = Color(0xFFF8FAFC);
    const Color textPrimary = Color(0xFF1E293B);
    const Color textSecondary = Color(0xFF64748B);
    const Color indigoColor = Color(0xFF4F46E5);
    const Color indigoLight = Color(0xFFE0E7FF);
    const Color emeraldColor = Color(0xFF059669);
    const Color dividerColor = Color(0xFFF1F5F9);
    const Color redSlate = Color(0xFFEF4444);

    // Status chip colors
    Color statusBgColor;
    Color statusTextColor;
    String statusText;
    
    if (ride.status == 'pending') {
      statusBgColor = indigoLight;
      statusTextColor = indigoColor;
      statusText = "Đang chờ";
    } else if (ride.status == 'ongoing') {
      statusBgColor = const Color(0xFFDBEAFE);
      statusTextColor = const Color(0xFF2563EB);
      statusText = "Đang thực hiện";
    } else if (ride.status == 'completed') {
      statusBgColor = const Color(0xFFD1FAE5);
      statusTextColor = emeraldColor;
      statusText = "Hoàn thành";
    } else {
      statusBgColor = const Color(0xFFF3F4F6);
      statusTextColor = textSecondary;
      statusText = "Đang chờ";
    }

    final isCreator = ride.creatorId == currentUserId;
    final isCompleted = ride.status == 'completed';
    final formattedTime = DateFormat('HH:mm - dd/MM/yyyy').format(ride.dateTime);

    // History (completed) cards have reduced opacity for faded look
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF8FAFC) : cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isCompleted 
              ? indigoColor.withOpacity(0.02) 
              : indigoColor.withOpacity(0.04),
            blurRadius: isCompleted ? 12 : 16,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: isCompleted 
          ? Border.all(color: const Color(0xFFD1FAE5), width: 1)
          : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with user info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFECFDF5) : headerBgColor,
                border: Border(
                  bottom: BorderSide(
                    color: isCompleted ? const Color(0xFFA7F3D0) : dividerColor, 
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCreator ? Icons.person_pin : Icons.person_outline, 
                        size: 16, 
                        color: isCreator 
                          ? (isCompleted ? emeraldColor.withOpacity(0.7) : indigoColor)
                          : (isCompleted ? textSecondary.withOpacity(0.6) : textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ride.creatorName ?? "Ẩn danh",
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 13,
                          color: isCreator 
                            ? (isCompleted ? emeraldColor.withOpacity(0.8) : indigoColor)
                            : (isCompleted ? textSecondary.withOpacity(0.7) : textPrimary),
                        ),
                      ),
                    ],
                  ),
                  // Status Chip with check icon for completed
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          Icon(Icons.check_circle, size: 12, color: statusTextColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          statusText, 
                          style: TextStyle(
                            color: statusTextColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content body - reduced padding for completed
            Padding(
              padding: EdgeInsets.all(isCompleted ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.schedule, 
                        size: 14, 
                        color: isCompleted ? textSecondary.withOpacity(0.6) : textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime, 
                        style: TextStyle(
                          fontSize: 12, 
                          color: isCompleted ? textSecondary.withOpacity(0.7) : textSecondary, 
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1, 
                    color: isCompleted ? dividerColor.withOpacity(0.5) : dividerColor,
                  ),
                  const SizedBox(height: 12),
                  
                  // Route info with white background icons and dotted line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left icons column
                      Column(
                        children: [
                          // Origin blue circle - muted for completed
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                ? Colors.blue[300] 
                                : Colors.blue[700],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          // Dotted line - muted for completed
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            height: 32,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                4,
                                (index) => SizedBox(
                                  width: 2,
                                  height: 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: isCompleted 
                                        ? const Color(0xFFCBD5E1).withOpacity(0.5)
                                        : const Color(0xFFCBD5E1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Destination red circle - muted for completed
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                ? Colors.red[300] 
                                : Colors.red[700],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 5,
                                height: 5,
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
                      // Right side addresses
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Điểm đón",
                              style: TextStyle(
                                color: isCompleted ? textSecondary.withOpacity(0.6) : textSecondary, 
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              ride.pickupPoint,
                              style: TextStyle(
                                fontWeight: FontWeight.w600, 
                                fontSize: 12, 
                                color: isCompleted ? textSecondary.withOpacity(0.8) : textPrimary, 
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Điểm đến",
                              style: TextStyle(
                                color: isCompleted ? textSecondary.withOpacity(0.6) : textSecondary, 
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              ride.destinationPoint,
                              style: TextStyle(
                                fontWeight: FontWeight.w600, 
                                fontSize: 12, 
                                color: isCompleted ? textSecondary.withOpacity(0.8) : textPrimary, 
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  // Distance, type and Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted 
                            ? const Color(0xFFF1F5F9).withOpacity(0.7)
                            : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${ride.distance} • ${ride.type == 'round_trip' ? 'Khứ hồi' : '1 chiều'}", 
                          style: TextStyle(
                            color: isCompleted ? textSecondary.withOpacity(0.7) : textSecondary, 
                            fontSize: 11, 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(ride.price), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15, 
                          color: isCompleted ? emeraldColor.withOpacity(0.8) : emeraldColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Delete button (only for creator with pending status)
            if (isCreator && ride.status == 'pending')
              Container(
                padding: const EdgeInsets.only(right: 12, bottom: 12),
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _showDeleteConfirmDialog(ride),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: redSlate.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline, 
                      color: redSlate, 
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap completed cards with Opacity for faded History look
    if (isCompleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Opacity(
          opacity: 0.75,
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: cardContent,
    );
  }

  void _showDeleteConfirmDialog(RideModel ride) {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 48),
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa ghi chú \"${ride.pickupPoint} → ${ride.destinationPoint}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton.icon(
            onPressed: () async {
              await rideRepo.deleteRide(ride.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã xóa ghi chú thành công!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text("XÓA"),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label, 
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
