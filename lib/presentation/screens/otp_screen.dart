import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'home_screen.dart';
import 'register_info_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final Color primaryColor = const Color(0xFF7B66FF);
  final Color bgColor = const Color(0xFFF2F9F8);

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(fontSize: 22, color: primaryColor, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Xác thực", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            // Thay `const HomeScreen()` bằng `HomeScreen()`
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen()), (route) => false);
          } else if (state is NewUserRequiredState) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterInfoScreen()));
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(8, 8), blurRadius: 15),
                      BoxShadow(color: Colors.white, offset: const Offset(-8, -8), blurRadius: 15),
                    ],
                  ),
                  child: Icon(Icons.security_rounded, size: 60, color: primaryColor),
                ),
                const SizedBox(height: 30),
                const Text("Mã xác thực", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  "Nhập mã OTP vừa được gửi đến điện thoại",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(10, 10), blurRadius: 20),
                    ],
                  ),
                  child: Pinput(
                    length: 6,
                    controller: _otpController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: primaryColor, width: 2),
                      ),
                    ),
                    onCompleted: (pin) {
                      context.read<AuthBloc>().add(VerifyOtpEvent(widget.verificationId, pin));
                    },
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: (state is! AuthLoading)
                      ? () => context.read<AuthBloc>().add(VerifyOtpEvent(widget.verificationId, _otpController.text))
                      : null,
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.4), offset: const Offset(0, 8), blurRadius: 15),
                        BoxShadow(color: Colors.white.withOpacity(0.2), offset: const Offset(-4, -4), blurRadius: 10),
                      ],
                    ),
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "XÁC NHẬN",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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