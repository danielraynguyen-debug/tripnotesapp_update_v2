import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'home_screen.dart';

class RegisterInfoScreen extends StatefulWidget {
  const RegisterInfoScreen({super.key});

  @override
  State<RegisterInfoScreen> createState() => _RegisterInfoScreenState();
}

class _RegisterInfoScreenState extends State<RegisterInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final Color primaryColor = const Color(0xFF7B66FF);
  final Color bgColor = const Color(0xFFF2F9F8);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildClayInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Thông tin cá nhân",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            // Thay `const HomeScreen()` bằng `HomeScreen()`
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
                  (route) => false,
            );
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(8, 8), blurRadius: 16),
                      BoxShadow(color: Colors.white, offset: const Offset(-8, -8), blurRadius: 16),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person_add_alt_1_rounded, size: 50, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Sắp hoàn tất rồi!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Text("Hãy cho chúng tôi biết về bạn",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(10, 10), blurRadius: 20),
                      BoxShadow(color: Colors.white, offset: const Offset(-10, -10), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildClayInput(
                          controller: _nameController,
                          label: "Họ và tên",
                          icon: Icons.badge_outlined
                      ),
                      const SizedBox(height: 20),
                      _buildClayInput(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (state is AuthLoading)
                  const CircularProgressIndicator()
                else
                  GestureDetector(
                    onTap: () {
                      final name = _nameController.text.trim();
                      final email = _emailController.text.trim();
                      if (name.isNotEmpty && email.isNotEmpty) {
                        context.read<AuthBloc>().add(
                          UpdateUserInfoEvent(name: name, email: email),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
                        );
                      }
                    },
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            offset: const Offset(0, 8),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            offset: const Offset(-4, -4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        "HOÀN TẤT",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5
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