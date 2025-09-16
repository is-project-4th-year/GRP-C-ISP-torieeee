// screens/main_page.dart
import 'package:flutter/material.dart';
import 'package:provision_sight/services/voice_service.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isOnline = true;
  bool _isListening = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _startVoiceListener();
  }

  void _startVoiceListener() async {
  // Small delay to let UI settle
  await Future.delayed(Duration(milliseconds: 500));

  VoiceService.speak(
    "Welcome to your main page! "
    "You can say: "
    "'guide' for navigation assistance, "
    "'help' for emergency, "
    "'profile' to view your information, "
    "or 'emergency' to view your contact. "
    "What would you like to do?"
  );

  VoiceService.startListening((command) {
    setState(() {
      _lastCommand = command;
    });
    _handleVoiceCommand(command);
  });

  setState(() {
    _isListening = true;
  });
}

void _handleVoiceCommand(String command) {
  command = command.toLowerCase();
  
  if (command.contains("guide")) {
    VoiceService.speak("Opening guide page.");
    Navigator.pushNamed(context, '/guide');
  } else if (command.contains("help")) {
    VoiceService.speak("Initiating emergency protocol.");
    _handleEmergency();
  } else if (command.contains("profile")) {
    VoiceService.speak("Opening your profile.");
    Navigator.pushNamed(context, '/profile');
  } else if (command.contains("emergency") || command.contains("contact")) {
    VoiceService.speak("Opening emergency contact information.");
    Navigator.pushNamed(context, '/emergency');
  } else if (command.contains("assist") || command.contains("help info")) {
    VoiceService.speak("Showing help information.");
    _showHelpDialog();
  } else {
    VoiceService.speak("I didn't understand. You can say 'guide', 'help', 'profile', or 'emergency'.");
  }
}

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Alert'),
        content: Text('Calling emergency contact...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              VoiceService.speak("Emergency call initiated.");
              // TODO: Implement actual call
            },
            child: Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voice Commands'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Say "guide" for navigation assistance'),
            Text('• Say "help" for emergency assistance'),
            Text('• Say "profile" to view your profile'),
            Text('• Say "emergency" to view emergency contact'),
            Text('• Say "assist" for help information'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provision'),
        backgroundColor: Color(0xFF1B5E20),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.greenAccent,
          ),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice command status
          Container(
            padding: EdgeInsets.all(10),
            color: _isListening ? Colors.green[800] : Colors.grey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                Text(
                  _isListening ? 'Listening...' : 'Not Listening',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Last command display
          if (_lastCommand.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.green[900],
              child: Text(
                'Last command: "$_lastCommand"',
                style: TextStyle(color: Colors.white),
              ),
            ),
          
          // Main content
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(20),
              childAspectRatio: 1.5,
              children: [
                _buildFeatureButton(
                  icon: Icons.explore,
                  label: 'Guide',
                  onTap: () => Navigator.pushNamed(context, '/guide'),
                ),
                _buildFeatureButton(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _buildFeatureButton(
                  icon: Icons.contact_emergency,
                  label: 'Emergency Contact',
                  onTap: () => Navigator.pushNamed(context, '/emergency'),
                ),
                _buildFeatureButton(
                  icon: Icons.help,
                  label: 'Help Info',
                  onTap: _showHelpDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Color(0xFF2E7D32),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    VoiceService.stopListening();
    super.dispose();
  }
}