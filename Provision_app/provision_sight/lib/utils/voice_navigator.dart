// lib/services/voice_navigator.dart
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provision_sight/services/voice_service.dart';

class VoiceNavigator {
  final FlutterTts _tts = VoiceService.tts;
  bool _isSpeaking = false;
  bool _isListening = false;

  VoiceNavigator() {
    // TTS is already initialized in VoiceService
  }

  // Speak instruction aloud
  Future<void> speak(String text) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    await _tts.speak(text);
    _isSpeaking = false;
  }

  // Stop current speech
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    if (_isListening) {
      await VoiceService.stopListening();
      _isListening = false;
    }
  }

  // Listen for a command with timeout and retry
  Future<String> listenForCommand({int maxRetries = 2}) async {
    for (int i = 0; i <= maxRetries; i++) {
      Completer<String> completer = Completer();
      _isListening = true;

      VoiceService.startListening((text) {
        if (!completer.isCompleted) {
          completer.complete(text);
        }
      });

      try {
        String result = await completer.future.timeout(
          Duration(seconds: 8),
          onTimeout: () => "timeout",
        );

        await VoiceService.stopListening();
        _isListening = false;

        if (result == "timeout") {
          if (i < maxRetries) {
            await speak("I didn't hear you. Please try again.");
            continue;
          } else {
            await speak("I'm having trouble hearing you. You can use the screen buttons.");
            return "cancel";
          }
        }

        if (result.toLowerCase().contains("cancel") || result.toLowerCase().contains("stop")) {
          await speak("Cancelled.");
          return "cancel";
        }

        return result;
      } catch (e) {
        await VoiceService.stopListening();
        _isListening = false;
        if (i < maxRetries) {
          await speak("Error occurred. Please try again.");
          continue;
        }
        return "cancel";
      }
    }
    return "cancel";
  }

  // Listen and auto-fill field — speaks prompt + listens + confirms
  Future<String> listenForField(String fieldName) async {
    await speak("Please say your $fieldName.");
    final input = await listenForCommand();

    if (input == "cancel") return "";

    await speak("You said: $input. If correct, I'll proceed. If not, say 'cancel' now.");
    final confirm = await listenForCommand(maxRetries: 1);

    if (confirm.toLowerCase().contains("cancel")) {
      await speak("Okay, let's try again.");
      return await listenForField(fieldName); // Recursive retry
    }

    return input;
  }

  void dispose() {
    _tts.stop();
  }
}