import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/otp_login_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/prayer_times/presentation/screens/home_screen.dart';
import 'features/admin/presentation/screens/super_admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';

class MasjidApp extends ConsumerWidget {
  const MasjidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Silah Community Adhan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppStartupGate(),
    );
  }
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    final hasSession = await ApiService.instance.initSession();
    if (!mounted) return;

    if (hasSession && ApiService.instance.currentUser != null) {
      final user = ApiService.instance.currentUser!;
      final phone = (user['phone'] ?? '').toString();
      final isSuperAdmin = ApiService.instance.isSuperAdmin || phone.contains('1234567890');

      // 1. Super Admin route
      if (isSuperAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
        );
        return;
      }

      // 2. Incomplete onboarding route
      final isOnboarded = user['isOnboarded'] == true ||
          (user['name'] != null && user['name'].toString().trim().isNotEmpty && user['name'].toString().trim() != 'User');
      if (!isOnboarded) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OnboardingScreen(phone: phone)),
        );
        return;
      }

      // 3. Check if user is Masjid Admin
      final adminRoles = user['adminRoles'] as List<dynamic>?;
      if (adminRoles != null && adminRoles.isNotEmpty) {
        NotificationService.instance.configureAfterLogin();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }

      // 4. Regular Musalli -> Home Screen (with bottom nav bar)
      NotificationService.instance.configureAfterLogin();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // No active session -> OtpLoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F432B),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
