// services/mode_service.dart
import 'package:hive/hive.dart';

class ModeService {
  final Box _settingsBox = Hive.box('appSettings');

  bool get isOnline => _settingsBox.get('isOnline', defaultValue: true);

  Future<void> setOnline(bool online) async {
    await _settingsBox.put('isOnline', online);
  }

  Future<void> toggleMode() async {
    bool current = isOnline;
    await setOnline(!current);
  }
}