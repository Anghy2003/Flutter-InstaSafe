import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AntiSpoofingService {
  late Interpreter _interpreter;
  bool _cargado = false;

  Future<void> cargarModelo() async {
    if (_cargado) return;
    _interpreter = await Interpreter.fromAsset('modelos/FaceAntiSpoofing.tflite');
    _cargado = true;
  }

  Future<bool> esImagenReal(File imagen) async {
    await cargarModelo();

    final img.Image? original = img.decodeImage(await imagen.readAsBytes());
    if (original == null) return false;

    final img.Image resized = img.copyResize(original, width: 80, height: 80);

    final input = List.generate(1, (_) => List.generate(80, (y) => List.generate(80, (x) {
      final pixel = resized.getPixelSafe(x, y);
      return [
        pixel.rNormalized, // Red canal normalizado
        
        pixel.gNormalized, // Green
        pixel.bNormalized, // Blue
      ];
    })));

    final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    _interpreter.run(input, output);

    final real = output[0][0];
    final spoof = output[0][1];

    print('🔍 AntiSpoof: Real=$real, Spoof=$spoof');
    return real > spoof;
  }
}
