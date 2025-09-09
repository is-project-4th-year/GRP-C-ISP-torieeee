// services/vision_service.dart
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

class VisionService {
  // static final FlutterTts _tts = FlutterTts(); // Removed unused field
  static ObjectDetector? _detector;
  static bool _isInitialized = false;

  // Initialize Google ML Kit with DEFAULT model
  static Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // ✅ Use the DEFAULT built-in model (no need to download anything)
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single,    // Changed from stream to single
        classifyObjects: true,
        multipleObjects: true,
      );

      _detector = ObjectDetector(options: options);
      _isInitialized = true;
      print("✅ Google ML Kit Vision Service initialized successfully");
    } catch (e) {
      print("❌ ML Kit initialization failed: $e");
      throw Exception("Failed to initialize computer vision: $e");
    }
  }

  // Process image from file path
  static Future<String> analyzeImage(String imagePath) async {
    if (!_isInitialized) await initialize();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final detectionResults = await _detector!.processImage(inputImage);

      if (detectionResults.isEmpty) {
        return "No objects detected in your surroundings. Please try moving to a different area.";
      }

      final description = _createSpatialDescription(detectionResults);
      final distanceInfo = _estimateDistances(detectionResults);

      return "$description $distanceInfo";
    } catch (e) {
      return "Vision system temporarily unavailable. Error: ${e.toString()}";
    }
  }

  // Process camera frame directly
  static Future<String> analyzeCameraFrame(CameraImage cameraImage) async {
    if (!_isInitialized) await initialize();

    try {
      final inputImage = _inputImageFromCameraImage(cameraImage);
      final detectionResults = await _detector!.processImage(inputImage);

      if (detectionResults.isEmpty) {
        return "No objects detected in the current view.";
      }

      final description = _createSpatialDescription(detectionResults);
      final distanceInfo = _estimateDistances(detectionResults);

      return "$description $distanceInfo";
    } catch (e) {
      print("Camera frame processing error: $e");
      return "Failed to process camera frame. Please try again.";
    }
  }

  // Convert CameraImage to InputImage
  static InputImage _inputImageFromCameraImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    final InputImageRotation imageRotation = InputImageRotation.rotation0deg;
    final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(cameraImage.format.raw) ?? InputImageFormat.nv21;

    // Use bytesPerRow from the first plane
    final int bytesPerRow = cameraImage.planes.first.bytesPerRow;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  // Create natural language description from detections
  static String _createSpatialDescription(List<DetectedObject> detections) {
    final objectCounts = <String, int>{};
    final objectConfidences = <String, double>{};

    for (var detection in detections) {
      if (detection.labels.isEmpty) continue;
      
      final label = detection.labels.first.text;
      final confidence = detection.labels.first.confidence;

      objectCounts[label] = (objectCounts[label] ?? 0) + 1;
      if (confidence > (objectConfidences[label] ?? 0)) {
        objectConfidences[label] = confidence;
      }
    }

    if (objectCounts.isEmpty) {
      return "No identifiable objects detected.";
    }

    final sortedObjects = objectCounts.keys.toList()
      ..sort((a, b) => (objectConfidences[b] ?? 0).compareTo(objectConfidences[a] ?? 0));

    final descriptions = sortedObjects.map((label) {
      final count = objectCounts[label]!;
      final confidence = objectConfidences[label]!;

      String description = count > 1 ? "$count ${_pluralize(label)}" : "a $label";

      if (confidence > 0.8) description = "$description (very clear)";
      else if (confidence > 0.5) description = "$description (clear)";

      return description;
    }).toList();

    return "I can see ${_joinList(descriptions)}.";
  }

  // Estimate distances based on bounding box size
  static String _estimateDistances(List<DetectedObject> detections) {
    final distanceEstimates = <String>[];

    for (var detection in detections) {
      if (detection.labels.isEmpty) continue;
      
      final label = detection.labels.first.text;
      final confidence = detection.labels.first.confidence;
      final box = detection.boundingBox;

      if (confidence < 0.4) continue;

      // Calculate relative box area (0.0 to 1.0)
      final boxArea = (box.width * box.height) / (640 * 480); // Standard preview size
      final distance = _calculateDistanceFromBox(boxArea, confidence);
      final position = _getObjectPosition(box);

      distanceEstimates.add("$label is $distance and $position");
    }

    return distanceEstimates.isNotEmpty
        ? "Distance estimates: ${_joinList(distanceEstimates)}."
        : "";
  }

  static String _calculateDistanceFromBox(double boxArea, double confidence) {
    if (boxArea > 0.3 && confidence > 0.7) return "very close (1-2 meters)";
    if (boxArea > 0.15 && confidence > 0.5) return "close (2-3 meters)";
    if (boxArea > 0.05 && confidence > 0.4) return "moderately close (3-5 meters)";
    if (boxArea > 0.02) return "some distance away (5-7 meters)";
    return "far away (7+ meters)";
  }

  static String _getObjectPosition(Rect box) {
    final centerX = box.left + box.width / 2;
    final relativeX = centerX / 640; // Standard preview width

    if (relativeX < 0.3) return "to your left";
    if (relativeX > 0.7) return "to your right";
    if (relativeX > 0.4 && relativeX < 0.6) return "directly ahead";
    return "slightly to the ${relativeX < 0.5 ? 'left' : 'right'}";
  }

  static String _pluralize(String word) {
    if (word.endsWith('s') || word.endsWith('sh') || word.endsWith('ch') || word.endsWith('x') || word.endsWith('z')) {
      return '${word}es';
    } else if (word.endsWith('y') && !['a', 'e', 'i', 'o', 'u'].contains(word[word.length - 2])) {
      return '${word.substring(0, word.length - 1)}ies';
    } else {
      return '${word}s';
    }
  }

  static String _joinList(List<String> items) {
    if (items.isEmpty) return "";
    if (items.length == 1) return items.first;
    
    final last = items.removeLast();
    return "${items.join(', ')} and $last";
  }

  static void dispose() {
    _detector?.close();
    _isInitialized = false;
  }
}