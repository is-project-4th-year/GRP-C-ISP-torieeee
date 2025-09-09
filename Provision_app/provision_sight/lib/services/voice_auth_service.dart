// services/voice_auth_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';

class VoiceAuthService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Box _voiceBox = Hive.box('voicePrints');
  
  Future<bool> initializeVoice() async {
    return await _speech.initialize();
  }

  Future<String> listenForCommand({Duration listenFor = const Duration(seconds: 5)}) async {
    String result = '';
    
    await _speech.listen(
      onResult: (speechResult) => result = speechResult.recognizedWords,
      listenFor: listenFor,
    );
    
    await Future.delayed(listenFor); // Wait for listening to complete
    return result.toLowerCase().trim();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
    await Future.delayed(Duration(seconds: text.length ~/ 10 + 2)); // Wait for speech to complete
  }

  Future<void> saveVoicePrint(List<String> voiceSamples) async {
    await _voiceBox.put('provisionSamples', voiceSamples);
  }

  List<String> getVoicePrints() {
    return _voiceBox.get('provisionSamples', defaultValue: []);
  }

  bool verifyVoicePrint(String currentAttempt) {
    final savedSamples = getVoicePrints();
    if (savedSamples.isEmpty) return false;
    
    // Simple verification - you can enhance this with audio analysis later
    return savedSamples.any((sample) => 
        _isVoiceMatch(sample, currentAttempt));
  }

  bool _isVoiceMatch(String sample1, String sample2) {
    // Basic text matching - for now we'll just check the words
    // In a real app, you'd analyze audio characteristics like pitch, tone, etc.
    return sample1 == sample2 && sample1 == "provision";
  }

  Future<void> clearVoicePrints() async {
    await _voiceBox.delete('provisionSamples');
  }
}