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
  // ---- Singleton ----
  static final GeneradorPlantillaFacial _instance = GeneradorPlantillaFacial._internal();
  factory GeneradorPlantillaFacial() => _instance;
  GeneradorPlantillaFacial._internal();

  late final Interpreter _interpreterFaceNet;
  late final Interpreter _interpreterBlur;
  late final Interpreter _interpreterAntiSpoof;
  late final Interpreter _interpreterEmotion;
  bool _cargado = false;

  /// Inicializa todos los modelos solo una vez.
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

  /// Genera la plantilla facial desde una imagen de usuario.
  Future<Map<String, dynamic>> generarDesdeImagen(File imagen) async {
    final tiempoTotal = DateTime.now();
    try {
      if (!_cargado) {
        print('❌ Modelos NO cargados');
        return {
          'plantilla': null,
          'mensaje': '❌ El sistema aún está cargando el reconocimiento facial. Por favor, espera unos segundos e intenta de nuevo.'
        };
      }

      // Leer y decodificar la imagen
      final bytes = await imagen.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) {
        print('❌ Imagen no decodificable');
        return {
          'plantilla': null,
          'mensaje':
              '❌ No se pudo procesar la imagen.\n\nConsejos:\n- Asegúrate de tomar la foto con buena luz.\n- No uses imágenes borrosas ni pixeladas.'
        };
      }

      // Redimensionar
      final img.Image resized = img.copyResize(decoded, width: 112, height: 112);

      // Detección de landmarks
      final puntos = await detectarLandmarks(resized);
      if (puntos.length != 5) {
        print('❌ No se detectaron suficientes puntos faciales');
        return {
          'plantilla': null,
          'mensaje':
              '❌ No se pudo detectar un rostro claro en la foto.\n\nTips para un buen escaneo:\n'
              '• Asegúrate de que tu cara esté centrada y completamente visible.\n'
              '• Mira de frente a la cámara.\n'
              '• Evita sombras y objetos que tapen el rostro.\n'
              '• No uses gafas oscuras, gorras o mascarillas.'
        };
      }

      // Transformación afín
      final (alineacion, valido) = SimilarityTransform().estimate(puntos);
      if (!valido) {
        print('❌ Transformación afín inválida');
        return {
          'plantilla': null,
          'mensaje':
              '❌ No se pudo alinear el rostro correctamente.\nIntenta tomar la foto de frente y con la cabeza recta.'
        };
      }

      final rostroAlineado = _aplicarTransformacion(resized, alineacion.affineMatrix);

      // Preprocesamiento
      final inputMatrix = _preprocesarRGB(rostroAlineado);

      if (!await esRostroReal(inputMatrix)) {
        print('❌ Rostro no válido (spoofing)');
        return {
          'plantilla': null,
          'mensaje':
              '❌ El rostro detectado no es válido. Evita usar fotos impresas, pantallas o alteraciones.\nIntenta con tu rostro real.'
        };
      }

      // Detección de emoción (opcional)
      final emocion = await detectarEmocion(inputMatrix);
      print('🔍 Emoción detectada: $emocion');

      // Embedding
      final output = List.filled(192, 0.0).reshape([1, 192]);
      _interpreterFaceNet.run(inputMatrix, output);
      final vector = List<double>.from(output[0]);
      final norm = math.sqrt(vector.fold(0.0, (s, v) => s + v * v));
      final normalizado = vector.map((v) => v / norm).toList();
      final plantilla = PlantillaFacial(normalizado);

      print('✅ Tiempo total generarDesdeImagen: ${DateTime.now().difference(tiempoTotal).inMilliseconds} ms');
      return {'plantilla': plantilla.toBase64(), 'mensaje': null};
    } catch (e, stacktrace) {
      print('❌ Error generando plantilla: $e');
      print(stacktrace); // Para saber la línea exacta si hay crash
      return {
        'plantilla': null,
        'mensaje':
            '❌ Ocurrió un error inesperado generando la plantilla facial.\nIntenta de nuevo o toma otra foto.\n\nDetalles técnicos: $e'
      };
    }
  }

  /// Preprocesa el rostro alineado para el modelo
  List<List<List<List<double>>>> _preprocesarRGB(img.Image rostro) {
    // Ya está a 112x112, no necesita más resize aquí
    return [
      List.generate(112, (y) => List.generate(112, (x) {
            final pixel = rostro.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          }))
    ];
  }

  /// Verifica si el rostro es real usando el modelo AntiSpoofing
  Future<bool> esRostroReal(List<List<List<List<double>>>> inputMatrix) async {
    try {
      final output = List.filled(2, 0.0).reshape([1, 2]);
      _interpreterAntiSpoof.run(inputMatrix, output);
      return output[0][1] > output[0][0];
    } catch (_) {
      return true;
    }
  }

  /// Detecta la emoción facial (opcional)
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

  /// Detección de landmarks faciales usando ML Kit
  Future<List<List<double>>> detectarLandmarks(img.Image imagen) async {
    // Usa la imagen ya pequeña
    final tempFile = await _crearArchivoTemporal(Uint8List.fromList(img.encodeJpg(imagen, quality: 80)));
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

  /// Crea un archivo temporal con la imagen para ML Kit
  Future<File> _crearArchivoTemporal(Uint8List bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('instasafe_temp_');
    final file = File('${tempDir.path}/temp_face.jpg');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Aplica la transformación afín al rostro (opcional: aquí puedes mejorar el alineamiento)
  img.Image _aplicarTransformacion(img.Image original, List<List<double>> matriz) {
    // Si tienes una función real de alineamiento, úsala aquí.
    // Por ahora, solo devuelve la imagen ya redimensionada
    return original;
  }
}
