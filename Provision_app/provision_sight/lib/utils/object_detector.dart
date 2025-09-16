// utils/object_detector.dart
import 'package:google_ml_kit/google_ml_kit.dart' as google_ml_kit;
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ObjectDetector {
  static final google_ml_kit.ObjectDetector mlKitDetector = google_ml_kit.GoogleMlKit.vision.objectDetector(
    options: google_ml_kit.ObjectDetectorOptions(
      mode: google_ml_kit.DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );
  
  static Future<String> detectObjects(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      
      final google_ml_kit.InputImageRotation imageRotation =
          google_ml_kit.InputImageRotation.rotation0deg;
      
      final google_ml_kit.InputImageFormat inputImageFormat =
          google_ml_kit.InputImageFormat.nv21;
      
      // Plane metadata is not required for InputImageMetadata in the latest google_ml_kit
      final metadata = google_ml_kit.InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = google_ml_kit.InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
      
      final List<google_ml_kit.DetectedObject> objects =
          await mlKitDetector.processImage(inputImage);
      
      if (objects.isEmpty) {
        return "No objects detected";
      }
      
      String result = "Detected: ";
      for (final google_ml_kit.DetectedObject object in objects) {
        if (object.labels.isNotEmpty) {
          final label = object.labels.first;
          result += "${label.text} (${(label.confidence * 100).toStringAsFixed(1)}%), ";
        }
      }
      
      return result.substring(0, result.length - 2);
    } catch (e) {
      return "Detection error: $e";
    }
  }
  
  static Future<String> detectObjectsOnline(CameraImage image) async {
    // This would send the image to a server for more advanced processing
    // For now, we'll use the local detector
    return await detectObjects(image);
  }
  
  static Future<void> close() async {
    await mlKitDetector.close();
  }
}