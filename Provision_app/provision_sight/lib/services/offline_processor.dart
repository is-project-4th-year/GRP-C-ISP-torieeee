// services/offline_processor.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'vision_service.dart';

class OfflineProcessor {
  static final FlutterTts _tts = FlutterTts();
  static bool _isProcessing = false;
  static bool _isContinuousMode = false;

  // Initialize offline processing system
  static Future<void> initialize() async {
    try {
      await VisionService.initialize();
      await _tts.awaitSpeakCompletion(true);
      print("Offline processor initialized");
    } catch (e) {
      print("Offline processor initialization failed: $e");
      throw Exception("Offline vision system unavailable");
    }
  }

  // Process image from file
  static Future<void> processImage(String imagePath) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final description = await VisionService.analyzeImage(imagePath);
      await _tts.speak(description);
    } catch (e) {
      await _tts.speak("Sorry, I couldn't process the image. Please try again.");
    } finally {
      _isProcessing = false;
    }
  }

  // Process camera frame - REAL IMPLEMENTATION
  static Future<void> processCameraFrame(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Convert CameraImage to a format MediaPipe can process
      final imageFile = await _convertCameraImageToFile(cameraImage);
      final description = await VisionService.analyzeImage(imageFile.path);
      
      await _tts.speak(description);
      
      // Clean up temporary file
      await imageFile.delete();
    } catch (e) {
      print("Camera frame processing error: $e");
      await _tts.speak("Vision processing temporarily unavailable.");
    } finally {
      _isProcessing = false;
    }
  }

  // Convert CameraImage to File - REAL IMPLEMENTATION
  static Future<File> _convertCameraImageToFile(CameraImage cameraImage) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Convert based on image format
      img.Image image;
      
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        image = _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        image = _convertBGRA8888ToImage(cameraImage);
      } else {
        throw Exception('Unsupported image format: ${cameraImage.format}');
      }
      
      // Save as JPEG
      final jpegBytes = img.encodeJpg(image);
      await tempFile.writeAsBytes(jpegBytes);
      
      return tempFile;
    } catch (e) {
      print("Image conversion error: $e");
      throw Exception("Failed to process camera image: $e");
    }
  }

  // Convert YUV420 to Image
  static img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;
    
    final image = img.Image(width, height);
    
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
        
        final yValue = yBuffer[yIndex];
        final uValue = uBuffer[uvIndex];
        final vValue = vBuffer[uvIndex];
        
        // Convert YUV to RGB
        final r = _yuvToR(yValue, uValue, vValue);
        final g = _yuvToG(yValue, uValue, vValue);
        final b = _yuvToB(yValue, uValue, vValue);
        
        image.setPixelRgba(x, y, r, g, b);
      }
    }
    
    return image;
  }

  // Convert BGRA8888 to Image
  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final bytes = cameraImage.planes[0].bytes;
    
    final image = img.Image(width, height);
    
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final index = (y * width + x) * 4;
        final b = bytes[index];
        final g = bytes[index + 1];
        final r = bytes[index + 2];
        // final a = bytes[index + 3]; // Alpha channel, not used
        
        image.setPixelRgba(x, y, r, g, b);
      }
    }
    
    return image;
  }

  // YUV to RGB conversion helpers
  static int _yuvToR(int y, int u, int v) {
    final r = (y + 1.402 * (v - 128)).clamp(0, 255).toInt();
    return r;
  }

  static int _yuvToG(int y, int u, int v) {
    final g = (y - 0.344 * (u - 128) - 0.714 * (v - 128)).clamp(0, 255).toInt();
    return g;
  }

  static int _yuvToB(int y, int u, int v) {
    final b = (y + 1.772 * (u - 128)).clamp(0, 255).toInt();
    return b;
  }

  // Continuous guidance mode - REAL IMPLEMENTATION
  static Future<void> startContinuousGuidance(CameraController cameraController) async {
    _isContinuousMode = true;
    
    await _tts.speak("Starting continuous spatial guidance. I will describe your surroundings every 10 seconds.");

    while (_isContinuousMode && !_isProcessing) {
      try {
        // Capture frame from camera
        final image = await cameraController.takePicture();
        
        // Process the image
        _isProcessing = true;
        final description = await VisionService.analyzeImage(image.path);
        await _tts.speak(description);
        
        // Delete temporary image file
        await File(image.path).delete();
        
        _isProcessing = false;
        
        // Wait before next capture
        await Future.delayed(Duration(seconds: 10));
      } catch (e) {
        print("Continuous guidance error: $e");
        _isProcessing = false;
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  // Stop continuous guidance
  static void stopContinuousGuidance() {
    _isContinuousMode = false;
  }

  // Process single frame from camera controller
  static Future<void> processSingleFrame(CameraController cameraController) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final image = await cameraController.takePicture();
      await processImage(image.path);
      
      // Clean up
      await File(image.path).delete();
    } catch (e) {
      await _tts.speak("Failed to capture image. Please try again.");
    } finally {
      _isProcessing = false;
    }
  }

  // Stop processing
  static void stopProcessing() {
    _isProcessing = false;
    _isContinuousMode = false;
    VisionService.dispose();
  }

  // Get system status
  static String getStatus() {
    if (_isContinuousMode) return "Continuous Guidance";
    return _isProcessing ? "Processing" : "Ready";
  }

  // Check if system is busy
  static bool get isProcessing => _isProcessing;
  static bool get isContinuousMode => _isContinuousMode;
}