// services/emergency_service.dart
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencyService {
  final Box _userBox = Hive.box('userData');
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _lastHelpRequest;
  int _helpCount = 0;

  Future<void> triggerEmergencyHelp() async {
    final now = DateTime.now();
    
    // Check if this is the second "help" within 10 seconds
    if (_lastHelpRequest != null && 
        now.difference(_lastHelpRequest!) < Duration(seconds: 10)) {
      _helpCount++;
      
      if (_helpCount >= 2) {
        await _callEmergencyContact();
        return;
      }
    } else {
      _helpCount = 1;
    }
    
    _lastHelpRequest = now;
    
    await _tts.speak("Emergency help activated. Recording message and sending location.");
    
    // Record 10-second message
    final audioPath = await _recordEmergencyMessage();
    
    // Get current location
    final position = await _getCurrentLocation();
    
    // Send to emergency contact
    await _sendEmergencyAlert(audioPath, position);
    
    await _tts.speak("Help has been contacted. Your emergency contact has been notified.");
  }

  Future<String> _recordEmergencyMessage() async {
    final path = '/emergency_message.aac';
    await _recorder.start(const RecordConfig(), path: path);
    
    await Future.delayed(Duration(seconds: 10));
    await _recorder.stop();
    
    return path;
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _sendEmergencyAlert(String audioPath, Position position) async {
    final contact = _userBox.get('userProfile')['emergencyContact'];
    final message = """
    EMERGENCY ALERT from ${_userBox.get('userProfile')['firstName']}!
    Location: ${position.latitude}, ${position.longitude}
    Time: ${DateTime.now()}
    """;
    
    // Send SMS with location
    final smsUrl = 'sms:${contact['phone']}?body=${Uri.encodeComponent(message)}';
    if (await canLaunch(smsUrl)) {
      await launch(smsUrl);
    }
    
    // TODO: Send audio file via email or other service
  }

  Future<void> _callEmergencyContact() async {
    final contact = _userBox.get('userProfile')['emergencyContact'];
    final phoneUrl = 'tel:${contact['phone']}';
    
    if (await canLaunch(phoneUrl)) {
      await launch(phoneUrl);
      await _tts.speak("Calling your emergency contact now.");
    }
  }
}