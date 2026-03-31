import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/clay_container.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _selectedLocation = const LatLng(10.762622, 106.660172); // Mặc định TP.HCM
  String _address = "Đang lấy địa chỉ...";
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getAddress(_selectedLocation);
    _moveToCurrentLocation(); // Thử tự động lấy vị trí khi vừa mở bản đồ
  }

  Future<void> _getAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = "${place.street ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Không thể lấy địa chỉ";
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí trước
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);
      
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
      setState(() {
        _selectedLocation = newLatLng;
      });
      _getAddress(newLatLng);
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chiều cao của các thanh điều hướng (tai thỏ, home bar)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn vị trí", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'address': _address,
                'lat': _selectedLocation.latitude,
                'lng': _selectedLocation.longitude,
              });
            },
            child: const Text("CHỌN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),
            myLocationEnabled: true, // Hiển thị chấm xanh dương của user
            myLocationButtonEnabled: false, // Ẩn nút mặc định của Google để tự làm UI đẹp hơn
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              setState(() {
                _selectedLocation = position.target;
              });
            },
            onCameraIdle: () {
              _getAddress(_selectedLocation);
            },
          ),
          
          // Ghim mục tiêu (Tâm bản đồ - Claymorphism)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 45, color: Colors.redAccent),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 45), // Nâng khung để tâm ghim khớp đúng điểm
              ],
            ),
          ),
          
          // Nút đưa về vị trí hiện tại
          Positioned(
            right: 16,
            bottom: bottomPadding + 110, // Đẩy nút lên tránh bị UI che
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Thanh hiển thị địa chỉ (Claymorphism style)
          Positioned(
            bottom: bottomPadding + 20, // Đẩy thanh lên cao dựa trên padding thiết bị
            left: 16,
            right: 16,
            child: ClayContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Text(
                _address,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        ],
      ),
    );
  }
}
