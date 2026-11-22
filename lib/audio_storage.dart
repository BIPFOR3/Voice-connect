import 'dart:typed_data';

export 'audio_storage_stub.dart'
    if (dart.library.io) 'audio_storage_io.dart'
    if (dart.library.js_interop) 'audio_storage_web.dart'
    if (dart.library.html) 'audio_storage_web.dart';

class AudioBytesCache {
  static final Map<String, Uint8List> _cache = {};

  static void set(String key, Uint8List bytes) {
    if (key.isNotEmpty) {
      _cache[key] = bytes;
    }
  }

  static Uint8List? get(String key) {
    if (key.isEmpty) return null;
    return _cache[key];
  }
}
