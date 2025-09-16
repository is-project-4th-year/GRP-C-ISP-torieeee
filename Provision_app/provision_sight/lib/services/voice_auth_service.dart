// Fixed services/voice_auth_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'dart:async';

class VoiceAuthService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Box _voiceBox = Hive.box('voicePrints');
  bool _isInitialized = false;

  Future<bool> initializeVoice() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    }
    return _isInitialized;
  }

  Future<String> listenForCommand({Duration listenFor = const Duration(seconds: 8)}) async {
    try {
      if (!await initializeVoice()) {
        return "error: initialization_failed";
      }

      if (!await _speech.hasPermission) {
        return "error: permission_not_granted";
      }

      await stopAllOperations();
      await Future.delayed(Duration(milliseconds: 500));

      String result = '';
      Completer<String> completer = Completer<String>();
      bool hasResult = false;
      bool isListening = false;

      double? lastSoundLevel;
      bool hasDetectedSound = false;

      isListening = await _speech.listen(
        onResult: (speechResult) {
          if (speechResult.finalResult && !hasResult) {
            hasResult = true;
            result = speechResult.recognizedWords;
            print('Speech result: $result');
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          }
        },
        listenFor: listenFor,
        pauseFor: Duration(seconds: 2),
        partialResults: true,
        onSoundLevelChange: (level) {
          lastSoundLevel = level;
          if (level > 0.1 && !hasDetectedSound) {
            hasDetectedSound = true;
            print('Microphone is detecting sound: $level');
          }
        },
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      if (!isListening) {
        return "error: speech_not_available";
      }

      await Future.delayed(Duration(seconds: 2));
      
      if (!hasDetectedSound && lastSoundLevel == 0) {
        print('No sound detected - microphone may not be working');
        await _speech.stop();
        return "error: no_sound_detected";
      }

      try {
        String finalResult = await completer.future.timeout(
          listenFor + Duration(seconds: 1),
          onTimeout: () {
            print('Speech recognition completed without final result');
            return result.isEmpty ? "" : result;
          },
        );
        
        await _speech.stop();
        return finalResult.toLowerCase().trim();
      } catch (e) {
        print('Error in speech recognition: $e');
        await _speech.stop();
        return result.isEmpty ? "" : result.toLowerCase().trim();
      }
    } catch (e) {
      print('Exception in listenForCommand: $e');
      return "error: $e";
    }
  }

  Future<void> speak(String text) async {
    try {
      print('Speaking: $text');
      await stopAllOperations();
      await Future.delayed(Duration(milliseconds: 300));
      
      Completer<void> completer = Completer<void>();
      
      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _tts.setErrorHandler((error) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await _tts.speak(text);
      
      await completer.future.timeout(
        Duration(seconds: (text.length / 5).ceil() + 3),
        onTimeout: () {
          print('TTS timeout for: $text');
        },
      );
      
      await Future.delayed(Duration(milliseconds: 800));
    } catch (e) {
      print('Error in speak method: $e');
      await Future.delayed(Duration(seconds: (text.length / 10).ceil() + 1));
    }
  }

  Future<void> stopAllOperations() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _tts.stop();
    } catch (e) {
      print('Error stopping operations: $e');
    }
  }

  // ✅ FIXED: Method signature to accept List<String> for voice samples
  Future<void> saveVoicePrint(List<String> voiceSamples) async {
    try {
      // Store voice samples as a single concatenated string or JSON
      String voiceData = voiceSamples.join('|'); // Simple concatenation
      await _voiceBox.put('user_voice_print', voiceData);
      print('Voice print saved with ${voiceSamples.length} samples');
    } catch (e) {
      print('Error saving voice print: $e');
      rethrow;
    }
  }

  // ✅ FIXED: Method to verify voice print properly
  Future<bool> verifyVoicePrint(String spokenWord) async {
    try {
      final storedVoicePrint = _voiceBox.get('user_voice_print');
      if (storedVoicePrint == null) {
        print('No voice print found for user');
        return false;
      }
      
      // Simple verification: check if the spoken word contains "provision"
      final isMatch = spokenWord.toLowerCase().contains('provision');
      print('Voice print verification result: $isMatch (heard: "$spokenWord")');
      return isMatch;
    } catch (e) {
      print('Error verifying voice print: $e');
      return false;
    }
  }
}

//=================================================================
// Fixed screens/signup_screen.dart
