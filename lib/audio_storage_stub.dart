import 'dart:typed_data';

Future<String> getRecordingPath() =>
    throw UnsupportedError('Plataforma no soportada');

Future<Uint8List> getAudioBytes(String path) =>
    throw UnsupportedError('Plataforma no soportada');

Future<void> deleteAudioFile(String path) =>
    throw UnsupportedError('Plataforma no soportada');
