import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/ride_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'tabs/home_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/connect_tab.dart';
import 'tabs/notification_tab.dart';
import 'tabs/profile_tab.dart';
import '../widgets/create_ride_dialog.dart';
import 'login_screen.dart';
import 'ride_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> homeKey = GlobalKey<_HomeScreenState>();

  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    ActivityTab(key: ActivityTab.activityKey),
    const ConnectTab(),
    const NotificationTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingRideFromNotification();
    });
  }

  Future<void> _checkPendingRideFromNotification() async {
    if (NotificationService.pendingRideId != null) {
      final rideId = NotificationService.pendingRideId!;
      NotificationService.pendingRideId = null;
      
      final rideRepo = RepositoryProvider.of<RideRepository>(context, listen: false);
      final ride = await rideRepo.getRideById(rideId);
      
      if (ride != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
        );
      }
    }
  }

  void setIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void showSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: duration ?? const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F9F8),
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "CreateRide",
              pageBuilder: (context, _, __) => const CreateRideDialog(),
            );
          },
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 10,
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 12,
          color: Colors.white,
          elevation: 20,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, "Trang chủ", 0),
                _buildNavItem(Icons.explore_rounded, "Hoạt động", 1),
                _buildNavItem(Icons.connect_without_contact, "Kết nối", 2),
                _buildNavItem(Icons.notifications_rounded, "Thông báo", 3),
                _buildNavItem(Icons.person_rounded, "Tài khoản", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}

// Đã chuyển về FAB mặc định centerDocked
