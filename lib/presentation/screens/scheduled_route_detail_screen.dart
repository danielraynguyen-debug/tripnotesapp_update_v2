import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../data/models/scheduled_route_model.dart';
import '../widgets/clay_container.dart';

class ScheduledRouteDetailScreen extends StatefulWidget {
  final ScheduledRouteModel route;

  const ScheduledRouteDetailScreen({super.key, required this.route});

  @override
  State<ScheduledRouteDetailScreen> createState() => _ScheduledRouteDetailScreenState();
}

class _ScheduledRouteDetailScreenState extends State<ScheduledRouteDetailScreen> {
  // Colors
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color bgApp = Color(0xFFF4F5F7);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF8F9FA);
  static const Color textLabel = Color(0xFF6B7280);
  static const Color textValue = Color(0xFF1C1C1E);
  static const Color iconPickup = Color(0xFF00B36B);
  static const Color iconDest = Color(0xFFFF3B30);

  final _customerPickupController = TextEditingController();
  final _dio = Dio();
  final _debounce = Debouncer(milliseconds: 800);
  
  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  List _pickupPredictions = [];
  LatLng? _customerPickupLatLng;
  Marker? _customerPickupMarker;

  final String _goongApiKey = "DTG9XzXVm1lZi9NhVAXtrBREelukL5MhZI9eJvqg";

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _customerPickupController.dispose();
    super.dispose();
  }

  void _initializeMapData() {
    // Add markers for pickup and destination
    if (widget.route.pickupLat != null && widget.route.pickupLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.route.pickupLat!, widget.route.pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Điểm xuất phát'),
        ),
      );
    }
    
    if (widget.route.destLat != null && widget.route.destLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(widget.route.destLat!, widget.route.destLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Điểm đến'),
        ),
      );
    }

    // Fetch route polyline
    _fetchRoutePolyline();
  }

  Future<void> _fetchRoutePolyline() async {
    if (widget.route.pickupLat == null || widget.route.pickupLng == null ||
        widget.route.destLat == null || widget.route.destLng == null) return;

    try {
      final response = await _dio.get(
        "https://rsapi.goong.io/v2/direction",
        queryParameters: {
          "api_key": _goongApiKey,
          "origin": "${widget.route.pickupLat},${widget.route.pickupLng}",
          "destination": "${widget.route.destLat},${widget.route.destLng}",
          "vehicle": "car",
          "optimize": "true",
          "alternatives": "true",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          // Find shortest route by distance
          var shortestRoute = routes[0];
          var minDistance = routes[0]['legs'][0]['distance']['value'] as num;
          
          for (var route in routes) {
            final distance = route['legs'][0]['distance']['value'] as num;
            if (distance < minDistance) {
              minDistance = distance;
              shortestRoute = route;
            }
          }
          
          final overviewPolyline = shortestRoute['overview_polyline']['points'];
          final points = _decodePolyline(overviewPolyline);
          
          setState(() {
            _routePoints = points;
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: primaryIndigo,
                width: 5,
              ),
            );
          });

          // Fit bounds to show the whole route
          _fitBounds();
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy đường đi: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _fitBounds() {
    if (_routePoints.isEmpty || _mapController == null) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }

  void _onCustomerPickupChanged(String query) {
    _debounce.run(() {
      if (query.length > 2) {
        _fetchPlacePredictions(query);
      } else {
        setState(() => _pickupPredictions = []);
      }
    });
  }

  Future<void> _fetchPlacePredictions(String query) async {
    try {
      final response = await _dio.get(
        "https://rsapi.goong.io/v2/place/autocomplete",
        queryParameters: {"api_key": _goongApiKey, "input": query},
      );
      if (response.statusCode == 200 && mounted) {
        final predictions = response.data['predictions'] as List;
        if (_customerPickupController.text.trim() == query.trim()) {
          setState(() => _pickupPredictions = predictions);
        }
      }
    } catch (e) {}
  }

  Future<void> _selectCustomerPickup(String placeId, String description) async {
    setState(() {
      _customerPickupController.text = description;
      _pickupPredictions = [];
    });

    try {
      final response = await _dio.get(
        "https://rsapi.goong.io/v2/place/detail",
        queryParameters: {"api_key": _goongApiKey, "place_id": placeId},
      );
      if (response.statusCode == 200 && mounted) {
        final location = response.data['result']['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        
        setState(() {
          _customerPickupLatLng = LatLng(lat, lng);
          
          // Remove old marker if exists
          if (_customerPickupMarker != null) {
            _markers.remove(_customerPickupMarker);
          }
          
          // Add new marker
          _customerPickupMarker = Marker(
            markerId: const MarkerId('customer_pickup'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: const InfoWindow(title: 'Điểm đón khách'),
          );
          _markers.add(_customerPickupMarker!);
        });

        // Move camera to customer pickup location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(widget.route.departureTime);
    final dateStr = DateFormat('EEEE, dd/MM', 'vi').format(widget.route.departureTime);

    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // Header with route info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgCard,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: textValue),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      const Expanded(
                        child: Text(
                          "Thông tin lộ trình",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: textValue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Time badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: primaryIndigo),
                            const SizedBox(width: 4),
                            Text(
                              "$timeStr - $dateStr",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                          color: bgInput,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.route.vehicleType,
                          style: const TextStyle(fontSize: 12, color: textLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Route points - New design matching reference image
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side icons column
                      Column(
                        children: [
                          // Origin blue circle
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: primaryIndigo,
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
                          // Dotted line
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            height: 60,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                6,
                                (index) => Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: textLabel.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Destination red pin
                          const Icon(
                            Icons.location_on,
                            color: iconDest,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Right side addresses
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Origin address
                            Text(
                              widget.route.pickupPoint,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textValue,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Distance badge
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Cách bạn ${widget.route.distance}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            // Destination address
                            Text(
                              widget.route.destinationPoint,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textValue,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.route.pickupLat != null && widget.route.pickupLng != null
                      ? LatLng(widget.route.pickupLat!, widget.route.pickupLng!)
                      : const LatLng(10.762622, 106.660172),
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_routePoints.isNotEmpty) {
                    _fitBounds();
                  }
                },
              ),
            ),

            // Bottom section - Customer pickup input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgCard,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price and seats info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_seat, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.route.availableSeats} ghế trống",
                              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.route.formattedPrice,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.route.price > 0 ? Colors.green[700] : textLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Customer pickup input
                  ClayContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: bgInput,
                    child: TextField(
                      controller: _customerPickupController,
                      onChanged: _onCustomerPickupChanged,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textValue,
                      ),
                      decoration: InputDecoration(
                        hintText: "Nhập điểm đón khách...",
                        hintStyle: const TextStyle(fontSize: 13, color: textLabel),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.location_searching, color: primaryIndigo, size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        suffixIcon: _customerPickupController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: textLabel, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _customerPickupController.clear();
                                    _pickupPredictions = [];
                                    if (_customerPickupMarker != null) {
                                      _markers.remove(_customerPickupMarker);
                                      _customerPickupMarker = null;
                                    }
                                  });
                                },
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              )
                            : null,
                      ),
                    ),
                  ),
                  
                  // Predictions list
                  if (_pickupPredictions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _pickupPredictions.length,
                        itemBuilder: (context, index) {
                          final p = _pickupPredictions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.location_on, size: 18, color: primaryIndigo),
                            title: Text(
                              p['description'],
                              style: const TextStyle(fontSize: 13, color: textValue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectCustomerPickup(p['place_id'], p['description']),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Đóng"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textLabel,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // TODO: Implement booking/request logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đã gửi yêu cầu tham gia lộ trình!"),
                                backgroundColor: primaryIndigo,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Tham gia"),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for debouncing
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
