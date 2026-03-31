import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../screens/map_picker_screen.dart';

class CreateRideDialog extends StatefulWidget {
  final RideModel? editRide;

  const CreateRideDialog({super.key, this.editRide});

  @override
  State<CreateRideDialog> createState() => _CreateRideDialogState();
}

class _CreateRideDialogState extends State<CreateRideDialog> {
  // Modern Glass & Indigo Colors
  static const Color bgApp = Color(0xFFF8FAFC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgInput = Color(0xFFF1F5F9);
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFF6366F1);
  
  // Text Colors
  static const Color textLabel = Color(0xFF64748B);
  static const Color textValue = Color(0xFF1E293B);
  static const Color textSection = Color(0xFF94A3B8);
  
  // Functional Colors
  static const Color iconPickup = Color(0xFF00B36B);
  static const Color iconDest = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color slateLine = Color(0xFFCBD5E1);

  final _phoneController = TextEditingController();
  final _pickupController = TextEditingController();
  final _destController = TextEditingController();
  final _priceController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  String _distanceStr = "0 km";
  double _rawDistance = 0;
  double? _pickupLat;
  double? _pickupLng;
  double? _destLat;
  double? _destLng;
  
  String _tripType = "one_way"; 
  
  Timer? _debounce;
  final _dio = Dio();
  
  List _pickupPredictions = [];
  List _destPredictions = [];

  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  final String _goongApiKey = "DTG9XzXVm1lZi9NhVAXtrBREelukL5MhZI9eJvqg";

  @override
  void initState() {
    super.initState();
    if (widget.editRide != null) {
      final ride = widget.editRide!;
      _phoneController.text = ride.customerPhone;
      _pickupController.text = ride.pickupPoint;
      _destController.text = ride.destinationPoint;
      _priceController.text = NumberFormat('#,###').format(ride.price);
      _selectedDate = ride.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(ride.dateTime);
      _tripType = ride.type;
      _distanceStr = ride.distance;
      _pickupLat = ride.pickupLat;
      _pickupLng = ride.pickupLng;
      _destLat = ride.destLat;
      _destLng = ride.destLng;
      
      try {
        _rawDistance = double.parse(ride.distance.split(' ')[0]);
        if (_tripType == 'round_trip') _rawDistance /= 2;
      } catch(e) {}
    }

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
    _phoneController.dispose();
    _pickupController.dispose();
    _destController.dispose();
    _priceController.dispose();
    _pickupFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.permissions.request(PermissionType.read) == PermissionStatus.granted) {
      final id = await FlutterContacts.native.showPicker();
      if (id != null) {
        final contact = await FlutterContacts.get(id, properties: {ContactProperty.phone});
        if (contact != null && contact.phones.isNotEmpty) {
          String phone = contact.phones.first.number.replaceAll(RegExp(r'\D'), '');
          if (phone.startsWith('84')) phone = '0' + phone.substring(2);
          if (phone.length > 10) phone = phone.substring(phone.length - 10);
          setState(() { _phoneController.text = phone; });
        }
      }
    }
  }

  void _formatPrice(String value) {
    if (value.isEmpty) return;
    String newValue = value.replaceAll(',', '');
    int? price = int.tryParse(newValue);
    if (price != null) {
      final formatted = NumberFormat('#,###').format(price);
      _priceController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
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
      _calculateDistance();
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("Lỗi GPS: $e");
    }
  }

  void _onSearchChanged(String query, bool isPickup) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
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
    setState(() {});
  }

  Future<void> _fetchPlacePredictions(String query, bool isPickup) async {
    try {
      final response = await _dio.get(
        "https://rsapi.goong.io/v2/place/autocomplete",
        queryParameters: { "api_key": _goongApiKey, "input": query },
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
      final response = await _dio.get("https://rsapi.goong.io/v2/place/detail", queryParameters: {"api_key": _goongApiKey, "place_id": placeId});
      if (response.statusCode == 200 && mounted) {
        final location = response.data['result']['geometry']['location'];
        setState(() {
          if (isPickup) { _pickupLat = location['lat']; _pickupLng = location['lng']; } 
          else { _destLat = location['lat']; _destLng = location['lng']; }
        });
        _calculateDistance();
      }
    } catch (e) {}
  }

  Future<void> _calculateDistance() async {
    if (_pickupLat != null && _pickupLng != null && _destLat != null && _destLng != null) {
      try {
        final response = await _dio.get(
          "https://rsapi.goong.io/v2/distancematrix",
          queryParameters: {"api_key": _goongApiKey, "origins": "$_pickupLat,$_pickupLng", "destinations": "$_destLat,$_destLng", "vehicle": "car"},
        );
        if (response.statusCode == 200) {
          final element = response.data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            setState(() {
              _rawDistance = (element['distance']['value'] as num).toDouble() / 1000.0;
              _updateDistanceDisplay();
            });
          }
        }
      } catch (e) {}
    } else {
      setState(() { _rawDistance = 0; _updateDistanceDisplay(); });
    }
  }

  void _updateDistanceDisplay() {
    double totalKm = _tripType == "round_trip" ? _rawDistance * 2 : _rawDistance;
    setState(() { _distanceStr = "${totalKm.toStringAsFixed(1)} km"; });
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
        builder: (context, child) => Localizations.override(context: context, locale: const Locale('vi', 'VN'), child: child),
      );
      if (time != null) { setState(() { _selectedDate = date; _selectedTime = time; }); }
    }
  }

  Future<void> _openMapPicker(bool isPickup) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen()));
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (isPickup) { _pickupController.text = result['address']; _pickupLat = result['lat']; _pickupLng = result['lng']; } 
        else { _destController.text = result['address']; _destLat = result['lat']; _destLng = result['lng']; }
      });
      _calculateDistance();
    }
  }

  void _clearAddress(bool isPickup) {
    setState(() {
      if (isPickup) { _pickupController.clear(); _pickupLat = null; _pickupLng = null; _pickupPredictions = []; } 
      else { _destController.clear(); _destLat = null; _destLng = null; _destPredictions = []; }
      _calculateDistance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editRide != null;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: Text(
          isEditing ? "SỬA GHI CHÚ" : "TẠO GHI CHÚ MỚI",
          style: const TextStyle(
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
            // Card Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryIndigo.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === LỘ TRÌNH ===
                  _buildSectionTitle("LỘ TRÌNH"),
                  const SizedBox(height: 16),
                  // Route timeline with dotted line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Icons column
                      Column(
                        children: [
                          // Pickup icon
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: iconPickup,
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
                            height: 48,
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
                          // Destination icon
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: iconDest,
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
                      // Right side - Address fields
                      Expanded(
                        child: Column(
                          children: [
                            _buildAddressField(
                              label: "Điểm đón",
                              controller: _pickupController,
                              isPickup: true,
                              focusNode: _pickupFocus,
                            ),
                            _buildInlinePredictions(_pickupPredictions, true),
                            const SizedBox(height: 8),
                            _buildAddressField(
                              label: "Điểm đến",
                              controller: _destController,
                              isPickup: false,
                              focusNode: _destFocus,
                            ),
                            _buildInlinePredictions(_destPredictions, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Distance display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.route, color: primaryIndigo, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "$_distanceStr${_tripType == 'round_trip' ? ' (khứ hồi)' : ''}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: primaryIndigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: divider),
                  const SizedBox(height: 24),

                  // === THỜI GIAN & LOẠI CHUYẾN ===
                  _buildSectionTitle("THỜI GIAN & LOẠI CHUYẾN"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTripTypeDropdown(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: divider),
                  const SizedBox(height: 24),

                  // === LIÊN HỆ & CHI PHÍ ===
                  _buildSectionTitle("LIÊN HỆ & CHI PHÍ"),
                  const SizedBox(height: 12),
                  _buildPhoneField(),
                  const SizedBox(height: 12),
                  _buildPriceField(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // CTA Buttons Row
            Row(
              children: [
                // Back Button - Outlined
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryIndigo,
                        side: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        "Quay lại",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit Button - Gradient
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4F46E5).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(
                          isEditing ? "CẬP NHẬT" : "ĐĂNG GHI CHÚ",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildDateTimePicker() {
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
                    "${DateFormat('dd/MM/yyyy').format(_selectedDate)} - ${_selectedTime.format(context)}",
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

  Widget _buildPhoneField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _phoneController,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textValue,
        ),
        decoration: InputDecoration(
          hintText: "SĐT khách (10 số)",
          hintStyle: const TextStyle(color: textLabel, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: const Icon(Icons.phone_android, color: primaryIndigo, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: IconButton(
            icon: const Icon(Icons.contact_phone, color: primaryIndigo, size: 20),
            onPressed: _pickContact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        keyboardType: TextInputType.phone,
        maxLength: 10,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      ),
    );
  }

  Widget _buildTripTypeDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tripType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: textLabel, size: 20),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: primaryIndigo,
          ),
          items: const [
            DropdownMenuItem(
              value: "one_way",
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: primaryIndigo),
                  SizedBox(width: 8),
                  Text("1 chiều"),
                ],
              ),
            ),
            DropdownMenuItem(
              value: "round_trip",
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: primaryIndigo),
                  SizedBox(width: 8),
                  Text("Khứ hồi"),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _tripType = val!;
              _updateDistanceDisplay();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDistanceDisplay() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: textSection, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Khoảng cách",
                  style: TextStyle(
                    fontSize: 13,
                    color: textLabel,
                    height: 1.23,
                  ),
                ),
                Text(
                  _distanceStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textValue,
                    height: 1.33,
                  ),
                ),
              ],
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
          hintText: "Giá tiền (VNĐ)",
          hintStyle: TextStyle(color: textLabel, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(Icons.payments, color: successGreen, size: 20),
          prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required TextEditingController controller,
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
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: iconDest, size: 20),
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

  Widget _buildInlinePredictions(List predictions, bool isPickup) {
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

  void _submitRide() async {
    final rideRepo = RepositoryProvider.of<RideRepository>(context);
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final user = authRepo.currentUser;
    final finalDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    if (finalDateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn thời gian ở hiện tại hoặc tương lai!"),
          backgroundColor: iconDest,
        ),
      );
      return;
    }
    double price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    final rideData = RideModel(
      id: widget.editRide?.id ?? '',
      customerPhone: _phoneController.text,
      pickupPoint: _pickupController.text,
      destinationPoint: _destController.text,
      dateTime: finalDateTime,
      price: price,
      distance: _distanceStr,
      status: widget.editRide?.status ?? 'pending',
      type: _tripType,
      pickupLat: _pickupLat,
      pickupLng: _pickupLng,
      destLat: _destLat,
      destLng: _destLng,
      creatorId: widget.editRide?.creatorId ?? user?.uid,
      creatorName: widget.editRide?.creatorName ?? user?.displayName ?? 'Thành viên',
      creatorPhone: widget.editRide?.creatorPhone ?? user?.phoneNumber ?? '',
      createdAt: widget.editRide?.createdAt ?? DateTime.now(),
    );
    if (widget.editRide != null) { await rideRepo.updateRide(rideData); } 
    else { await rideRepo.createRide(rideData); }
    if (mounted) Navigator.pop(context);
  }
}
