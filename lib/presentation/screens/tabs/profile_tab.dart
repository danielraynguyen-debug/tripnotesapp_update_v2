import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploading = false;
  String? _appVersion;

  // Modern Glass & Indigo Colors
  static const Color bgApp = Color(0xFFF8FAFC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFF6366F1);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFF1F5F9);
  static const Color amberPremium = Color(0xFFF59E0B);
  static const Color emeraldBasic = Color(0xFF10B981);

  Future<void> _pickAndUploadImage(AuthRepository authRepo, String uid) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        await authRepo.uploadAvatar(uid, File(pickedFile.path));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải ảnh: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "${info.version} + ${info.buildNumber}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = RepositoryProvider.of<AuthRepository>(context);
    final userAuth = authRepo.currentUser;

    if (userAuth == null) {
      return const Center(child: Text("Lỗi: Không tìm thấy phiên đăng nhập."));
    }

    return Scaffold(
      backgroundColor: bgApp,
      body: StreamBuilder<UserModel?>(
        stream: authRepo.getUserStream(userAuth.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryIndigo,
              ),
            );
          }

          final userModel = snapshot.data;
          
          final displayName = userModel?.displayName ?? userAuth.displayName ?? "Chưa cập nhật";
          final phoneNumber = userModel?.phoneNumber ?? userAuth.phoneNumber ?? "N/A";
          final email = userModel?.email ?? userAuth.email ?? "Chưa có email";
          final photoUrl = userModel?.photoUrl ?? userAuth.photoURL;
          final membership = userModel?.membership ?? 'Free';
          final isPremium = membership == 'Premium';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Gradient + Overlapping Avatar
                _buildHeaderSection(photoUrl, authRepo, userAuth.uid, displayName, isPremium),
                
                const SizedBox(height: 20), // Reduced space for cleaner layout
                
                // User Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildUserInfoCard(displayName, phoneNumber, email),
                ),
                const SizedBox(height: 24),
                
                // Logout Button - Light Red
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(LogoutEvent());
                      },
                      icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                      label: const Text(
                        "Đăng xuất",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                        backgroundColor: const Color(0xFFFFF1F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Version at bottom
                Text(
                  _appVersion != null ? "Version $_appVersion" : "Version ...",
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(String? photoUrl, AuthRepository authRepo, String uid, String displayName, bool isPremium) {
    return Container(
      height: 200,
      child: Stack(
        children: [
          // Indigo Gradient Background
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      "TÀI KHOẢN",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Avatar and Info - Centered at bottom of header
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _pickAndUploadImage(authRepo, uid),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: primaryIndigo.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 84,
                                height: 84,
                              )
                            : Container(
                                color: const Color(0xFFEEF2FF),
                                child: const Icon(
                                  Icons.person,
                                  size: 36,
                                  color: primaryIndigo,
                                ),
                              ),
                        ),
                      ),
                      if (_isUploading)
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      // Camera button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primaryIndigo,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: primaryIndigo.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Display Name
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Membership Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: isPremium
                      ? const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                    color: isPremium ? null : const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.workspace_premium : Icons.shield,
                        size: 10,
                        color: isPremium ? Colors.white : primaryIndigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? "Thành viên Premium" : "Hạng Chì",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPremium ? Colors.white : primaryIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium
          ? const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
        color: isPremium ? null : bgCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? primaryIndigo : primaryIndigo).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPremium 
                ? Colors.white.withOpacity(0.2)
                : const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.person_outline,
                  size: 18,
                  color: isPremium ? Colors.white : primaryIndigo,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? "Thành viên Premium" : "Thành viên Cơ bản",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isPremium ? Colors.white : primaryIndigo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Benefits list
          ..._buildBenefitsList(isPremium),
          const SizedBox(height: 20),
          // Upgrade Button (only for basic members)
          if (!isPremium)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to upgrade screen
                  _showUpgradeDialog();
                },
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text(
                  "Nâng cấp Premium",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildBenefitsList(bool isPremium) {
    final benefits = isPremium
      ? [
          _buildBenefitItem(Icons.check_circle, "Ưu tiên hiển thị ghi chú", true),
          _buildBenefitItem(Icons.check_circle, "Không giới hạn đăng lộ trình", true),
          _buildBenefitItem(Icons.check_circle, "Hỗ trợ 24/7", true),
          _buildBenefitItem(Icons.check_circle, "Badge Premium độc quyền", true),
        ]
      : [
          _buildBenefitItem(Icons.check_circle, "Đăng tối đa 5 ghi chú/tháng", true),
          _buildBenefitItem(Icons.check_circle, "Tạo 3 lộ trình cố định", true),
          _buildBenefitItem(Icons.remove_circle, "Ưu tiên hiển thị", false),
          _buildBenefitItem(Icons.remove_circle, "Hỗ trợ 24/7", false),
        ];
    return benefits;
  }

  Widget _buildBenefitItem(IconData icon, String text, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isAvailable ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: isAvailable ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(String displayName, String phoneNumber, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryIndigo.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(Icons.badge_outlined, "Họ tên", displayName),
          const Divider(height: 16, color: dividerColor, indent: 48),
          _buildInfoItem(Icons.phone_outlined, "Số điện thoại", phoneNumber),
          const Divider(height: 16, color: dividerColor, indent: 48),
          _buildInfoItem(Icons.email_outlined, "Email", email),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryIndigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 40,
                color: primaryIndigo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Nâng cấp Premium",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Trải nghiệm đầy đủ tính năng",
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildUpgradeBenefit("Ưu tiên hiển thị ghi chú"),
            _buildUpgradeBenefit("Không giới hạn đăng lộ trình"),
            _buildUpgradeBenefit("Hỗ trợ khách hàng 24/7"),
            _buildUpgradeBenefit("Badge Premium độc quyền"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement payment
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tính năng đang phát triển")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "199.000đ / tháng",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Để sau",
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
