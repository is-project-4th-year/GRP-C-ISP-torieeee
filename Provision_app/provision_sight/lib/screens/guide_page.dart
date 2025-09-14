// screens/guide_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provision_sight/utils/object_detector.dart';

class GuidePage extends StatefulWidget {
  @override
  _GuidePageState createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  CameraController? _controller;
  String _detectionResult = "No objects detected yet";
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
    setState(() {});
    
    // Start object detection
    _startObjectDetection();
  }

  void _startObjectDetection() {
    setState(() {
      _isDetecting = true;
    });
    
    // Simulate object detection
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _detectionResult = "Detected: Chair, Table, Door";
          _isDetecting = false;
        });
        
        // Continue detection
        Future.delayed(Duration(seconds: 10), _startObjectDetection);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Guide'),
          backgroundColor: Color(0xFF1B5E20),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Guide'),
        backgroundColor: Color(0xFF1B5E20),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: CameraPreview(_controller!),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isDetecting)
                    CircularProgressIndicator()
                  else
                    Icon(Icons.check_circle, color: Colors.green, size: 40),
                  SizedBox(height: 10),
                  Text(
                    _detectionResult,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}