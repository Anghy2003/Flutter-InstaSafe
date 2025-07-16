import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:instasafe/illescas/screens/verificar.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  bool _escaneado = false;
  late AnimationController _controller;
  late Animation<double> _linePosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _linePosition = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _procesarQR(String rawValue) async {
    _escaneado = true;
    print('📥 QR detectado: $rawValue');

    try {
      final Map<String, dynamic> datosQR = jsonDecode(rawValue);
      final cedula = datosQR['cedula'];
      print('🔍 Consultando datos de usuario con cédula: $cedula');

      final response = await http.get(
        Uri.parse('https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/cedula/$cedula'),
      );

      print('📡 Respuesta usuario: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Usuario no encontrado');
      }

      final usuario = jsonDecode(response.body);
      print('✅ Usuario obtenido: ${usuario['nombre']}');

      final datosUsuario = {
        'id': usuario['id'],
        'cedula': usuario['cedula'],
        'nombre': '${usuario['nombre']} ${usuario['apellido']}',
        'apellido': usuario['apellido'],
        'email': usuario['correo'] ?? '',
        'rol': usuario['id_rol']?['nombre'] ?? 'Sin rol',
        'foto': usuario['foto'],
        'acceso': usuario['estado'] ?? true,
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificacionResultadoScreen(
            datosUsuario: datosUsuario,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error procesando QR: $e');
      _escaneado = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error procesando QR: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              facing: CameraFacing.back,
              detectionSpeed: DetectionSpeed.normal,
              formats: [BarcodeFormat.qrCode],
            ),
            onDetect: (capture) {
              if (_escaneado) return;
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                _procesarQR(barcode.rawValue!);
              }
            },
          ),
          _OverlayConEsquinas(animacion: _linePosition),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Coloque el código adentro del recuadro',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Icon(Icons.image, color: Color(0xFF07294D), size: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayConEsquinas extends StatelessWidget {
  final Animation<double> animacion;
  const _OverlayConEsquinas({required this.animacion});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.biggest;
        const width = 250.0;
        const height = 250.0;
        final left = (size.width - width) / 2;
        final top = (size.height - height) / 2;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(color: Colors.black.withOpacity(0.75)),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: width,
                      height: height,
                      color: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: CustomPaint(
                size: const Size(width, height),
                painter: _PunterosEsquinasPainter(),
              ),
            ),
            AnimatedBuilder(
              animation: animacion,
              builder: (_, __) {
                return Positioned(
                  left: left,
                  top: top + animacion.value * height,
                  child: Container(
                    width: width,
                    height: 2,
                    color: const Color(0xFF07294D),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PunterosEsquinasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double length = 25;

    // Esquinas
    canvas.drawLine(Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, length), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
