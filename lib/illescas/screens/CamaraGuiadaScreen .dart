import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CamaraGuiadaScreen extends StatefulWidget {
  final void Function(File) onFotoCapturada;

  const CamaraGuiadaScreen({super.key, required this.onFotoCapturada});

  @override
  State<CamaraGuiadaScreen> createState() => _CamaraGuiadaScreenState();
}

class _CamaraGuiadaScreenState extends State<CamaraGuiadaScreen> {
  late CameraController _controller;
  late Future<void> _initCamera;

  @override
  void initState() {
    super.initState();
    _initCamera = _configurarCamara();
  }

  Future<void> _configurarCamara() async {
    final cameras = await availableCameras();
    final trasera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.back);
    _controller = CameraController(trasera, ResolutionPreset.medium);
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capturar() async {
    final xFile = await _controller.takePicture();
    final archivo = File(xFile.path);
    widget.onFotoCapturada(archivo);
    Navigator.of(context).pop(); // cerrar cámara
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initCamera,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Center(child: CameraPreview(_controller)),
              _marcosGuia(context),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capturar"),
                    onPressed: _capturar,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  /// Marco guía solo con líneas en esquinas
  Widget _marcosGuia(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 320,
        child: CustomPaint(
          painter: _EsquinasGuiaPainter(),
        ),
      ),
    );
  }
}

class _EsquinasGuiaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF07294D) // Azul oscuro personalizado
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double lineLength = 20;

    // Esquinas: superior izquierda
    canvas.drawLine(Offset(0, 0), Offset(lineLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, lineLength), paint);

    // superior derecha
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - lineLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, lineLength), paint);

    // inferior izquierda
    canvas.drawLine(Offset(0, size.height), Offset(lineLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - lineLength), paint);

    // inferior derecha
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - lineLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - lineLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
