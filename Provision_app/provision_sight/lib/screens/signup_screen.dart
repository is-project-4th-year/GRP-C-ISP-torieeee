// screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/voice_auth_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final VoiceAuthService _voiceService = VoiceAuthService();
  final Box _userBox = Hive.box('userData');
  
  Map<String, dynamic> _userData = {
    'firstName': '',
    'lastName': '',
    'phone': '',
    'email': '',
    'emergencyContact': {
      'name': '',
      'phone': '',
      'email': ''
    }
  };

  List<String> _voiceSamples = [];
  int _currentSample = 0;
  bool _isRecordingVoicePrint = false;

  Future<void> _collectUserData() async {
    await _voiceService.speak("Welcome to Provision. Let's set up your account.");
    
    // Collect personal information
    await _collectPersonalInfo();
    
    // Collect emergency contact
    await _collectEmergencyContact();
    
    // Create voice print password
    await _createVoicePrint();
    
    // Save all data
    await _userBox.put('userProfile', _userData);
    
    await _voiceService.speak("Account setup complete! You can now sign in with your voice.");
    Navigator.pushReplacementNamed(context, '/signin');
  }

  Future<void> _collectPersonalInfo() async {
    await _voiceService.speak("Please say your first name");
    _userData['firstName'] = await _voiceService.listenForCommand();
    
    await _voiceService.speak("Please say your last name");
    _userData['lastName'] = await _voiceService.listenForCommand();
    
    await _collectPhoneNumber();
    
    await _voiceService.speak("Please say your email address, or say skip if you don't want to provide it");
    String email = await _voiceService.listenForCommand();
    if (email != "skip") {
      _userData['email'] = email;
    }
  }

  Future<void> _createVoicePrint() async {
    setState(() {
      _isRecordingVoicePrint = true;
      _currentSample = 0;
      _voiceSamples = [];
    });

    await _voiceService.speak("Now let's create your voice password. You'll need to say 'provision' five times.");

    for (int i = 0; i < 5; i++) {
      setState(() {
        _currentSample = i + 1;
      });

      await _voiceService.speak("Please say 'provision' for sample ${i + 1} of 5");
      
      String sample = await _voiceService.listenForCommand(listenFor: Duration(seconds: 3));
      
      if (sample == "provision") {
        _voiceSamples.add(sample);
        await _voiceService.speak("Sample ${i + 1} recorded successfully!");
      } else {
        await _voiceService.speak("That didn't sound right. Please try again.");
        i--; // Repeat this sample
      }
      
      await Future.delayed(Duration(seconds: 1));
    }

    // Save voice prints
    await _voiceService.saveVoicePrint(_voiceSamples);
    
    setState(() {
      _isRecordingVoicePrint = false;
    });

    await _voiceService.speak("Voice password setup complete! Your voice print has been saved.");
  }

  Future<void> _collectPhoneNumber() async {
    bool validPhone = false;
    
    while (!validPhone) {
      await _voiceService.speak("Please say your phone number with country code");
      String phone = await _voiceService.listenForCommand();
      
      if (phone.length >= 10) {
        _userData['phone'] = phone;
        validPhone = true;
      } else {
        await _voiceService.speak("That doesn't seem like a valid phone number. Please try again");
      }
    }
  }

  Future<void> _collectEmergencyContact() async {
    await _voiceService.speak("Now let's set up your emergency contact");
    
    await _voiceService.speak("Please say your emergency contact's full name");
    _userData['emergencyContact']['name'] = await _voiceService.listenForCommand();
    
    await _voiceService.speak("Please say your emergency contact's phone number");
    String emergencyPhone = await _voiceService.listenForCommand();
    
    if (emergencyPhone.length >= 10) {
      _userData['emergencyContact']['phone'] = emergencyPhone;
    } else {
      await _voiceService.speak("Invalid phone number. Emergency contact setup skipped.");
      return;
    }
    
    await _voiceService.speak("Please say your emergency contact's email, or say skip");
    String emergencyEmail = await _voiceService.listenForCommand();
    if (emergencyEmail != "skip") {
      _userData['emergencyContact']['email'] = emergencyEmail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecordingVoicePrint) ...[
              Icon(Icons.mic, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              Text("Voice Print Setup", style: TextStyle(fontSize: 24)),
              SizedBox(height: 10),
              Text("Sample $_currentSample of 5", style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Say 'provision' clearly into the microphone", 
                   style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ] else ...[
              Icon(Icons.person_add, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text("Voice Registration", style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _collectUserData,
                child: Text("Start Voice Registration"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}