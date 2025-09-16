// // // // screens/signup_screen.dart
// // // import 'package:flutter/material.dart';
// // // import 'package:hive/hive.dart';
// // // import '../services/voice_auth_service.dart';

// // // class SignUpScreen extends StatefulWidget {
// // //   @override
// // //   _SignUpScreenState createState() => _SignUpScreenState();
// // // }

// // // class _SignUpScreenState extends State<SignUpScreen> {
// // //   final VoiceAuthService _voiceService = VoiceAuthService();
// // //   final Box _userBox = Hive.box('userData');
  
// // //   Map<String, dynamic> _userData = {
// // //     'firstName': '',
// // //     'lastName': '',
// // //     'phone': '',
// // //     'email': '',
// // //     'emergencyContact': {
// // //       'name': '',
// // //       'phone': '',
// // //       'email': ''
// // //     }
// // //   };

// // //   List<String> _voiceSamples = [];
// // //   int _currentSample = 0;
// // //   bool _isRecordingVoicePrint = false;
// // //   String _currentStep = 'idle';
// // //   bool _isCollecting = false; // Prevent multiple simultaneous operations

// // //   Future<void> _collectUserData() async {
// // //     try {
// // //       setState(() => _currentStep = 'initializing');
      
// // //       // Initialize voice service first
// // //       bool initialized = await _voiceService.initializeVoice();
// // //       if (!initialized) {
// // //         await _showError("Failed to initialize voice service. Please check microphone permissions.");
// // //         return;
// // //       }

// // //       await _voiceService.speak("Welcome to Provision. Let's set up your account.");
      
// // //       // Collect personal information
// // //       await _collectPersonalInfo();
      
// // //       // Collect emergency contact
// // //       await _collectEmergencyContact();
      
// // //       // Create voice print password
// // //       await _createVoicePrint();
      
// // //       // Save all data
// // //       await _userBox.put('userProfile', _userData);
      
// // //       await _voiceService.speak("Account setup complete! You can now sign in with your voice.");
      
// // //       if (mounted) {
// // //         Navigator.pushReplacementNamed(context, '/signin');
// // //       }
// // //     } catch (e) {
// // //       print('Error in _collectUserData: $e');
// // //       await _showError("An error occurred during registration. Please try again.");
// // //     }
// // //   }

// // //   Future<void> _collectPersonalInfo() async {
// // //     setState(() => _currentStep = 'collecting_personal_info');
    
// // //     // Collect first name with retry logic
// // //     String firstName = await _collectWithRetry(
// // //       prompt: "Please say your first name",
// // //       validator: (input) => input.isNotEmpty && !input.contains('error:'),
// // //       maxRetries: 3
// // //     );
// // //     if (firstName.isEmpty) return;
// // //     _userData['firstName'] = firstName;
    
// // //     // Collect last name with retry logic
// // //     String lastName = await _collectWithRetry(
// // //       prompt: "Please say your last name",
// // //       validator: (input) => input.isNotEmpty && !input.contains('error:'),
// // //       maxRetries: 3
// // //     );
// // //     if (lastName.isEmpty) return;
// // //     _userData['lastName'] = lastName;
    
// // //     await _collectPhoneNumber();
    
// // //     await _voiceService.speak("Please say your email address, or say skip if you don't want to provide it");
// // //     String email = await _voiceService.listenForCommand(listenFor: Duration(seconds: 8));
    
// // //     if (!email.contains('error:') && email != "skip" && email.isNotEmpty) {
// // //       _userData['email'] = email;
// // //     }
// // //   }

// // //   // In _collectWithRetry method - FIX THE VALIDATOR
// // // Future<String> _collectWithRetry({
// // //   required String prompt,
// // //   required bool Function(String) validator,
// // //   int maxRetries = 3,
// // // }) async {
// // //   for (int attempt = 0; attempt < maxRetries; attempt++) {
// // //     await _voiceService.speak(prompt);
// // //     await Future.delayed(Duration(milliseconds: 800)); // Add pause
    
// // //     String response = await _voiceService.listenForCommand(listenFor: Duration(seconds: 8));
    
// // //     // ✅ FIXED VALIDATOR: Don't treat empty responses as errors immediately
// // //     if (response.contains('error:')) {
// // //       if (response.contains('permission_not_granted')) {
// // //         await _showError("Microphone permission is required. Please enable it in your device settings.");
// // //         return '';
// // //       } else if (response.contains('no_sound_detected')) {
// // //         await _voiceService.speak("I didn't hear anything. Please speak louder or check your microphone.");
// // //         continue;
// // //       } else {
// // //         await _voiceService.speak("There was a technical error. Let's try again.");
// // //         continue;
// // //       }
// // //     }
    
// // //     // ✅ Allow empty responses to retry instead of failing
// // //     if (response.isEmpty) {
// // //       await _voiceService.speak("I didn't hear anything. Please try again.");
// // //       continue;
// // //     }
    
// // //     if (validator(response)) {
// // //       await _voiceService.speak("Got it!");
// // //       await Future.delayed(Duration(milliseconds: 500));
// // //       return response;
// // //     } else {
// // //       await _voiceService.speak("I heard '$response'. Please try again.");
// // //     }
// // //   }
  
// // //   await _showError("Unable to collect information after multiple attempts. Please try again later.");
// // //   return '';
// // // }

// // // Future<void> _playStartBeep() async {
// // //   // Play a beep sound to indicate recording start
// // //   await _voiceService.speak(" ");
// // //   await Future.delayed(Duration(milliseconds: 300));
// // // }

// // //   Future<void> _createVoicePrint() async {
// // //     setState(() {
// // //       _isRecordingVoicePrint = true;
// // //       _currentSample = 0;
// // //       _voiceSamples = [];
// // //       _currentStep = 'voice_print';
// // //     });

// // //     await _voiceService.speak("Now let's create your voice password. You'll need to say 'provision' five times clearly.");
// // //     await Future.delayed(Duration(seconds: 1));

// // //     for (int i = 0; i < 5; i++) {
// // //       setState(() {
// // //         _currentSample = i + 1;
// // //       });

// // //       bool sampleRecorded = false;
// // //       int attempts = 0;
      
// // //       while (!sampleRecorded && attempts < 3) {
// // //         await _voiceService.speak("Please say 'provision' clearly for sample ${i + 1} of 5");
        
// // //         String sample = await _voiceService.listenForCommand(listenFor: Duration(seconds: 4));
        
// // //         if (sample.contains('error:')) {
// // //           attempts++;
// // //           if (attempts >= 3) {
// // //             await _showError("Unable to record voice sample. Please try again later.");
// // //             setState(() => _isRecordingVoicePrint = false);
// // //             return;
// // //           }
// // //           await _voiceService.speak("There was an error. Let's try again.");
// // //           continue;
// // //         }
        
// // //         if (sample.toLowerCase().contains("provision")) {
// // //           _voiceSamples.add(sample);
// // //           await _voiceService.speak("Sample ${i + 1} recorded successfully!");
// // //           sampleRecorded = true;
// // //         } else {
// // //           attempts++;
// // //           if (attempts < 3) {
// // //             await _voiceService.speak("I heard '$sample'. Please say 'provision' clearly.");
// // //           } else {
// // //             await _voiceService.speak("Let's try this sample again.");
// // //             attempts = 0; // Reset attempts for this sample
// // //           }
// // //         }
        
// // //         await Future.delayed(Duration(milliseconds: 500));
// // //       }
      
// // //       if (!sampleRecorded) {
// // //         await _showError("Unable to record voice samples. Please try again later.");
// // //         setState(() => _isRecordingVoicePrint = false);
// // //         return;
// // //       }
// // //     }

// // //     // Save voice prints
// // //     await _voiceService.saveVoicePrint(_voiceSamples);
    
// // //     setState(() {
// // //       _isRecordingVoicePrint = false;
// // //       _currentStep = 'completed';
// // //     });

// // //     await _voiceService.speak("Excellent! Your voice password has been created and saved.");
// // //   }

// // //   Future<void> _collectPhoneNumber() async {
// // //     bool validPhone = false;
// // //     int attempts = 0;
    
// // //     while (!validPhone && attempts < 3) {
// // //       await _voiceService.speak("Please say your phone number with country code");
// // //       String phone = await _voiceService.listenForCommand(listenFor: Duration(seconds: 10));
      
// // //       if (phone.contains('error:')) {
// // //         attempts++;
// // //         if (attempts >= 3) {
// // //           await _showError("Unable to collect phone number. Please try again later.");
// // //           return;
// // //         }
// // //         await _voiceService.speak("There was an error. Let's try again.");
// // //         continue;
// // //       }
      
// // //       // Remove spaces and non-numeric characters for validation
// // //       String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
// // //       if (cleanPhone.length >= 10) {
// // //         _userData['phone'] = phone;
// // //         await _voiceService.speak("Phone number saved.");
// // //         validPhone = true;
// // //       } else {
// // //         attempts++;
// // //         if (attempts < 3) {
// // //           await _voiceService.speak("That doesn't seem like a valid phone number. Please include the country code and try again.");
// // //         }
// // //       }
// // //     }
    
// // //     if (!validPhone) {
// // //       await _showError("Unable to collect a valid phone number after multiple attempts.");
// // //     }
// // //   }

// // //   Future<void> _collectEmergencyContact() async {
// // //     setState(() => _currentStep = 'emergency_contact');
    
// // //     await _voiceService.speak("Now let's set up your emergency contact");
    
// // //     String emergencyName = await _collectWithRetry(
// // //       prompt: "Please say your emergency contact's full name",
// // //       validator: (input) => input.isNotEmpty && !input.contains('error:'),
// // //       maxRetries: 3
// // //     );
// // //     if (emergencyName.isEmpty) return;
// // //     _userData['emergencyContact']['name'] = emergencyName;
    
// // //     await _voiceService.speak("Please say your emergency contact's phone number");
// // //     String emergencyPhone = await _voiceService.listenForCommand(listenFor: Duration(seconds: 10));
    
// // //     if (!emergencyPhone.contains('error:')) {
// // //       String cleanPhone = emergencyPhone.replaceAll(RegExp(r'[^\d]'), '');
// // //       if (cleanPhone.length >= 10) {
// // //         _userData['emergencyContact']['phone'] = emergencyPhone;
// // //         await _voiceService.speak("Emergency contact phone number saved.");
// // //       } else {
// // //         await _voiceService.speak("Invalid phone number. Emergency contact phone skipped.");
// // //       }
// // //     } else {
// // //       await _voiceService.speak("Unable to record emergency phone. Skipping.");
// // //     }
    
// // //     await _voiceService.speak("Please say your emergency contact's email, or say skip");
// // //     String emergencyEmail = await _voiceService.listenForCommand(listenFor: Duration(seconds: 8));
    
// // //     if (!emergencyEmail.contains('error:') && emergencyEmail != "skip" && emergencyEmail.isNotEmpty) {
// // //       _userData['emergencyContact']['email'] = emergencyEmail;
// // //       await _voiceService.speak("Emergency contact email saved.");
// // //     }
// // //   }

// // //   Future<void> _showError(String message) async {
// // //     print('Error: $message');
// // //     if (mounted) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text(message), backgroundColor: Colors.red),
// // //       );
// // //     }
// // //     await _voiceService.speak(message);
// // //   }

// // //   @override
// // //   void dispose() {
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       body: Center(
// // //         child: Padding(
// // //           padding: EdgeInsets.all(20),
// // //           child: Column(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               if (_isRecordingVoicePrint) ...[
// // //                 Icon(Icons.mic, size: 100, color: Colors.blue),
// // //                 SizedBox(height: 20),
// // //                 Text("Voice Print Setup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// // //                 SizedBox(height: 10),
// // //                 Text("Sample $_currentSample of 5", style: TextStyle(fontSize: 18)),
// // //                 SizedBox(height: 10),
// // //                 CircularProgressIndicator(),
// // //                 SizedBox(height: 20),
// // //                 Text("Say 'provision' clearly into the microphone", 
// // //                      style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
// // //               ] else if (_currentStep != 'idle') ...[
// // //                 Icon(Icons.person_add, size: 100, color: Colors.green),
// // //                 SizedBox(height: 20),
// // //                 Text("Voice Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// // //                 SizedBox(height: 10),
// // //                 Text(_getStepDescription(), style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
// // //                 SizedBox(height: 20),
// // //                 CircularProgressIndicator(),
// // //               ] else ...[
// // //                 Icon(Icons.person_add, size: 100, color: Colors.green),
// // //                 SizedBox(height: 20),
// // //                 Text("Voice Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// // //                 SizedBox(height: 20),
// // //                 Text("Set up your account using only your voice", 
// // //                      style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
// // //                 SizedBox(height: 30),
// // //                 ElevatedButton(
// // //                   onPressed: _isCollecting ? null : _collectUserData, // Disable if already collecting
// // //                   style: ElevatedButton.styleFrom(
// // //                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
// // //                     backgroundColor: _isCollecting ? Colors.grey : null,
// // //                   ),
// // //                   child: Text(
// // //                     _isCollecting ? "Processing..." : "Start Voice Registration", 
// // //                     style: TextStyle(fontSize: 18)
// // //                   ),
// // //                 ),
// // //                 SizedBox(height: 20),
// // //                 TextButton(
// // //                   onPressed: () => Navigator.pushNamed(context, '/signin'),
// // //                   child: Text("Already have an account? Sign in"),
// // //                 ),
// // //               ],
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   String _getStepDescription() {
// // //     switch (_currentStep) {
// // //       case 'initializing':
// // //         return 'Initializing voice service...';
// // //       case 'collecting_personal_info':
// // //         return 'Collecting your personal information...';
// // //       case 'emergency_contact':
// // //         return 'Setting up emergency contact...';
// // //       case 'voice_print':
// // //         return 'Creating voice password...';
// // //       case 'completed':
// // //         return 'Registration completed!';
// // //       default:
// // //         return 'Processing...';
// // //     }
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:hive/hive.dart';
// // import '../services/voice_auth_service.dart';

// // class SignUpScreen extends StatefulWidget {
// //   @override
// //   _SignUpScreenState createState() => _SignUpScreenState();
// // }

// // class _SignUpScreenState extends State<SignUpScreen> {
// //   final VoiceAuthService _voiceService = VoiceAuthService();
// //   final Box _userBox = Hive.box('userData');
  
// //   Map<String, dynamic> _userData = {
// //     'firstName': '',
// //     'lastName': '',
// //     'phone': '',
// //     'email': '',
// //     'emergencyContact': {
// //       'name': '',
// //       'phone': '',
// //       'email': ''
// //     }
// //   };

// //   List<String> _voiceSamples = [];
// //   int _currentSample = 0;
// //   bool _isRecordingVoicePrint = false;
// //   String _currentStep = 'idle';
// //   bool _isCollecting = false;

// //   Future<void> _collectUserData() async {
// //     if (_isCollecting) return; // ✅ FIXED: Prevent multiple simultaneous calls
    
// //     try {
// //       setState(() {
// //         _isCollecting = true;
// //         _currentStep = 'initializing';
// //       });
      
// //       bool initialized = await _voiceService.initializeVoice();
// //       if (!initialized) {
// //         await _showError("Failed to initialize voice service. Please check microphone permissions.");
// //         return;
// //       }

// //       await _voiceService.speak("Welcome to Provision. Let's set up your account.");
      
// //       await _collectPersonalInfo();
// //       await _collectEmergencyContact();
// //       await _createVoicePrint();
      
// //       await _userBox.put('userProfile', _userData);
      
// //       await _voiceService.speak("Account setup complete! You can now sign in with your voice.");
      
// //       if (mounted) {
// //         Navigator.pushReplacementNamed(context, '/signin');
// //       }
// //     } catch (e) {
// //       print('Error in _collectUserData: $e');
// //       await _showError("An error occurred during registration. Please try again.");
// //     } finally {
// //       // ✅ FIXED: Always reset the collecting state
// //       setState(() {
// //         _isCollecting = false;
// //         _currentStep = 'idle';
// //       });
// //     }
// //   }

// //   Future<void> _collectPersonalInfo() async {
// //     setState(() => _currentStep = 'collecting_personal_info');
    
// //     String firstName = await _collectWithRetry(
// //       prompt: "Please say your first name",
// //       validator: (input) => input.isNotEmpty && !input.contains('error:'),
// //       maxRetries: 3
// //     );
// //     if (firstName.isEmpty) return;
// //     _userData['firstName'] = firstName;
    
// //     String lastName = await _collectWithRetry(
// //       prompt: "Please say your last name",
// //       validator: (input) => input.isNotEmpty && !input.contains('error:'),
// //       maxRetries: 3
// //     );
// //     if (lastName.isEmpty) return;
// //     _userData['lastName'] = lastName;
    
// //     await _collectPhoneNumber();
    
// //     await _voiceService.speak("Please say your email address, or say skip if you don't want to provide it");
// //     String email = await _voiceService.listenForCommand(listenFor: Duration(seconds: 8));
    
// //     if (!email.contains('error:') && email != "skip" && email.isNotEmpty) {
// //       _userData['email'] = email;
// //     }
// //   }

// //   Future<String> _collectWithRetry({
// //     required String prompt,
// //     required bool Function(String) validator,
// //     int maxRetries = 3,
// //   }) async {
// //     for (int attempt = 0; attempt < maxRetries; attempt++) {
// //       await _voiceService.speak(prompt);
// //       await Future.delayed(Duration(milliseconds: 800));
      
// //       String response = await _voiceService.listenForCommand(listenFor: Duration(seconds: 8));
      
// //       if (response.contains('error:')) {
// //         if (response.contains('permission_not_granted')) {
// //           await _showError("Microphone permission is required. Please enable it in your device settings.");
// //           return '';
// //         } else if (response.contains('no_sound_detected')) {
// //           await _voiceService.speak("I didn't hear anything. Please speak louder or check your microphone.");
// //           continue;
// //         } else {
// //           await _voiceService.speak("There was a technical error. Let's try again.");
// //           continue;
// //         }
// //       }
      
// //       if (response.isEmpty) {
// //         await _voiceService.speak("I didn't hear anything. Please try again.");
// //         continue;
// //       }
      
// //       if (validator(response)) {
// //         await _voiceService.speak("Got it!");
// //         await Future.delayed(Duration(milliseconds: 500));
// //         return response;
// //       } else {
// //         await _voiceService.speak("I heard '$response'. Please try again.");
// //       }
// //     }
    
// //     await _showError("Unable to collect information after multiple attempts. Please try again later.");
// //     return '';
// //   }

// //   Future<void> _createVoicePrint() async {
// //     setState(() {
// //       _isRecordingVoicePrint = true;
// //       _currentSample = 0;
// //       _voiceSamples = [];
// //       _currentStep = 'voice_print';
// //     });

// //     await _voiceService.speak("Now let's create your voice password. You'll need to say 'provision' five times clearly.");
// //     await Future.delayed(Duration(seconds: 1));

// //     for (int i = 0; i < 5; i++) {
// //       setState(() {
// //         _currentSample = i + 1;
// //       });

// //       bool sampleRecorded = false;
// //       int attempts = 0;
      
// //       while (!sampleRecorded && attempts < 3) {
// //         await _voiceService.speak("Please say 'provision' clearly for sample ${i + 1} of 5");
        
// //         String sample = await _voiceService.listenForCommand(listenFor: Duration(seconds: 4));
        
// //         if (sample.contains('error:')) {
// //           attempts++;
// //           if (attempts >= 3) {
// //             await _showError("Unable to record voice sample. Please try again later.");
// //             setState(() => _isRecordingVoicePrint = false);
// //             return;
// //           }
// //           await _voiceService.speak("There was an error. Let's try again.");
// //           continue;
// //         }
        
// //         if (sample.toLowerCase().contains("provision")) {
// //           _voiceSamples.add(sample);
// //           await _voiceService.speak("Sample ${i + 1} recorded successfully!");
// //           sampleRecorded = true;
// //         } else {
// //           attempts++;
// //           if (attempts < 3) {
// //             await _voiceService.speak("I heard '$sample'. Please say 'provision' clearly.");
// //           } else {
// //             await _voiceService.speak("Let's try this sample again.");
// //             attempts = 0;
// //           }
// //         }
        
// //         await Future.delayed(Duration(milliseconds: 500));
// //       }
      
// //       if (!sampleRecorded) {
// //         await _showError("Unable to record voice samples. Please try again later.");
// //         setState(() => _isRecordingVoicePrint = false);
// //         return;
// //       }
// //     }

// //     // ✅ FIXED: Call saveVoicePrint with List<String> parameter
// //     await _voiceService.saveVoicePrint(_voiceSamples);
    
// //     setState(() {
// //       _isRecordingVoicePrint = false;
// //       _currentStep = 'completed';
// //     });

// //     await _voiceService.speak("Excellent! Your voice password has been created and saved.");
// //   }

// //   Future<void> _collectPhoneNumber() async {
// //     bool validPhone = false;
// //     int attempts = 0;
    
// //     while (!validPhone && attempts < 3) {
// //       await _voiceService.speak("Please say your phone number with country code");
// //       String phone = await _voiceService.listenForCommand(listenFor: Duration(seconds: 10));
      
// //       if (phone.contains('error:')) {
// //         attempts++;
// //         if (attempts >= 3) {
// //           await _showError("Unable to collect phone number. Please try again later.");
// //           return;
// //         }
// //         await _voiceService.speak("There was an error. Let's try again.");
// //         continue;
// //       }
      
// //       String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
// //       if (cleanPhone.length >= 10) {
// //         _userData['phone'] = phone;
// //         await _voiceService.speak("Phone number saved.");
// //         validPhone = true;
// //       } else {
// //         attempts++;
// //         if (attempts < 3) {
// //           await _voiceService.speak("That doesn't seem like a valid phone number. Please include the country code and try again.");
// //         }
// //       }
// //     }
    
// //     if (!validPhone) {
// //       await _showError("Unable to collect a valid phone number after multiple attempts.");
// //     }
// //   }

// //   Future<void> _collectEmergencyContact() async {
// //     setState(() => _currentStep = 'emergency_contact');
    
// //     await _voiceService.speak("Now let's set up your emergency contact");
    
// //     String emergencyName = await _collectWithRetry(
// //       prompt: "Please say your emergency contact's full name",
// //       validator: (input) => input.isNotEmpty && !input.contains('error:'),
// //       maxRetries: 3
// //     );
// //     if (emergencyName.isEmpty) return;
// //     _userData['emergencyContact']['name'] = emergencyName;
    
// //     await _voiceService.speak("Please say your emergency contact's phone number");
// //     String emergencyPhone = await _voiceService.listenForCommand(listenFor: Duration(seconds: 10));
    
// //     if (!emergencyPhone.contains('error:')) {
// //       String cleanPhone = emergencyPhone.replaceAll(RegExp(r'[^\d]'), '');
// //       if (cleanPhone.length >= 10) {
// //         _userData['emergencyContact']['phone'] = emergencyPhone;
// //         await _voiceService.speak("Emergency contact phone number saved.");
// //       } else {
// //         await _voiceService.speak("Invalid phone number. Emergency contact phone skipped.");
// //       }
// //     } else {
// //       await _voiceService.speak("Unable to record emergency phone. Skipping.");
// //     }
    
// //     await _voiceService.speak("Please say your emergency contact's email, or say skip");
// //     String emergencyEmail = await _voiceService.listenForCommand(listenFor: Duration(seconds: 8));
    
// //     if (!emergencyEmail.contains('error:') && emergencyEmail != "skip" && emergencyEmail.isNotEmpty) {
// //       _userData['emergencyContact']['email'] = emergencyEmail;
// //       await _voiceService.speak("Emergency contact email saved.");
// //     }
// //   }

// //   Future<void> _showError(String message) async {
// //     print('Error: $message');
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text(message), backgroundColor: Colors.red),
// //       );
// //     }
// //     await _voiceService.speak(message);
// //   }

// //   @override
// //   void dispose() {
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Center(
// //         child: Padding(
// //           padding: EdgeInsets.all(20),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               if (_isRecordingVoicePrint) ...[
// //                 Icon(Icons.mic, size: 100, color: Colors.blue),
// //                 SizedBox(height: 20),
// //                 Text("Voice Print Setup", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// //                 SizedBox(height: 10),
// //                 Text("Sample $_currentSample of 5", style: TextStyle(fontSize: 18)),
// //                 SizedBox(height: 10),
// //                 CircularProgressIndicator(),
// //                 SizedBox(height: 20),
// //                 Text("Say 'provision' clearly into the microphone", 
// //                      style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
// //               ] else if (_currentStep != 'idle') ...[
// //                 Icon(Icons.person_add, size: 100, color: Colors.green),
// //                 SizedBox(height: 20),
// //                 Text("Voice Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// //                 SizedBox(height: 10),
// //                 Text(_getStepDescription(), style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
// //                 SizedBox(height: 20),
// //                 CircularProgressIndicator(),
// //               ] else ...[
// //                 Icon(Icons.person_add, size: 100, color: Colors.green),
// //                 SizedBox(height: 20),
// //                 Text("Voice Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
// //                 SizedBox(height: 20),
// //                 Text("Set up your account using only your voice", 
// //                      style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
// //                 SizedBox(height: 30),
// //                 ElevatedButton(
// //                   onPressed: _isCollecting ? null : _collectUserData,
// //                   style: ElevatedButton.styleFrom(
// //                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
// //                     backgroundColor: _isCollecting ? Colors.grey : null,
// //                   ),
// //                   child: Text(
// //                     _isCollecting ? "Processing..." : "Start Voice Registration", 
// //                     style: TextStyle(fontSize: 18)
// //                   ),
// //                 ),
// //                 SizedBox(height: 20),
// //                 TextButton(
// //                   onPressed: () => Navigator.pushNamed(context, '/signin'),
// //                   child: Text("Already have an account? Sign in"),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   String _getStepDescription() {
// //     switch (_currentStep) {
// //       case 'initializing':
// //         return 'Initializing voice service...';
// //       case 'collecting_personal_info':
// //         return 'Collecting your personal information...';
// //       case 'emergency_contact':
// //         return 'Setting up emergency contact...';
// //       case 'voice_print':
// //         return 'Creating voice password...';
// //       case 'completed':
// //         return 'Registration completed!';
// //       default:
// //         return 'Processing...';
// //     }
// //   }
// // }

// // screens/signup_page.dart
// import 'package:flutter/material.dart';
// import 'package:provision_sight/utils/voice_auth.dart';

// class SignupPage extends StatefulWidget {
//   @override
//   _SignupPageState createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _emergencyNameController = TextEditingController();
//   final TextEditingController _emergencyPhoneController = TextEditingController();
//   final TextEditingController _emergencyEmailController = TextEditingController();
//   final TextEditingController _relationshipController = TextEditingController();

//   int _voiceSamplesRecorded = 0;
//   bool _isRecording = false;
//   bool _useVoiceInput = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Sign Up'),
//         backgroundColor: Color(0xFF1B5E20),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text(
//                 'Personal Information',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               SizedBox(height: 20),
//               _buildInputField(
//                 controller: _firstNameController,
//                 label: 'First Name',
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 15),
//               _buildInputField(
//                 controller: _lastNameController,
//                 label: 'Last Name',
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 15),
//               _buildInputField(
//                 controller: _phoneController,
//                 label: 'Phone Number',
//                 keyboardType: TextInputType.phone,
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 15),
//               _buildInputField(
//                 controller: _emailController,
//                 label: 'Email',
//                 keyboardType: TextInputType.emailAddress,
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 30),
//               Text(
//                 'Emergency Contact',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               SizedBox(height: 20),
//               _buildInputField(
//                 controller: _emergencyNameController,
//                 label: 'Contact Name',
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 15),
//               _buildInputField(
//                 controller: _emergencyPhoneController,
//                 label: 'Contact Phone',
//                 keyboardType: TextInputType.phone,
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 15),
//               _buildInputField(
//                 controller: _emergencyEmailController,
//                 label: 'Contact Email',
//                 keyboardType: TextInputType.emailAddress,
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 15),
//               _buildInputField(
//                 controller: _relationshipController,
//                 label: 'Relationship',
//                 isVoice: _useVoiceInput,
//               ),
//               SizedBox(height: 30),
//               Row(
//                 children: [
//                   Text('Use Voice Input', style: TextStyle(color: Colors.white)),
//                   Switch(
//                     value: _useVoiceInput,
//                     onChanged: (value) {
//                       setState(() {
//                         _useVoiceInput = value;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Voice Authentication',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               SizedBox(height: 15),
//               Text(
//                 'Please say "Provision" 5 times for voice authentication',
//                 style: TextStyle(color: Colors.white70),
//               ),
//               SizedBox(height: 10),
//               LinearProgressIndicator(
//                 value: _voiceSamplesRecorded / 5,
//                 backgroundColor: Colors.grey,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 '$_voiceSamplesRecorded/5 samples recorded',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.white70),
//               ),
//               SizedBox(height: 15),
//               ElevatedButton.icon(
//                 onPressed: _isRecording ? null : _recordVoiceSample,
//                 icon: Icon(Icons.mic),
//                 label: Text(_isRecording ? 'Recording...' : 'Record Voice Sample'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF1B5E20),
//                   padding: EdgeInsets.symmetric(vertical: 15),
//                 ),
//               ),
//               SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: _submitForm,
//                 child: Text(
//                   'Complete Sign Up',
//                   style: TextStyle(fontSize: 18),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: Color(0xFF1B5E20),
//                   padding: EdgeInsets.symmetric(vertical: 15),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField({
//     required TextEditingController controller,
//     required String label,
//     TextInputType keyboardType = TextInputType.text,
//     bool isVoice = false,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       style: TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         labelText: label,
//         suffixIcon: isVoice
//             ? IconButton(
//                 icon: Icon(Icons.mic, color: Colors.green),
//                 onPressed: () async {
//                   // Implement voice-to-text functionality
//                   final recognizedText = await VoiceAuth.recognizeSpeech();
//                   if (recognizedText.isNotEmpty) {
//                     controller.text = recognizedText;
//                   }
//                 },
//               )
//             : null,
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter $label';
//         }
//         return null;
//       },
//     );
//   }

//   void _recordVoiceSample() async {
//     setState(() {
//       _isRecording = true;
//     });
    
//     // Simulate voice recording
//     await Future.delayed(Duration(seconds: 2));
    
//     setState(() {
//       _voiceSamplesRecorded++;
//       _isRecording = false;
//     });
    
//     if (_voiceSamplesRecorded >= 5) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Voice samples recorded successfully!')),
//       );
//     }
//   }

//   void _submitForm() {
//     if (_formKey.currentState!.validate() && _voiceSamplesRecorded >= 5) {
//       // Save user data and navigate to main page
//       Navigator.pushReplacementNamed(context, '/main');
//     } else if (_voiceSamplesRecorded < 5) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please record all 5 voice samples')),
//       );
//     }
//   }
// }

// screens/signup_page.dart
import 'package:flutter/material.dart';
import 'package:provision_sight/utils/voice_auth.dart';
import 'package:provision_sight/models/UserModel.dart';
import 'package:provision_sight/utils/app_storage.dart';
import 'package:provision_sight/services/voice_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provision_sight/utils/voice_navigator.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _emergencyEmailController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  int _voiceSamplesRecorded = 0;
  bool _isRecording = false;
  bool _useVoiceInput = false;
  List<String> _voiceSamples = [];

  late VoiceNavigator _voiceNav;
  bool _isInVoiceMode = false;

  @override
  void initState() {
    super.initState();
    _voiceNav = VoiceNavigator();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askIfVoiceGuided();
    });
  }
   @override
  void dispose() {
    _voiceNav.dispose();
    super.dispose();
  }

  void _askIfVoiceGuided() async {
    await _voiceNav.speak("Would you like me to guide you through signup using voice? Say 'yes' or 'no'.");
    final response = await _voiceNav.listenForCommand();
    if (response.toLowerCase().contains("yes")) {
      setState(() => _isInVoiceMode = true);
      _startVoiceGuidedSignup();
    } else {
      await _voiceNav.speak("Okay, you can fill the form manually. Tap any field's mic icon to use voice input.");
    }
  }
  Future<void> _waitForVoiceSamples() async {
  // Wait until 5 samples are recorded
  while (_voiceSamples.length < 5) {
    await Future.delayed(Duration(seconds: 1));
    if (!mounted) return;
  }
}

Future<void> _submitFormWithVoice() async {
  if (_formKey.currentState!.validate() && _voiceSamples.length >= 5) {
    try {
      // Create user object
      final user = User(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        emergencyContact: EmergencyContact(
          name: _emergencyNameController.text,
          phone: _emergencyPhoneController.text,
          email: _emergencyEmailController.text,
          relationship: _relationshipController.text,
        ),
        voiceSamples: _voiceSamples,
      );

      // Save user data and voice samples
      await AppStorage.saveUser(user);
      await AppStorage.saveVoiceSamples(_voiceSamples);
      await AppStorage.setLoggedIn(true);

      // Fingerprint enrollment
      try {
        final localAuth = LocalAuthentication();
        final canCheck = await localAuth.canCheckBiometrics;
        final hasFingerprint = await localAuth.isDeviceSupported();

        if (canCheck && hasFingerprint) {
          final didAuthenticate = await localAuth.authenticate(
            localizedReason: 'Enroll fingerprint for faster future logins',
          );
          if (didAuthenticate) {
            await AppStorage.saveFingerprintEnrolled(true);
            print('✅ Fingerprint enrolled successfully');
          } else {
            print('ℹ️ Fingerprint enrollment skipped by user');
          }
        }
      } catch (e) {
        print('Fingerprint enrollment skipped or failed: $e');
      }

      await _voiceNav.speak("Signup complete! Taking you to the main page now.");

      // Navigate to main page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main');
      });

    } catch (e) {
      await _voiceNav.speak("Error saving user data: $e");
    }
  } else {
    await _voiceNav.speak("Please make sure all fields are filled and you've recorded 5 voice samples.");
  }
}

  Future<void> _startVoiceGuidedSignup() async {
  // Personal Info
  _firstNameController.text = await _voiceNav.listenForField("first name");
  if (_firstNameController.text.isEmpty) return;

  _lastNameController.text = await _voiceNav.listenForField("last name");
  if (_lastNameController.text.isEmpty) return;

  _phoneController.text = await _voiceNav.listenForField("phone number");
  if (_phoneController.text.isEmpty) return;

  _emailController.text = await _voiceNav.listenForField("email address");
  if (_emailController.text.isEmpty) return;

  // Emergency Contact
  await _voiceNav.speak("Now, let's set up your emergency contact.");

  _emergencyNameController.text = await _voiceNav.listenForField("emergency contact's name");
  if (_emergencyNameController.text.isEmpty) return;

  _emergencyPhoneController.text = await _voiceNav.listenForField("emergency contact's phone number");
  if (_emergencyPhoneController.text.isEmpty) return;

  _emergencyEmailController.text = await _voiceNav.listenForField("emergency contact's email");
  if (_emergencyEmailController.text.isEmpty) return;

  _relationshipController.text = await _voiceNav.listenForField("your relationship to this contact");
  if (_relationshipController.text.isEmpty) return;

  // ➡️ STEP 1: REVIEW USER INPUT
  await _voiceNav.speak(
    "Let me read back your information. "
    "Your name is ${_firstNameController.text} ${_lastNameController.text}. "
    "Your phone is ${_phoneController.text}. "
    "Your email is ${_emailController.text}. "
    "Your emergency contact is ${_emergencyNameController.text}, "
    "phone ${_emergencyPhoneController.text}, "
    "relationship ${_relationshipController.text}. "
    "Is this correct? Say 'yes' to confirm or 'no' to start over."
  );

  final reviewConfirm = await _voiceNav.listenForCommand();
  if (!reviewConfirm.toLowerCase().contains("yes")) {
    await _voiceNav.speak("Okay, let's start over.");
    _startVoiceGuidedSignup(); // Restart
    return;
  }

  await _voiceNav.speak("Great! Now please record 5 voice samples by tapping the 'Record Voice Sample' button.");

  // Wait until samples are recorded (we'll auto-detect via state)
  await _waitForVoiceSamples();

  // ➡️ STEP 2: CONFIRM COMPLETION
  await _voiceNav.speak("You've recorded all 5 voice samples. Would you like to complete signup now? Say 'yes' or 'no'.");

  final finalConfirm = await _voiceNav.listenForCommand();
  if (finalConfirm.toLowerCase().contains("yes")) {
    await _submitFormWithVoice();
  } else {
    await _voiceNav.speak("Okay, you can complete signup later by tapping the 'Complete Sign Up' button.");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Color(0xFF1B5E20),
        actions: [
          if (_isInVoiceMode)
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: () {
                _voiceNav.stop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Voice guidance stopped.")),
                );
              },
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 20),
              _buildInputField(
                controller: _firstNameController,
                label: 'First Name',
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 15),
_buildInputField(
                controller: _lastNameController,
                label: 'Last Name',
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 15),
              _buildInputField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 15),
              _buildInputField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 30),
              Text(
                'Emergency Contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 20),
              _buildInputField(
                controller: _emergencyNameController,
                label: 'Contact Name',
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 15),
              _buildInputField(
                controller: _emergencyPhoneController,
                label: 'Contact Phone',
                keyboardType: TextInputType.phone,
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 15),
              _buildInputField(
                controller: _emergencyEmailController,
                label: 'Contact Email',
                keyboardType: TextInputType.emailAddress,
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 15),
              _buildInputField(
                controller: _relationshipController,
                label: 'Relationship',
                isVoice: _useVoiceInput,
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Text('Use Voice Input', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _useVoiceInput,
                    onChanged: (value) {
                      setState(() {
                        _useVoiceInput = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Voice Authentication',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 15),
              Text(
                'Please say "Provision" clearly when recording',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: _voiceSamplesRecorded / 5,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                '$_voiceSamplesRecorded/5 samples recorded',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
                ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _isRecording ? null : _recordVoiceSample,
                icon: Icon(Icons.mic),
                label: Text(_isRecording ? 'Recording... Say "Provision"' : 'Record Voice Sample'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B5E20),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(
                  'Complete Sign Up',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1B5E20),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // In your signup_page.dart, update the _buildInputField method:

Widget _buildInputField({
  required TextEditingController controller,
  required String label,
  TextInputType keyboardType = TextInputType.text,
  bool isVoice = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    style: TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: isVoice
          ? IconButton(
              icon: Icon(Icons.mic, color: Colors.green),
              onPressed: () async {
                VoiceService.startListening((text) {
                  setState(() {
                    controller.text = text;
                  });
                });
              },
            )
          : null,
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter $label';
      }
      
      // Email validation
      if (label.toLowerCase().contains('email') && !value.contains('@')) {
        return 'Please enter a valid email address';
      }
      
      // Phone validation
      if (label.toLowerCase().contains('phone') && value.length < 10) {
        return 'Please enter a valid phone number';
      }
      
      return null;
    },
  );
}

  // In your signup_page.dart, update the _recordVoiceSample method:

void _recordVoiceSample() async {
  setState(() {
    _isRecording = true;
  });
  
  try {
    // Record voice sample using VoiceAuth
    final samplePath = await VoiceAuth.recordAuthenticationSample();
    
    // Check audio quality
    final isGoodQuality = await VoiceAuth.checkAudioQuality(samplePath);
    
    if (isGoodQuality && samplePath.isNotEmpty) {
      setState(() {
        _voiceSamples.add(samplePath);
        _voiceSamplesRecorded = _voiceSamples.length;
      });
      
      if (_voiceSamplesRecorded >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice samples recorded successfully!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poor audio quality. Please try again in a quieter environment.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error recording voice sample: $e')),
    );
  } finally {
    setState(() {
      _isRecording = false;
    });
  }
}

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _voiceSamples.length >= 5) {
      try {
        // Create user object
        final user = User(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          emergencyContact: EmergencyContact(
            name: _emergencyNameController.text,
            phone: _emergencyPhoneController.text,
            email: _emergencyEmailController.text,
            relationship: _relationshipController.text,
          ),
          voiceSamples: _voiceSamples,
        );

        // Save user data and voice samples
        await AppStorage.saveUser(user);
        await AppStorage.saveVoiceSamples(_voiceSamples);
        await AppStorage.setLoggedIn(true);

        try {
        final localAuth = LocalAuthentication();
        final canCheck = await localAuth.canCheckBiometrics;
        final hasFingerprint = await localAuth.isDeviceSupported();

        if (canCheck && hasFingerprint) {
          final didAuthenticate = await localAuth.authenticate(
            localizedReason: 'Enroll fingerprint for faster future logins',
          );
          if (didAuthenticate) {
            await AppStorage.saveFingerprintEnrolled(true);
            print('✅ Fingerprint enrolled successfully');
          } else {
            print('ℹ️ Fingerprint enrollment skipped by user');
          }
        }
      } catch (e) {
        print('Fingerprint enrollment skipped or failed: $e');
      }

        // Navigate to main page
        Navigator.pushReplacementNamed(context, '/main');
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving user data: $e')),
        );
      }
    } else if (_voiceSamples.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record all 5 voice samples')),
      );
    }
  }
}