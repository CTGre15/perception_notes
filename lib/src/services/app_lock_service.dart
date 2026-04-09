import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockService {
  static const _pinKey = 'app_lock_pin';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedPin;

  bool get isLockEnabled => _cachedPin != null && _cachedPin!.isNotEmpty;

  Future<void> initialize() async {
    _cachedPin = await _storage.read(key: _pinKey);
  }

  Future<void> setPin(String pin) async {
    _cachedPin = pin;
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    return _cachedPin == pin;
  }

  Future<void> clearPin() async {
    _cachedPin = null;
    await _storage.delete(key: _pinKey);
  }
}
