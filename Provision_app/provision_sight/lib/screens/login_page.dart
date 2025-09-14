// screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provision_sight/utils/voice_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _useFingerprint = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final hasFingerprint = await _localAuth.isDeviceSupported();
      setState(() {
        _useFingerprint = canCheck && hasFingerprint;
      });
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        backgroundColor: Color(0xFF1B5E20),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 120,
              width: 120,
            ),
            SizedBox(height: 40),
            Text(
              'Please say "Provision" to authenticate',
              style: TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticateWithVoice,
              icon: Icon(Icons.mic),
              label: Text(
                _isAuthenticating ? 'Listening...' : 'Start Voice Authentication',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            if (_useFingerprint) ...[
              Text(
                'or',
                style: TextStyle(color: Colors.white54),
              ),
              SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _authenticateWithFingerprint,
                icon: Icon(Icons.fingerprint),
                label: Text('Use Fingerprint'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
            SizedBox(height: 30),
            if (_attempts > 0)
              Text(
                'Authentication failed. Please try again.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _authenticateWithVoice() async {
    setState(() {
      _isAuthenticating = true;
    });

    // Simulate voice authentication
    await Future.delayed(Duration(seconds: 2));
    
    // For demo purposes, we'll assume success after 2 seconds
    final bool isAuthenticated = true; // Replace with actual voice auth logic
    
    setState(() {
      _isAuthenticating = false;
    });

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      setState(() {
        _attempts++;
      });
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Provision',
        options: AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() {
          _attempts++;
        });
      }
    } catch (e) {
      print('Error with fingerprint authentication: $e');
      setState(() {
        _attempts++;
      });
    }
  }
}