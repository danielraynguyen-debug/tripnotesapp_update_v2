import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _completePhoneNumber = '';
  bool _isValid = false;

  String _sanitizePhoneNumber(String phone) {
    String sanitized = phone.replaceAll(RegExp(r'\s+'), '');
    if (sanitized.startsWith('+840')) {
      sanitized = '+84${sanitized.substring(4)}';
    }
    return sanitized;
  }

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo cho phong cách Claymorphism (thường là màu Pastel)
    final Color primaryColor = const Color(0xFF7B66FF); // Tím hiện đại
    final Color bgColor = const Color(0xFFF2F9F8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Welcome Back", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSentState) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(verificationId: state.verificationId)));
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              children: [
                // Hình minh họa 3D giả lập
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phonelink_ring_rounded, size: 80, color: primaryColor),
                ),
                const SizedBox(height: 40),

                // Card chứa Input theo phong cách Claymorphism
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      // Đổ bóng ngoài (Outer Shadow)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(10, 10),
                        blurRadius: 20,
                      ),
                      // Đổ bóng trong giả lập (Inner Shadow - đặc trưng Clay)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        offset: const Offset(-5, -5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("Đăng nhập số điện thoại", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54)),
                      const SizedBox(height: 25),
                      // Thay thế đoạn IntlPhoneField cũ bằng code này:
                      IntlPhoneField(
                        initialCountryCode: 'VN',
                        countries: const [
                          Country(
                            name: "Vietnam",
                            flag: "🇻🇳",
                            code: "VN",
                            dialCode: "84",
                            minLength: 9,
                            maxLength: 10,
                            nameTranslations: {"en": "Vietnam", "vn": "Việt Nam"},
                          ),
                        ],
                        dropdownIconPosition: IconPosition.trailing,
                        textAlignVertical: TextAlignVertical.center,
                        // Tùy chỉnh Style cho chữ nhập vào
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại...',
                          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.normal),
                          filled: true,
                          fillColor: bgColor, // Màu nền lún xuống

                          // 1. Viền khi ở trạng thái bình thường
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white, width: 2), // Viền trắng tạo độ nổi
                          ),

                          // 2. Viền khi nhấn vào (Highlight)
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 2),
                          ),

                          // 3. Thêm biểu tượng điện thoại ở đầu để định hướng
                          prefixIcon: Icon(Icons.phone_android_rounded, color: primaryColor),

                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

                          // Hiệu ứng đổ bóng nhẹ ngay trên Input
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                        onChanged: (phone) {
                          setState(() {
                            _completePhoneNumber = phone.completeNumber;
                            final digitsOnly = phone.number.replaceAll(RegExp(r'\D'), '');
                            _isValid = (digitsOnly.length == 9 || digitsOnly.length == 10);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Nút bấm Claymorphism
                GestureDetector(
                  onTap: (_isValid && state is! AuthLoading)
                      ? () => context.read<AuthBloc>().add(SendOtpEvent(_sanitizePhoneNumber(_completePhoneNumber)))
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 60,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isValid ? primaryColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: _isValid ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                        ),
                        // Hiệu ứng sáng cạnh trên (Top highlight)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          offset: const Offset(-4, -4),
                          blurRadius: 10,
                        ),
                      ] : [],
                    ),
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "GỬI MÃ OTP",
                      style: TextStyle(
                        color: _isValid ? Colors.white : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}