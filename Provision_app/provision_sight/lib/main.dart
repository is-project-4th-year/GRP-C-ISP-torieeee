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
  
  // Request necessary permissions
  await _requestPermissions();
  
  // Initialize voice services
  try {
    await VoiceService.initialize();
  } catch (e) {
    print('Voice service initialization failed: $e');
  }
  
  // Initialize app storage
  await AppStorage.initialize();
  
  runApp(ProvisionApp());
}

Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.location.request();
  await Permission.storage.request();
  await Permission.contacts.request();
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