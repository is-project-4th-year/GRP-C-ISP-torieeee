// utils/voice_auth.dart
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAuth {
  static final AudioRecorder recorder = AudioRecorder();
  static final stt.SpeechToText speechToText = stt.SpeechToText();
  
  // Record a single authentication sample
  static Future<String> recordAuthenticationSample() async {
    // Request microphone permission
    if (!(await Permission.microphone.request().isGranted)) {
      throw 'Microphone permission denied';
    }
    
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/auth_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    // Start recording
    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
      ),
      path: path,
    );
    
    // Record for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    // Stop recording
    final recordingPath = await recorder.stop();
    
    return recordingPath ?? path;
  }
  
  // Record multiple voice samples for enrollment
  static Future<List<String>> recordSamples(int count) async {
    List<String> samplePaths = [];
    
    // Request microphone permission
    if (!(await Permission.microphone.request().isGranted)) {
      return samplePaths;
    }
    
    final dir = await getApplicationDocumentsDirectory();
    
    for (int i = 0; i < count; i++) {
      final path = '${dir.path}/enrollment_sample_$i.m4a';
      
      // Start recording
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
        ),
        path: path,
      );
      
      // Record for 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      
      // Stop recording
      final recording = await recorder.stop();
      
      if (recording != null) {
        samplePaths.add(recording);
      }
      
      // Wait before next recording
      if (i < count - 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    return samplePaths;
  }
  
  // Authenticate using voice
  static Future<bool> authenticate(List<String> storedSamples) async {
    if (storedSamples.isEmpty) {
      return false;
    }
    
    // Request microphone permission
    if (!(await Permission.microphone.request().isGranted)) {
      return false;
    }
    
    final dir = await getApplicationDocumentsDirectory();
    final currentSamplePath = '${dir.path}/current_auth_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    // Start recording
    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
      ),
      path: currentSamplePath,
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    // Stop recording
    final recording = await recorder.stop();
    final actualPath = recording ?? currentSamplePath;
    
    // Compare with stored samples
    return await _compareVoiceSamples(actualPath, storedSamples);
  }
  
  // Speech-to-text recognition
  static Future<String> recognizeSpeech() async {
    // Initialize speech to text if not already done
    bool available = await speechToText.initialize();
    if (!available) {
      return "Speech recognition not available";
    }
    
    Completer<String> completer = Completer();
    
    speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          completer.complete(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
    );
    
    // Wait for recognition to complete or timeout
    try {
      return await completer.future.timeout(const Duration(seconds: 6));
    } catch (e) {
      await speechToText.stop();
      return "No speech detected";
    }
  }
  
  // Compare voice samples for authentication
  static Future<bool> _compareVoiceSamples(String currentSample, List<String> storedSamples) async {
    try {
      final currentFile = File(currentSample);
      if (!await currentFile.exists()) return false;
      
      final currentSize = await currentFile.length();
      
      // Basic validation - check if file has reasonable size
      if (currentSize < 50000) { // At least 50KB
        return false;
      }
      
      // Check if we have stored samples
      if (storedSamples.isEmpty) return false;
      
      // For a real implementation, you would use audio signal processing here
      // This is a simplified version that checks file properties
      int validMatches = 0;
      
      for (String storedPath in storedSamples) {
        final storedFile = File(storedPath);
        if (await storedFile.exists()) {
          final storedSize = await storedFile.length();
          
          // Allow 40% size difference as a simple check
          final sizeDifference = (currentSize - storedSize).abs();
          if (sizeDifference < storedSize * 0.4) {
            validMatches++;
          }
        }
      }
      
      // Require at least 60% of samples to match
      return validMatches >= (storedSamples.length * 0.6);
    } catch (e) {
      print('Voice comparison error: $e');
      return false;
    }
  }
  
  // Verify if a specific phrase was spoken
  static Future<bool> verifyPhrase(String expectedPhrase) async {
    final recognizedText = await recognizeSpeech();
    return recognizedText.toLowerCase().contains(expectedPhrase.toLowerCase());
  }
  
  // Clean up old voice samples
  static Future<void> cleanupSamples(List<String> samplePaths) async {
    for (String path in samplePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting sample $path: $e');
      }
    }
  }
  
  // Get audio file duration (simplified)
  static Future<Duration> getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        // Rough estimation: 1MB ≈ 1 minute of audio
        return Duration(seconds: (size / 17000).round());
      }
    } catch (e) {
      print('Error getting audio duration: $e');
    }
    return Duration.zero;
  }
  
  // Check if audio quality is sufficient
  static Future<bool> checkAudioQuality(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final size = await file.length();
        // Check if file size is within expected range for a 3-second recording
        return size > 40000 && size < 200000;
      }
    } catch (e) {
      print('Error checking audio quality: $e');
    }
    return false;
  }
  
  // Check if recording is currently in progress
  static Future<bool> isRecording() async {
    return await recorder.isRecording();
  }
  
  // Dispose the recorder when done
  static Future<void> dispose() async {
    await recorder.dispose();
  }
}