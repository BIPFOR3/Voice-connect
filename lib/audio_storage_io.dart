import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> getRecordingPath() async {
  final carpeta = await getTemporaryDirectory();
  return '${carpeta.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
}

Future<Uint8List> getAudioBytes(String path) async {
  final archivo = File(path);
  if (!await archivo.exists()) {
    throw Exception('No se encontró el archivo de audio local.');
  }
  return await archivo.readAsBytes();
}

Future<void> deleteAudioFile(String path) async {
  try {
    final archivo = File(path);
    if (await archivo.exists()) {
      await archivo.delete();
    }
  } catch (_) {}
}
