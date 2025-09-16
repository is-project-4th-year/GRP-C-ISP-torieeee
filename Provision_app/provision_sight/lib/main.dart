import 'package:flutter/material.dart';
import 'package:provision_sight/screens/landing_page.dart';
import 'package:provision_sight/screens/signup_screen.dart';
import 'package:provision_sight/screens/login_page.dart';
import 'package:provision_sight/screens/main_page.dart';
import 'package:provision_sight/screens/guide_page.dart';
import 'package:provision_sight/screens/profile_page.dart';
import 'package:provision_sight/screens/emergency_contact_page.dart';
import 'package:provision_sight/themes/app_theme.dart';
import 'package:provision_sight/services/voice_service.dart';
import 'package:provision_sight/utils/app_storage.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ➡️ Initialize AppStorage ONCE — BEFORE everything else
  try {
    await AppStorage.initialize();
    print('✅ AppStorage initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize AppStorage: $e');
    // You may want to show a dialog or exit gracefully in production
    rethrow; // For now, let it crash during dev so you notice it
  }

  // Request necessary permissions
  await _requestPermissions();

  // Initialize voice services
  try {
    await VoiceService.initialize();
    print('✅ VoiceService initialized successfully');
  } catch (e) {
    print('⚠️ Voice service initialization failed: $e');
    // Not critical — app can still work with manual input
  }

  runApp(ProvisionApp());
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.storage,
    Permission.contacts,
  ];

  for (final permission in permissions) {
    final status = await permission.request();
    print('.Permission ${permission.toString().split('.').last}: $status');
  }
}

class ProvisionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provision',
      theme: AppThemes.darkGreenTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/signup': (context) => SignupPage(),
        '/login': (context) => LoginPage(),
        '/main': (context) => MainPage(),
        '/guide': (context) => GuidePage(),
        '/profile': (context) => ProfilePage(),
        '/emergency': (context) => EmergencyContactPage(),
      },
    );
  }
}