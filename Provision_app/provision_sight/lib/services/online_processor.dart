// services/online_processor.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class OnlineProcessor {
  static final FlutterTts _tts = FlutterTts();
  static const String _serverUrl = 'http://your-server-ip:5002'; // Your Flask server

  static Future<String> sendFrameToServer(String imagePath) async {
    try {
      // Read image file
      File imageFile = File(imagePath);
      List<int> imageBytes = await imageFile.readAsBytes();
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/process_frame'),
      );
      
      // Add image file
      request.files.add(http.MultipartFile.fromBytes(
        'frame',
        imageBytes,
        filename: 'frame.jpg',
      ));
      
      // Send request
      var response = await request.send();
      
      if (response.statusCode == 200) {
        // Get the layout text response
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> responseData = jsonDecode(responseBody);
        
        // Process and convert to speech
        String layoutDescription = await _processLayoutResponse(responseData);
        await _tts.speak(layoutDescription);
        
        return layoutDescription;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      await _tts.speak("Error connecting to server. Please check your internet connection.");
      return "Connection error: $e";
    }
  }

  static Future<String> _processLayoutResponse(Map<String, dynamic> responseData) async {
    // Extract layout information and convert to natural language
    String rawLayout = responseData['layout_text'] ?? '';
    
    // Simple processing - you can enhance this with more sophisticated NLP
    String naturalLanguage = _convertToNaturalLanguage(rawLayout);
    
    return naturalLanguage;
  }

  static String _convertToNaturalLanguage(String technicalLayout) {
    // This is a simplified conversion - you might want to use a proper NLP approach
    return technicalLayout
        .replaceAll('wall', 'wall ahead')
        .replaceAll('door', 'doorway')
        .replaceAll('window', 'window to your')
        .replaceAll('box', 'object')
        + ". Please navigate carefully.";
  }

  static Future<void> startContinuousProcessing(Function(String) onUpdate) async {
    // Continuous frame processing every 30 seconds
    while (true) {
      try {
        // This would integrate with camera to capture frames periodically
        // For now, this is a placeholder for the continuous processing logic
        await Future.delayed(Duration(seconds: 30));
      } catch (e) {
        print("Continuous processing error: $e");
      }
    }
  }
}