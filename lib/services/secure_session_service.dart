import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro del JWT / sesión (rúbrica Criterio 4).
class SecureSessionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'bp_access_token';
  static const _keyRefreshToken = 'bp_refresh_token';
  static const _keyDocumento = 'bp_documento';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String documento,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyDocumento, value: documento);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyDocumento);
  }

  static Future<String?> get savedDocumento => _storage.read(key: _keyDocumento);
}
