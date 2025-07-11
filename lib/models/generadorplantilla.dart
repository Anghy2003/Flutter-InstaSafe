import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:instasafe/models/plantillafacial.dart';

class GeneradorPlantillaFacial {
  Interpreter? _interpreter;

  GeneradorPlantillaFacial();

  Future<void> inicializarModelo() async {
    if (_interpreter != null) return; // Ya está cargado

    final options = InterpreterOptions()
      ..threads = 4
      ..useNnApiForAndroid = true
      ..addDelegate(XNNPackDelegate());

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/modelos/mobilefacenet_ente_web.tflite',
        options: options,
      );
    } catch (e) {
      print('❌ Error cargando el modelo: $e');
    }
  }

  Future<String?> generarDesdeImagen(File imagen) async {
    if (_interpreter == null) {
      print('❌ Modelo no inicializado');
      return null;
    }

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );

    try {
      final inputImage = InputImage.fromFile(imagen);
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        print('❌ No se detectó ningún rostro.');
        return null;
      }

      if (faces.length > 1) {
        print('❌ Hay más de un rostro en la imagen.');
        return null;
      }

      final face = faces.first;

      if ((face.smilingProbability ?? 0) > 0.4) {
        print('❌ Sonrisa detectada.');
        return null;
      }

      if ((face.headEulerAngleY ?? 0).abs() > 10 || (face.headEulerAngleZ ?? 0).abs() > 10) {
        print('❌ El rostro no está bien alineado.');
        return null;
      }

      if ((face.leftEyeOpenProbability ?? 1.0) < 0.3 ||
          (face.rightEyeOpenProbability ?? 1.0) < 0.1) {
        print('❌ Ojos posiblemente cerrados o lentes oscuros.');
        return null;
      }

      final imageData = await imagen.readAsBytes();
      final original = img.decodeImage(imageData);
      if (original == null) {
        print('❌ No se pudo decodificar la imagen.');
        return null;
      }

      final bbox = face.boundingBox;
      final centerX = bbox.left + bbox.width / 2;
      final centerY = bbox.top + bbox.height / 2;
      final imageCenterX = original.width / 2;
      final imageCenterY = original.height / 2;

      if ((centerX - imageCenterX).abs() > original.width * 0.2 ||
          (centerY - imageCenterY).abs() > original.height * 0.2) {
        print('❌ El rostro no está centrado.');
        return null;
      }

      final cropRect = _expandBoundingBox(bbox, original.width, original.height);
      final cropped = img.copyCrop(
        original,
        cropRect.left.toInt(),
        cropRect.top.toInt(),
        cropRect.width.toInt(),
        cropRect.height.toInt(),
      );

      final resized = img.copyResize(cropped, width: 112, height: 112);

      final input = List.generate(
        1,
        (_) => List.generate(
          112,
          (y) => List.generate(112, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (img.getRed(pixel) - 127.5) / 128.0,
              (img.getGreen(pixel) - 127.5) / 128.0,
              (img.getBlue(pixel) - 127.5) / 128.0,
            ];
          }),
        ),
      );

      final output = List.filled(192, 0.0).reshape([1, 192]);

      try {
        _interpreter!.run(input, output);
      } catch (e) {
        print('❌ Error al ejecutar el modelo: $e');
        return null;
      }

      final vector = List<double>.from(output[0]);
      final norm = sqrt(vector.fold(0.0, (sum, val) => sum + val * val));
      final normalized = vector.map((v) => v / norm).toList();

      final plantilla = PlantillaFacial(normalized);
      return plantilla.toBase64();
    } catch (e) {
      print('❌ Error general en procesamiento de imagen: $e');
      return null;
    }
  }

  Rect _expandBoundingBox(
    Rect bbox,
    int imgWidth,
    int imgHeight, {
    double factor = 1.4,
  }) {
    final centerX = bbox.left + bbox.width / 2;
    final centerY = bbox.top + bbox.height / 2;
    final newSize = max(bbox.width, bbox.height) * factor;

    final left = max(centerX - newSize / 2, 0).toDouble();
    final top = max(centerY - newSize / 2, 0).toDouble();
    final right = min(centerX + newSize / 2, imgWidth.toDouble());
    final bottom = min(centerY + newSize / 2, imgHeight.toDouble());

    return Rect.fromLTRB(left, top, right, bottom);
  }
}
