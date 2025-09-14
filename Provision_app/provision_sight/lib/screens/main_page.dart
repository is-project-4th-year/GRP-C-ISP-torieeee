// screens/main_page.dart
import 'package:flutter/material.dart';
import 'package:provision_sight/utils/voice_commands.dart';

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
    VoiceCommands.listen((command) {
      setState(() {
        _lastCommand = command;
        _isListening = false;
      });
      
      _handleVoiceCommand(command);
      
      // Restart listening after a short delay
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isListening = true;
          });
        }
      });
    });
    
    setState(() {
      _isListening = true;
    });
  }

  void _handleVoiceCommand(String command) {
    switch (command) {
      case 'guide':
        Navigator.pushNamed(context, '/guide');
        break;
      case 'activate':
        // Handle activate command
        break;
      case 'help':
        _handleEmergency();
        break;
      case 'assist':
        // Handle assist command
        break;
      default:
        print('Unknown command: $command');
    }
  }

  void _handleEmergency() {
    // Implement emergency handling
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
              // Implement emergency call
            },
            child: Text('Call'),
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
                  onTap: () {
                    // Show help information
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Voice Commands'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Say "guide" for navigation assistance'),
                            Text('• Say "activate" for...'),
                            Text('• Say "help" for emergency assistance'),
                            Text('• Say "assist" for...'),
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
                  },
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
    VoiceCommands.stopListening();
    super.dispose();
  }
}