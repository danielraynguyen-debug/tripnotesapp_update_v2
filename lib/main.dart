import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/ride_repository.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'services/update_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  
  final authRepository = AuthRepository();
  final rideRepository = RideRepository();
  
  runApp(MyApp(
    authRepository: authRepository,
    rideRepository: rideRepository,
  ));
  
  // Check for updates after app launch (with delay to not block UI)
  Future.delayed(const Duration(seconds: 5), () {
    _checkForAppUpdate();
  });
}

/// Check for GitHub updates
Future<void> _checkForAppUpdate() async {
  await GithubUpdateService.checkAndDoUpdate(
    onLog: (message) => debugPrint('[AppUpdate] $message'),
    onError: (error) => debugPrint('[AppUpdate] ERROR: $error'),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final RideRepository rideRepository;
  
  const MyApp({
    super.key,
    required this.authRepository,
    required this.rideRepository,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Primary Palette: Indigo hiện đại #4F46E5
    const primaryIndigo = Color(0xFF4F46E5);
    const deepNavy = Color(0xFF1E293B);
    const lightSlate = Color(0xFFF1F5F9);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: rideRepository),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository),
        child: MaterialApp(
          title: 'Trip Notes',
          navigatorKey: NotificationService.navigatorKey, 
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryIndigo,
              primary: primaryIndigo,
              surface: Colors.white,
              background: lightSlate,
            ),
            // 3. Typography Hierarchy
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
              titleLarge: GoogleFonts.inter(
                color: deepNavy,
                fontWeight: FontWeight.bold,
              ),
              labelMedium: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
              bodyLarge: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: deepNavy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.1,
              ),
              iconTheme: IconThemeData(color: deepNavy),
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi', 'VN')],
          locale: const Locale('vi', 'VN'),
          home: SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
