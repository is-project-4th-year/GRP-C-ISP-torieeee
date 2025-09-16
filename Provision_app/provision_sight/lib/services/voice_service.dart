// lib/services/voice_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final FlutterTts tts = FlutterTts();
  static final stt.SpeechToText speechToText = stt.SpeechToText();
  static final AudioRecorder audioRecorder = AudioRecorder();
  
  static bool isListening = false;
  static Function(String)? onResult;
  
  static Future<void> initialize() async {
    // Request permissions
    await Permission.microphone.request();
    await Permission.storage.request();
    
    // Initialize TTS
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.awaitSpeakCompletion(true); // ⬅️ Important: wait for speech to finish
    
    // Initialize STT
    bool available = await speechToText.initialize(
      onStatus: (status) => print('🎙️ Speech status: $status'),
      onError: (error) => print('❌ Speech error: $error'),
    );
    
    if (!available) {
      throw 'Speech to text not available';
    }
  }
  
  static Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await tts.speak(text);
  }
  
  static Future<void> startListening(Function(String) onResultCallback) async {
    if (isListening) return;
    
    onResult = onResultCallback;
    isListening = true;
    
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult && onResult != null && !result.recognizedWords.trim().isEmpty) {
          onResult!(result.recognizedWords.toLowerCase());
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: false, // ⬅️ Only final results
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }
  
  static Future<void> stopListening() async {
    if (speechToText.isListening) {
      await speechToText.stop();
    }
    isListening = false;
  }
  
  static Future<String> recordAudio(Duration duration) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    
    if (!(await Permission.microphone.request().isGranted)) {
      return '';
    }
    
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
  
  static Future<List<String>> recordVoiceSamples(int count) async {
    List<String> samples = [];
    final dir = await getApplicationDocumentsDirectory();
    
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
      
      await Future.delayed(const Duration(seconds: 2));
      final recording = await audioRecorder.stop();
      
      if (recording != null) {
        samples.add(recording);
      }
      
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
      return sampleSize > 10000;
    } catch (e) {
      print('❌ Voice verification error: $e');
      return false;
    }
  }
  
  static Future<void> disposeRecorder() async {
    await audioRecorder.dispose();
  }
}