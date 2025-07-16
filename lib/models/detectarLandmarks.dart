import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Detecta 5 puntos faciales simulados usando ML Kit (3 reales y 2 simulados para boca)
Future<List<List<double>>> detectarLandmarks(img.Image imagen) async {
  final bytes = Uint8List.fromList(img.encodeJpg(imagen));

  final inputImage = InputImage.fromFilePath(
    (await _crearArchivoTemporal(bytes)).path,
  );

  final options = FaceDetectorOptions(
    enableLandmarks: true,
    enableContours: false,
  );

  final detector = FaceDetector(options: options);
  final faces = await detector.processImage(inputImage);
  await detector.close();

  if (faces.isEmpty || faces.first.landmarks.isEmpty) return [];

  final face = faces.first;
  final landmarks = face.landmarks;

  final leftEye = landmarks[FaceLandmarkType.leftEye]?.position;
  final rightEye = landmarks[FaceLandmarkType.rightEye]?.position;
  final nose = landmarks[FaceLandmarkType.noseBase]?.position;

  if ([leftEye, rightEye, nose].any((p) => p == null)) return [];

  // Simular puntos de la boca relativos a la nariz
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

/// Guarda temporalmente una imagen en disco para usarla con ML Kit
Future<File> _crearArchivoTemporal(Uint8List bytes) async {
  final tempDir = Directory.systemTemp;
  final file = await File('${tempDir.path}/temp_face.jpg').create();
  await file.writeAsBytes(bytes);
  return file;
}
