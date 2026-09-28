import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/passage_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/reading/detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình đơn giản: chỉ cần google-services.json trong android/app/,
  // không cần firebase_options.dart (chỉ dùng khi target thêm iOS/web).
  await Firebase.initializeApp();

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // Nạp bài đọc mẫu + từ điển mini vào database (chỉ chạy nếu còn trống).
  await DatabaseService.instance.seedFromAssetsIfEmpty();

  runApp(const ChineseSrsApp());
}

class ChineseSrsApp extends StatelessWidget {
  const ChineseSrsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PassageProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: MaterialApp(
        title: 'Đọc Tiếng Trung',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/home': (_) => const HomeScreen(),
          '/detail': (_) => const DetailScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}

/// Quyết định màn hình đầu tiên khi mở app: nếu đã đăng nhập từ trước
/// (Firebase tự lưu phiên đăng nhập giữa các lần mở app) thì vào thẳng
/// HomeScreen, ngược lại hiện LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}