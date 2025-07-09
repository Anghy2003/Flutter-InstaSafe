import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:instasafe/models/plantillafacial.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class GeneradorPlantillaFacial {
  late final Interpreter _interpreter;

  GeneradorPlantillaFacial();

  Future<void> inicializarModelo() async {
    _interpreter = await Interpreter.fromAsset('facenet.tflite');
  }

  Future<String?> generarDesdeImagen(File imagen) async {
    // Paso 1: Detectar rostro
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );

    final inputImage = InputImage.fromFile(imagen);
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      print('❌ No se detectó ningún rostro.');
      return null;
    }

    final face = faces.first;

    // Paso 2: Leer y recortar imagen
    final imageData = await imagen.readAsBytes();
    final original = img.decodeImage(imageData);
    if (original == null) return null;

    final cropRect = face.boundingBox;
    final int cropX = cropRect.left.toInt().clamp(0, original.width - 1);
    final int cropY = cropRect.top.toInt().clamp(0, original.height - 1);
    final int cropW = cropRect.width.toInt().clamp(1, original.width - cropX);
    final int cropH = cropRect.height.toInt().clamp(1, original.height - cropY);

    final cropped = img.copyCrop(
  original,
  cropX,
  cropY,
  cropW,
  cropH,
);

    // Paso 3: Redimensionar a 112x112
    final resized = img.copyResize(cropped, width: 112, height: 112);

    // Paso 4: Preparar input normalizado RGB
    final input = List.generate(1, (_) => List.generate(112, (y) => List.generate(112, (x) {
      final r = img.getRed(resized.getPixel(x, y)).toDouble();
      final g = img.getGreen(resized.getPixel(x, y)).toDouble();
      final b = img.getBlue(resized.getPixel(x, y)).toDouble();
      return [
        (r - 128) / 128.0,
        (g - 128) / 128.0,
        (b - 128) / 128.0,
      ];
    })));

    // Paso 5: Output de 128
    final output = List.filled(128, 0.0).reshape([1, 128]);

    // Paso 6: Ejecutar el modelo
    _interpreter.run(input, output);
    final vector = List<double>.from(output[0]);

    // Paso 7: Convertir a base64
    final plantilla = PlantillaFacial(vector);
    return plantilla.toBase64();
  }
}
