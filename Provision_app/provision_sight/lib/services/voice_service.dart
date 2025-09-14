// services/voice_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final FlutterTts tts = FlutterTts();
  static final stt.SpeechToText speechToText = stt.SpeechToText();
  static final AudioRecorder audioRecorder = AudioRecorder();
  
  static bool isListening = false;
  static Function(String)? onResult;
  
  static Future<void> initialize() async {
    // Request microphone permission
    await Permission.microphone.request();
    
    // Initialize text-to-speech
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    
    // Initialize speech-to-text
    bool available = await speechToText.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    
    if (!available) {
      throw 'Speech to text not available';
    }
  }
  
  static Future<void> speak(String text) async {
    await tts.speak(text);
    await tts.awaitSpeakCompletion(true);
  }
  
  static Future<void> startListening(Function(String) onResultCallback) async {
    if (isListening) return;
    
    onResult = onResultCallback;
    isListening = true;
    
    // Start listening for speech
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult && onResult != null) {
          onResult!(result.recognizedWords.toLowerCase());
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }
  
  static Future<void> stopListening() async {
    await speechToText.stop();
    isListening = false;
  }
  
  static Future<String> recordAudio(Duration duration) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    // Check and request permission
    if (await Permission.microphone.request().isGranted) {
      await audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
        ),
        path: path,
      );
      
      await Future.delayed(duration);
      final recording = await audioRecorder.stop();
      
      return recording ?? path;
    }
    
    return '';
  }
  
  static Future<List<String>> recordVoiceSamples(int count) async {
    List<String> samples = [];
    final dir = await getApplicationDocumentsDirectory();
    
    // Check and request permission
    if (!(await Permission.microphone.request().isGranted)) {
      return samples;
    }
    
    for (int i = 0; i < count; i++) {
      final path = '${dir.path}/voice_sample_$i.m4a';
      
      await audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
        ),
        path: path,
      );
      
      // Record for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      final recording = await audioRecorder.stop();
      
      if (recording != null) {
        samples.add(recording);
      }
      
      // Wait before next recording
      if (i < count - 1) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    return samples;
  }
  
  static Future<bool> verifyVoiceSample(String samplePath, List<String> storedSamples) async {
    try {
      final sampleFile = File(samplePath);
      if (!await sampleFile.exists()) return false;
      
      final sampleSize = await sampleFile.length();
      
      // Basic validation - check if file has reasonable size
      return sampleSize > 10000; // At least 10KB
    } catch (e) {
      print('Voice verification error: $e');
      return false;
    }
  }
  
  static Future<void> disposeRecorder() async {
    await audioRecorder.dispose();
  }
}