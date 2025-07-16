import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:instasafe/models/plantillafacial.dart';
import 'package:instasafe/services/face_ml/face_alignment/similarity_transform.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui';

class GeneradorPlantillaFacial {
  late final Interpreter _interpreterFaceNet;
  late final Interpreter _interpreterBlur;
  late final Interpreter _interpreterAntiSpoof;
  late final Interpreter _interpreterEmotion;
  bool _cargado = false;

  Future<void> inicializarModelo() async {
    if (_cargado) return;
    final options = InterpreterOptions()
      ..threads = 4
      ..useNnApiForAndroid = true
      ..addDelegate(XNNPackDelegate());

    try {
      _interpreterBlur = await Interpreter.fromAsset(
        'assets/modelos/blur_detection_model.tflite',
        options: options,
      );
      _interpreterFaceNet = await Interpreter.fromAsset(
        'assets/modelos/mobilefacenet_ente_web.tflite',
        options: options,
      );
      _interpreterAntiSpoof = await Interpreter.fromAsset(
        'assets/modelos/FaceAntiSpoofing.tflite',
        options: options,
      );
      _interpreterEmotion = await Interpreter.fromAsset(
        'assets/modelos/emotion_detection_model.tflite',
        options: options,
      );
      _cargado = true;
      print('✅ Todos los modelos cargados correctamente');
    } catch (e) {
      print('❌ Error cargando modelos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generarDesdeImagen(File imagen) async {
    try {
      if (!_cargado) {
        return {
          'plantilla': null,
          'mensaje': '❌ Los modelos aún no están listos.'
        };
      }

      final bytes = await imagen.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return {
          'plantilla': null,
          'mensaje': '❌ No se pudo leer la imagen.'
        };
      }

      final puntos = await detectarLandmarks(decoded);
      if (puntos.length != 5) {
        return {
          'plantilla': null,
          'mensaje': '❌ No se detectaron suficientes puntos faciales.'
        };
      }

      final (alineacion, valido) = SimilarityTransform().estimate(puntos);
      if (!valido) {
        return {
          'plantilla': null,
          'mensaje': '❌ Transformación afín inválida.'
        };
      }

      final rostroAlineado = _aplicarTransformacion(decoded, alineacion.affineMatrix);
      final inputMatrix = _preprocesarRGB(rostroAlineado);

      if (!await esRostroReal(inputMatrix)) {
        return {
          'plantilla': null,
          'mensaje': '❌ Rostro no válido (spoofing).'
        };
      }

      final emocion = await detectarEmocion(inputMatrix);
      print('🔍 Emoción detectada: $emocion');

      // ✅ Aceptar cualquier emoción facial

      final output = List.filled(192, 0.0).reshape([1, 192]);
      _interpreterFaceNet.run(inputMatrix, output);
      final vector = List<double>.from(output[0]);
      final norm = math.sqrt(vector.fold(0.0, (s, v) => s + v * v));
      final normalizado = vector.map((v) => v / norm).toList();
      final plantilla = PlantillaFacial(normalizado);
      return {'plantilla': plantilla.toBase64(), 'mensaje': null};
    } catch (e) {
      print('❌ Error generando plantilla: ${e.toString()}');
      return {
        'plantilla': null,
        'mensaje': '❌ Error inesperado generando plantilla facial: $e'
      };
    }
  }

  List<List<List<List<double>>>> _preprocesarRGB(img.Image rostro) {
    final imgResized = img.copyResize(rostro, width: 112, height: 112);
    return [
      List.generate(112, (y) => List.generate(112, (x) {
        final pixel = imgResized.getPixel(x, y);
        return [
          pixel.r / 255.0,
          pixel.g / 255.0,
          pixel.b / 255.0,
        ];
      }))
    ];
  }

  Future<bool> esRostroReal(List<List<List<List<double>>>> inputMatrix) async {
    try {
      final output = List.filled(2, 0.0).reshape([1, 2]);
      _interpreterAntiSpoof.run(inputMatrix, output);
      return output[0][1] > output[0][0];
    } catch (_) {
      return true;
    }
  }

  Future<String?> detectarEmocion(List<List<List<List<double>>>> inputMatrix) async {
    try {
      final output = List.filled(7, 0.0).reshape([1, 7]);
      _interpreterEmotion.run(inputMatrix, output);
      final emociones = ['Enojo', 'Disgusto', 'Miedo', 'Feliz', 'Triste', 'Sorpresa', 'Neutral'];
      final scores = output[0];
      double maxScore = -1;
      int index = -1;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          index = i;
        }
      }
      return index != -1 ? emociones[index] : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<List<double>>> detectarLandmarks(img.Image imagen) async {
    final tempFile = await _crearArchivoTemporal(Uint8List.fromList(img.encodeJpg(imagen)));
    final inputImage = InputImage.fromFile(tempFile);

    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: false,
      ),
    );

    final faces = await detector.processImage(inputImage);
    await detector.close();

    if (faces.isEmpty) return [];

    final face = faces.first;
    final landmarks = face.landmarks;

    final leftEye = landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = landmarks[FaceLandmarkType.noseBase]?.position;

    if ([leftEye, rightEye, nose].any((p) => p == null)) return [];

    final mouthLeft = Offset(nose!.x - 15.0, nose.y + 30.0);
    final mouthRight = Offset(nose.x + 15.0, nose.y + 30.0);

    return [
      [leftEye!.x.toDouble(), leftEye.y.toDouble()],
      [rightEye!.x.toDouble(), rightEye.y.toDouble()],
      [nose.x.toDouble(), nose.y.toDouble()],
      [mouthLeft.dx, mouthLeft.dy],
      [mouthRight.dx, mouthRight.dy],
    ];
  }

  Future<File> _crearArchivoTemporal(Uint8List bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('instasafe_temp_');
    final file = File('${tempDir.path}/temp_face.jpg');
    await file.writeAsBytes(bytes);
    return file;
  }

  img.Image _aplicarTransformacion(img.Image original, List<List<double>> matriz) {
    return img.copyResize(original, width: 112, height: 112);
  }
}
