import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class IconoCamaraRegistro extends StatefulWidget {
  final void Function(bool, File?)? onFotoCambiada;
  const IconoCamaraRegistro({Key? key, this.onFotoCambiada}) : super(key: key);

  @override
  _IconoCamaraRegistroState createState() => _IconoCamaraRegistroState();
}

class _IconoCamaraRegistroState extends State<IconoCamaraRegistro>
    with SingleTickerProviderStateMixin {
  File? _imagenSeleccionada;
  bool _verificando = false;

  late final AnimationController _controller;
  late final Animation<Color?> _borderColorAnimation;
  final ImagePicker _picker = ImagePicker();

  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();

    // 1) Animación de borde
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: Colors.blueAccent.shade700,
      end: const Color.fromARGB(255, 183, 224, 244),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 2) Inicializar FaceDetector UNA VEZ
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableContours: false,               // no necesitamos contours
        performanceMode: FaceDetectorMode.fast, // más rápido que accurate
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close(); // liberar recursos del detector
    super.dispose();
  }

  Future<void> _procesarImagen() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _verificando = true;
      _imagenSeleccionada = null;
    });
    // Retardo mínimo para que el spinner se pinte
    await Future.delayed(const Duration(milliseconds: 100));

    final resultado = await _validarImagen(file);

    if (resultado == 'ok') {
      setState(() {
        _imagenSeleccionada = file;
        _verificando = false;
      });
      widget.onFotoCambiada?.call(true, file);
    } else {
      setState(() {
        _verificando = false;
        _imagenSeleccionada = null;
      });
      widget.onFotoCambiada?.call(false, null);
      _mostrarDialogoError(resultado);
    }
  }

  Future<String> _validarImagen(File imagen) async {
    final inputImage = InputImage.fromFile(imagen);

    // Usamos el detector ya inicializado
    final rostros = await _faceDetector.processImage(inputImage);

    if (rostros.isEmpty) return '❌ No se detectó ningún rostro.';
    if (rostros.length > 1) return '❌ Solo se permite un rostro en la imagen.';

    final r = rostros.first;
    final smile = r.smilingProbability ?? 0;
    if (smile > 0.6) {
      return '❌ Expresión muy sonriente detectada. Usa una expresión neutral.';
    }

    final ojosOk = (r.leftEyeOpenProbability ?? 0) > 0.5 &&
                   (r.rightEyeOpenProbability ?? 0) > 0.5;
    if (!ojosOk) {
      return '❌ Ojos cerrados o lentes detectados. Usa rostro despejado.';
    }

    final angY = (r.headEulerAngleY ?? 0).abs();
    final angZ = (r.headEulerAngleZ ?? 0).abs();
    if (angY > 15 || angZ > 15) {
      return '❌ Rostro mal alineado. Mira de frente a la cámara.';
    }

    final box = r.boundingBox;
    if (box.width < 100 || box.height < 100) {
      return '❌ Rostro muy pequeño. Acércate un poco más.';
    }

    return 'ok';
  }

  void _mostrarDialogoError(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Error de imagen', style: TextStyle(color: Colors.white)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraIcon() {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _procesarImagen();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _borderColorAnimation,
        builder: (context, _) {
          return ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.95).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColorAnimation.value!,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _verificando
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _imagenSeleccionada != null
                        ? Image.file(
                            _imagenSeleccionada!,
                            fit: BoxFit.cover,
                            width: 130,
                            height: 130,
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 60,
                            color: Colors.white,
                          ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCameraIcon(),
        const SizedBox(height: 8),
        const Text(
          'Clic para tomar foto',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
