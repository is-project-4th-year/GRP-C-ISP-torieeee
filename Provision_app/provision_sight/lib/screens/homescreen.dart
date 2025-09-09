// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/voice_auth_service.dart';
import '../services/mode_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceAuthService _voiceService = VoiceAuthService();
  final ModeService _modeService = ModeService();
  final FlutterTts _tts = FlutterTts();
  final Box _userBox = Hive.box('userData');
  final Box _settingsBox = Hive.box('appSettings');

  bool _isOnline = true;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _askForMode();
  }

  void _loadSettings() {
    _isOnline = _settingsBox.get('isOnline', defaultValue: true);
  }

  Future<void> _askForMode() async {
    await Future.delayed(Duration(seconds: 1));
    await _tts.speak("Welcome to Provision. Would you like to use the offline or online version of the app?");
    
    await _listenForModeSelection();
  }

  Future<void> _listenForModeSelection() async {
    setState(() => _isListening = true);
    
    final SpeechToText speech = SpeechToText();
    bool available = await speech.initialize();
    
    if (available) {
      await speech.listen(
        onResult: (result) async {
          String command = result.recognizedWords.toLowerCase();
          
          if (command.contains('offline')) {
            await _switchToOffline();
          } else if (command.contains('online')) {
            await _switchToOnline();
          }
        },
        listenFor: Duration(seconds: 10),
      );
    }
    
    setState(() => _isListening = false);
  }

  Future<void> _switchToOffline() async {
    setState(() => _isOnline = false);
    await _settingsBox.put('isOnline', false);
    await _tts.speak("Offline mode activated. Computer vision will guide you.");
  }

  Future<void> _switchToOnline() async {
    setState(() => _isOnline = true);
    await _settingsBox.put('isOnline', true);
    await _tts.speak("Online mode activated. Connecting to spatial intelligence server.");
  }

  Future<void> _handleCommand(String command) async {
    switch (command) {
      case 'guide':
        _navigateToGuide();
        break;
      case 'help':
        _triggerEmergencyHelp();
        break;
      case 'view profile':
        _navigateToProfile();
        break;
      case 'assistance':
        _provideAssistance();
        break;
      default:
        await _tts.speak("Command not recognized. Please say guide, help, view profile, or assistance.");
    }
  }

  Future<void> _navigateToGuide() async {
    await _tts.speak("Starting navigation guide.");
    // Navigate to guide screen
  }

  Future<void> _triggerEmergencyHelp() async {
    await _tts.speak("Emergency help activated. Contacting your emergency contact.");
    // Implement emergency help functionality
  }

  Future<void> _navigateToProfile() async {
    await _tts.speak("Opening your profile.");
    // Navigate to profile screen
  }

  Future<void> _provideAssistance() async {
    String commands = """
    Available commands: 
    Guide - Starts navigation assistance
    Help - Contacts emergency help
    View Profile - Shows your profile information
    Assistance - Lists all available commands
    Switch mode - Changes between online and offline modes
    """;
    
    await _tts.speak(commands);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Provision Assistant"),
        leading: Switch(
          value: _isOnline,
          onChanged: (value) async {
            setState(() => _isOnline = value);
            await _settingsBox.put('isOnline', value);
            await _tts.speak(value ? "Online mode activated" : "Offline mode activated");
          },
        ),
      ),
      body: Column(
        children: [
          if (_isListening)
            LinearProgressIndicator(),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _buildOptionButton(Icons.navigation, "Guide", Colors.blue, _navigateToGuide),
                _buildOptionButton(Icons.emergency, "Help", Colors.red, _triggerEmergencyHelp),
                _buildOptionButton(Icons.person, "View Profile", Colors.green, _navigateToProfile),
                _buildOptionButton(Icons.help, "Assistance", Colors.orange, _provideAssistance),
              ],
            ),
          ),
          
          // Voice command button
          Padding(
            padding: EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _listenForVoiceCommand,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _listenForVoiceCommand() async {
    setState(() => _isListening = true);
    
    final SpeechToText speech = SpeechToText();
    bool available = await speech.initialize();
    
    if (available) {
      await speech.listen(
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          _handleCommand(command);
        },
        listenFor: Duration(seconds: 5),
      );
    }
    
    setState(() => _isListening = false);
  }
}