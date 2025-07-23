import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;

/// Estructura para pasar argumentos al isolate
class ReducirImagenArgs {
  final String pathImagenOriginal;
  final String tempDirPath; // <--- Añade esto
  final SendPort sendPort;
  ReducirImagenArgs(this.pathImagenOriginal, this.tempDirPath, this.sendPort);
}

void reducirImagenIsolate(ReducirImagenArgs args) async {
  try {
    final file = File(args.pathImagenOriginal);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      args.sendPort.send({'error': 'No se pudo leer la imagen'});
      return;
    }

    final resized = img.copyResize(image, width: 400);
    final jpg = img.encodeJpg(resized, quality: 30);

    // Usa el path recibido, NO llames a getTemporaryDirectory() aquí
    final nuevoArchivo = File('${args.tempDirPath}/reducida_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await nuevoArchivo.writeAsBytes(jpg);

    args.sendPort.send({'filePath': nuevoArchivo.path});
  } catch (e) {
    args.sendPort.send({'error': e.toString()});
  }
}

