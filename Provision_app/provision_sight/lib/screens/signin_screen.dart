// screens/signin_screen.dart
import 'package:flutter/material.dart';
import '../services/voice_auth_service.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final VoiceAuthService _voiceService = VoiceAuthService();
  int _attempts = 0;
  bool _isVerifying = false;

  Future<void> _signInWithVoice() async {
    setState(() => _isVerifying = true);
    
    await _voiceService.speak("Please say provision to sign in");
    
    String attempt = await _voiceService.listenForCommand(listenFor: Duration(seconds: 3));
    
    if (_voiceService.verifyVoicePrint(attempt)) {
      await _voiceService.speak("Voice recognized. Welcome back!");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _attempts++;
      if (_attempts >= 3) {
        await _voiceService.speak("Too many failed attempts. Please try again later or contact support.");
      } else {
        await _voiceService.speak("Voice not recognized. Please try again.");
      }
    }
    
    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isVerifying) ...[
              Icon(Icons.verified_user, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              Text("Verifying Voice Print...", style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ] else ...[
              Icon(Icons.voice_chat, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              Text("Voice Authentication", style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signInWithVoice,
                child: Text("Start Voice Sign-in"),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: Text("Need to create an account?"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}