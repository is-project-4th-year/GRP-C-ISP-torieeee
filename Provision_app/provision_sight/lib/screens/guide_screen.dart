// screens/guide_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hive/hive.dart';
import '../services/online_processor.dart';
import '../services/offline_processor.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }
}

class GuideScreen extends StatefulWidget {
  @override
  _GuideScreenState createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final Box _settingsBox = Hive.box('appSettings');
  late CameraController _cameraController;
  bool _isOnline = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isOnline = _settingsBox.get('isOnline', defaultValue: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {});
  }

  Future<void> _startGuidance() async {
    setState(() => _isProcessing = true);
    
    if (_isOnline) {
      await _processOnline();
    } else {
      await _processOffline();
    }
    
    setState(() => _isProcessing = false);
  }

  Future<void> _processOnline() async {
    // Capture frame and send to server every 30 seconds
    while (_isProcessing) {
      final image = await _cameraController.takePicture();
      final response = await OnlineProcessor.sendFrameToServer(image.path);
      
      // Read layout.txt and convert to speech
      await TextToSpeech.speak(response);
      
      await Future.delayed(Duration(seconds: 30));
    }
  }

  Future<void> _processOffline() async {
    // Use local computer vision
    final image = await _cameraController.takePicture();
    final description = await OfflineProcessor.analyzeImage(image.path);
    
    await TextToSpeech.speak(description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Navigation Guide")),
      body: Column(
        children: [
          Text("Mode: ${_isOnline ? 'Online' : 'Offline'}"),
          Expanded(
            child: CameraPreview(_cameraController),
          ),
          _isProcessing 
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _startGuidance,
                child: Text("Start Guidance"),
              ),
        ],
      ),
    );
  }
}