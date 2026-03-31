import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../data/models/scheduled_route_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'map_picker_screen.dart';

class CreateScheduledRouteScreen extends StatefulWidget {
  const CreateScheduledRouteScreen({super.key});

  @override
  State<CreateScheduledRouteScreen> createState() => _CreateScheduledRouteScreenState();
}

class _CreateScheduledRouteScreenState extends State<CreateScheduledRouteScreen> {
  // Indigo Theme Colors
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color bgApp = Color(0xFFF4F5F7);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF8F9FA);
  static const Color textLabel = Color(0xFF6B7280);
  static const Color textValue = Color(0xFF1C1C1E);
  static const Color iconPickup = Color(0xFF00B36B);
  static const Color iconDest = Color(0xFFFF3B30);
  static const Color successGreen = Color(0xFF059669);
  static const Color divider = Color(0xFFE5E7EB);

  final _pickupController = TextEditingController();
  final _destController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  String _vehicleType = 'Xe 5 chỗ';
  int _availableSeats = 4;
  double? _pickupLat;
  double? _pickupLng;
  double? _destLat;
  double? _destLng;
  bool _isPremiumFeature = false;

  Timer? _debounce;
  final _dio = Dio();
  
  List _pickupPredictions = [];
  List _destPredictions = [];

  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  final String _goongApiKey = "DTG9XzXVm1lZi9NhVAXtrBREelukL5MhZI9eJvqg";

  final Map<String, int> _vehicleSeats = {
    'Xe 5 chỗ': 4,
    'Xe 7 chỗ': 6,
    'Xe 16 chỗ': 15,
  };

  @override
  void initState() {
    super.initState();
    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus && _pickupController.text.isEmpty) {
        setState(() { _pickupPredictions = [{'is_current': true, 'description': 'Vị trí của tôi'}]; });
      }
    });
    _destFocus.addListener(() {
      if (_destFocus.hasFocus && _destController.text.isEmpty) {
        setState(() { _destPredictions = [{'is_current': true, 'description': 'Vị trí của tôi'}]; });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _destController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _pickupFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, bool isPickup) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.length > 2) {
        _fetchPlacePredictions(query, isPickup);
      } else {
        setState(() {
          if (isPickup) {
            _pickupPredictions = [{'is_current': true, 'description': 'Vị trí của tôi'}];
          } else {
            _destPredictions = [{'is_current': true, 'description': 'Vị trí của tôi'}];
          }
        });
      }
    });
  }

  Future<void> _fetchPlacePredictions(String query, bool isPickup) async {
    try {
      final response = await _dio.get(
        "https://rsapi.goong.io/v2/place/autocomplete",
        queryParameters: {"api_key": _goongApiKey, "input": query},
      );
      if (response.statusCode == 200 && mounted) {
        final predictions = response.data['predictions'] as List;
        final currentText = isPickup ? _pickupController.text : _destController.text;
        if (currentText.trim() == query.trim()) {
          setState(() {
            final List list = [{'is_current': true, 'description': 'Vị trí của tôi'}];
            list.addAll(predictions);
            if (isPickup) { _pickupPredictions = list; } else { _destPredictions = list; }
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _getLatLngFromPlaceId(String placeId, bool isPickup, String fullAddress) async {
    _debounce?.cancel();
    setState(() {
      if (isPickup) { _pickupController.text = fullAddress; _pickupPredictions = []; } 
      else { _destController.text = fullAddress; _destPredictions = []; }
    });
    FocusScope.of(context).unfocus();
    try {
      final response = await _dio.get(
        "https://rsapi.goong.io/v2/place/detail",
        queryParameters: {"api_key": _goongApiKey, "place_id": placeId},
      );
      if (response.statusCode == 200 && mounted) {
        final location = response.data['result']['geometry']['location'];
        setState(() {
          if (isPickup) { _pickupLat = location['lat']; _pickupLng = location['lng']; } 
          else { _destLat = location['lat']; _destLng = location['lng']; }
        });
      }
    } catch (e) {}
  }

  Future<void> _getCurrentLocation(bool isPickup) async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      String address = "Vị trí hiện tại";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address = "${place.street ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}";
      }

      setState(() {
        if (isPickup) {
          _pickupController.text = address;
          _pickupLat = position.latitude;
          _pickupLng = position.longitude;
          _pickupPredictions = [];
        } else {
          _destController.text = address;
          _destLat = position.latitude;
          _destLng = position.longitude;
          _destPredictions = [];
        }
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("Lỗi GPS: $e");
    }
  }

  Future<void> _openMapPicker(bool isPickup) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen()));
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (isPickup) { 
          _pickupController.text = result['address']; 
          _pickupLat = result['lat']; 
          _pickupLng = result['lng']; 
          _pickupPredictions = [];
        } else { 
          _destController.text = result['address']; 
          _destLat = result['lat']; 
          _destLng = result['lng']; 
          _destPredictions = [];
        }
      });
    }
  }

  void _clearAddress(bool isPickup) {
    setState(() {
      if (isPickup) { 
        _pickupController.clear(); 
        _pickupLat = null; 
        _pickupLng = null; 
        _pickupPredictions = []; 
      } else { 
        _destController.clear(); 
        _destLat = null; 
        _destLng = null; 
        _destPredictions = []; 
      }
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN NGÀY ĐI',
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
        builder: (context, child) => Localizations.override(
          context: context, 
          locale: const Locale('vi', 'VN'), 
          child: child,
        ),
      );
      if (time != null) { 
        setState(() { 
          _selectedDate = date; 
          _selectedTime = time; 
        }); 
      }
    }
  }

  void _formatPrice(String value) {
    if (value.isEmpty) return;
    String newValue = value.replaceAll('.', '').replaceAll(',', '');
    int? price = int.tryParse(newValue);
    if (price != null) {
      final formatted = NumberFormat('#,###', 'vi_VN').format(price);
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onVehicleTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _vehicleType = value;
        _availableSeats = _vehicleSeats[value] ?? 4;
      });
    }
  }

  Future<void> _submitRoute() async {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final user = authRepo.currentUser;

    if (_pickupController.text.isEmpty || _destController.text.isEmpty) {
      _showSnackBar("Vui lòng nhập điểm đi và điểm đến!", Colors.red);
      return;
    }

    final now = DateTime.now();
    final departureTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (departureTime.isBefore(now)) {
      _showSnackBar("Thời gian xuất phát phải sau thời điểm hiện tại!", Colors.red);
      return;
    }

    double price = 0;
    final priceText = _priceController.text.replaceAll('.', '').replaceAll(',', '');
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText) ?? 0;
    }

    final route = ScheduledRouteModel(
      id: '',
      pickupPoint: _pickupController.text,
      destinationPoint: _destController.text,
      pickupLat: _pickupLat,
      pickupLng: _pickupLng,
      destLat: _destLat,
      destLng: _destLng,
      departureTime: departureTime,
      vehicleType: _vehicleType,
      availableSeats: _availableSeats,
      price: price,
      notes: _notesController.text,
      isPremiumFeature: _isPremiumFeature,
      creatorId: user?.uid ?? '',
      creatorName: user?.displayName ?? 'Thành viên',
      creatorPhone: user?.phoneNumber ?? '',
      status: 'active',
    );

    await rideRepo.createScheduledRoute(route);
    if (mounted) {
      _showSnackBar("Đã tạo lộ trình thành công!", successGreen);
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: const Text(
          "TẠO LỘ TRÌNH",
          style: TextStyle(
            color: textValue,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: bgApp,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: textValue, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("LỘ TRÌNH"),
                  const SizedBox(height: 12),
                  _buildAddressField(
                    label: "Điểm xuất phát",
                    controller: _pickupController,
                    icon: Icons.trip_origin,
                    iconColor: iconPickup,
                    isPickup: true,
                    focusNode: _pickupFocus,
                  ),
                  _buildPredictions(_pickupPredictions, true),
                  const SizedBox(height: 12),
                  _buildAddressField(
                    label: "Điểm đến",
                    controller: _destController,
                    icon: Icons.place,
                    iconColor: iconDest,
                    isPickup: false,
                    focusNode: _destFocus,
                  ),
                  _buildPredictions(_destPredictions, false),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: divider),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle("THỜI GIAN & PHƯƠNG TIỆN"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVehicleTypeDropdown(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSeatsInfo(),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: divider),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle("GIÁ & GHI CHÚ"),
                  const SizedBox(height: 12),
                  _buildPriceField(),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text(
                  "ĐĂNG LỘ TRÌNH",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        color: textLabel,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required bool isPickup,
    required FocusNode focusNode,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (val) => _onSearchChanged(val, isPickup),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textValue,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 13, color: textLabel),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, color: iconDest, size: 20),
                  onPressed: () => _clearAddress(isPickup),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              IconButton(
                icon: const Icon(Icons.map, color: textLabel, size: 20),
                onPressed: () => _openMapPicker(isPickup),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictions(List predictions, bool isPickup) {
    if (predictions.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: predictions.length,
        itemBuilder: (context, index) {
          final p = predictions[index];
          final isCurrent = p['is_current'] == true;
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Icon(
              isCurrent ? Icons.my_location : Icons.location_on,
              size: 20,
              color: isCurrent ? primaryIndigo : textLabel,
            ),
            title: Text(
              p['description'],
              style: TextStyle(
                fontSize: 14,
                color: isCurrent ? primaryIndigo : textValue,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () {
              if (isCurrent) {
                _getCurrentLocation(isPickup);
              } else {
                _getLatLngFromPlaceId(p['place_id'], isPickup, p['description']);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: primaryIndigo, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Ngày giờ đi",
                    style: TextStyle(fontSize: 11, color: textLabel),
                  ),
                  Text(
                    "${DateFormat('dd/MM/yyyy').format(_selectedDate)} - ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textValue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textLabel, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _vehicleType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: textLabel, size: 20),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textValue,
          ),
          items: _vehicleSeats.keys.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: _onVehicleTypeChanged,
        ),
      ),
    );
  }

  Widget _buildSeatsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_seat, color: primaryIndigo, size: 18),
          const SizedBox(width: 8),
          Text(
            "Số ghế trống: $_availableSeats",
            style: const TextStyle(
              fontSize: 13,
              color: primaryIndigo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _priceController,
        onChanged: _formatPrice,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: successGreen,
        ),
        decoration: const InputDecoration(
          hintText: "Thỏa thuận",
          hintStyle: TextStyle(color: textLabel, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(Icons.payments, color: successGreen, size: 20),
          prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
          suffixText: "VNĐ",
          suffixStyle: TextStyle(color: textLabel, fontSize: 13),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(
          fontSize: 14,
          color: textValue,
        ),
        decoration: const InputDecoration(
          hintText: "Ghi chú thêm (tùy chọn)...",
          hintStyle: TextStyle(color: textLabel, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }
}
