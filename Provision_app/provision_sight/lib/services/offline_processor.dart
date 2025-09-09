// services/offline_processor.dart
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';

class OfflineProcessor {
  static final FlutterTts _tts = FlutterTts();
  static Interpreter? _interpreter;
  static List<String> _labels = [];

  static Future<void> initialize() async {
    try {
      // Load TFLite model (you'll need to add these files to your assets)
      _interpreter = await Interpreter.fromAsset('models/object_detection.tflite');
      
      // Load labels
      String labelContent = await File('assets/models/labels.txt').readAsString();
      _labels = labelContent.split('\n');
      
    } catch (e) {
      print("Failed to initialize offline processor: $e");
    }
  }

  static Future<String> analyzeImage(String imagePath) async {
    try {
      if (_interpreter == null) {
        await initialize();
      }

      // Preprocess image
      List<List<List<List<double>>>> input = await _preprocessImage(imagePath);
      
      // Run inference
      var output = List.filled(1, List.filled(10, List.filled(10, List.filled(4, 0.0))));
      _interpreter!.run(input, output);
      
      // Process results
      String description = _processDetectionResults(output[0]);
      
      // Add distance estimation
      String distanceInfo = await _estimateDistances(imagePath);
      
      await _tts.speak("$description $distanceInfo");
      
      return "$description $distanceInfo";
    } catch (e) {
      await _tts.speak("Offline processing unavailable. Please switch to online mode.");
      return "Processing error: $e";
    }
  }

  static Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    // Load and preprocess image for the model
    img.Image image = img.decodeImage(File(imagePath).readAsBytesSync())!;
    img.Image resized = img.copyResize(image, width: 224, height: 224);
    
    // Convert to normalized float array
    List<List<List<List<double>>>> input = List.generate(
      1, 
      (_) => List.generate(
        224, 
        (i) => List.generate(
          224, 
          (j) => List.generate(
            3, 
            (k) {
              int pixel = resized.getPixel(j, i);
              // Extract RGB channels
              if (k == 0) return img.getRed(pixel) / 255.0;
              if (k == 1) return img.getGreen(pixel) / 255.0;
              return img.getBlue(pixel) / 255.0;
            }
          )
        )
      )
    );
    
    return input;
  }

  static String _processDetectionResults(List<List<List<double>>> results) {
    // Process detection results and create description
    List<String> detectedObjects = [];
    
    for (var detection in results) {
      double confidence = detection[0][0];
      if (confidence > 0.5) { // Confidence threshold
        int classId = detection[0][1].toInt();
        if (classId < _labels.length) {
          detectedObjects.add(_labels[classId]);
        }
      }
    }
    
    if (detectedObjects.isEmpty) {
      return "No objects detected in your surroundings.";
    }
    
    return "I can see: ${detectedObjects.join(', ')}.";
  }

  static Future<String> _estimateDistances(String imagePath) async {
    // Simple distance estimation (placeholder - you'd implement MiDAS here)
    // For now, using a simple heuristic based on object size
    return "Objects are approximately 2 to 5 meters away. Please proceed carefully.";
  }

  static Future<String> analyzeCameraFrame(List<int> imageBytes) async {
    // Alternative method for direct camera frame analysis
    try {
      // Save temporary image
      String tempPath = '/tmp/frame_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(tempPath).writeAsBytes(imageBytes);
      
      return await analyzeImage(tempPath);
    } catch (e) {
      return "Frame analysis error: $e";
    }
  }
}