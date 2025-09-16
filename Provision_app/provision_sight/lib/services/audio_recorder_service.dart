// services/audio_recorder_service.dart
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<String> startRecording(int durationSeconds) async {
    try {
      // Check and request permissions
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Start recording
      final path = '/emergency_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      // Record for specified duration
      await Future.delayed(Duration(seconds: durationSeconds));
      
      // Stop recording
      await _recorder.stop();
      
      return path;
    } catch (e) {
      throw Exception('Recording failed: $e');
    }
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}