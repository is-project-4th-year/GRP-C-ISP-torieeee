// Request permissions at runtime
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.location.request();
  await Permission.storage.request();
}