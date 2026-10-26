import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<String> getRecordingPath() async {
  return '';
}

Future<Uint8List> getAudioBytes(String path) async {
  final uri = Uri.parse(path);
  final respuesta = await http.get(uri);
  if (respuesta.statusCode != 200) {
    throw Exception('Error al descargar el audio grabado en web: ${respuesta.statusCode}');
  }
  return respuesta.bodyBytes;
}

Future<void> deleteAudioFile(String path) async {
  // En Web los Blob URLs son manejados por el navegador
}
