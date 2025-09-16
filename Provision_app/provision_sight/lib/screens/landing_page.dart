// screens/landing_page.dart
import 'package:flutter/material.dart';
import 'package:provision_sight/utils/voice_navigator.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late VoiceNavigator _voiceNav;

  @override
  void initState() {
    super.initState();
    _voiceNav = VoiceNavigator();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceGuidance();
    });
  }

  @override
  void dispose() {
    _voiceNav.dispose();
    super.dispose();
  }

  Future<void> _startVoiceGuidance() async {
    await Future.delayed(Duration(seconds: 1)); // Let UI settle
    await _voiceNav.speak("Welcome to Provision. Would you like to sign in or sign up? Say 'sign in' or 'sign up'.");
    
    final command = await _voiceNav.listenForCommand();
    _handleVoiceCommand(command);
  }

  void _handleVoiceCommand(String command) {
    command = command.toLowerCase();
    if (command.contains("sign up") || command.contains("signup")) {
      Navigator.pushNamed(context, '/signup');
    } else if (command.contains("sign in") || command.contains("signin")) {
      Navigator.pushNamed(context, '/login');
    } else if (command == "cancel") {
      _voiceNav.speak("Okay, you can use the buttons below.");
    } else {
      _voiceNav.speak("I didn't understand. Please say 'sign in' or 'sign up'.");
      _startVoiceGuidance(); // Retry
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF121212)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Provision',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              Image.asset(
                'assets/logo.jpeg',
                height: 150,
                width: 150,
              ),
              SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1B5E20),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  'Sign In',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}