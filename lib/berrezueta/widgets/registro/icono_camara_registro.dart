import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class IconoCamaraRegistro extends StatefulWidget {
  final void Function(bool)? onFotoCambiada;

  const IconoCamaraRegistro({super.key, this.onFotoCambiada});

  @override
  State<IconoCamaraRegistro> createState() => _IconoCamaraRegistroState();
}

class _IconoCamaraRegistroState extends State<IconoCamaraRegistro>
    with SingleTickerProviderStateMixin {
  File? _imagenSeleccionada;
  bool _verificando = false;

  late AnimationController _controller;
  late Animation<Color?> _borderColorAnimation;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: Colors.white24,
      end: Colors.white70,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Future<void> _procesarImagen(ImageSource source) async {
    final seleccion = await _picker.pickImage(source: source);
    if (seleccion == null) return;

    final archivo = File(seleccion.path);
    setState(() {
      _verificando = true;
      _imagenSeleccionada = null;
    });

    final resultado = await _validarImagen(archivo);

    if (resultado == 'ok') {
      setState(() {
        _imagenSeleccionada = archivo;
        _verificando = false;
      });
      widget.onFotoCambiada?.call(true);
    } else {
      setState(() {
        _verificando = false;
        _imagenSeleccionada = null;
      });
      widget.onFotoCambiada?.call(false);
      _mostrarDialogoError(resultado);
    }
  }

  Future<String> _validarImagen(File imagen) async {
    final inputImage = InputImage.fromFile(imagen);
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableContours: true,
      ),
    );
    final rostros = await detector.processImage(inputImage);
    await detector.close();

    if (rostros.isEmpty) return 'No se detectó ningún rostro';
    if (rostros.length > 1) return 'La imagen contiene más de un rostro';

    final rostro = rostros.first;
    final ojosAbiertos = (rostro.leftEyeOpenProbability ?? 0) > 0.6 &&
                         (rostro.rightEyeOpenProbability ?? 0) > 0.6;
    final orientacionCorrecta = (rostro.headEulerAngleY ?? 0).abs() < 25 &&
                                (rostro.headEulerAngleZ ?? 0).abs() < 20;

    final boundingBox = rostro.boundingBox;
    final rostroArea = boundingBox.width * boundingBox.height;

    const contenedorWidth = 120.0;
    const contenedorHeight = 120.0;
    final contenedorArea = contenedorWidth * contenedorHeight;

    final porcentajeRostro = rostroArea / contenedorArea;

    if (porcentajeRostro < 0.50) {
      return 'El rostro ocupa menos del 50% del área. Acércate más a la cámara.';
    }

    if (!ojosAbiertos || !orientacionCorrecta) {
      return 'El rostro está tapado o mal posicionado';
    }

    return 'ok';
  }

  void _mostrarDialogoError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Error de imagen', style: TextStyle(color: Colors.white)),
        content: Text(
          mensaje,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _contenedorImagen() {
    return GestureDetector(
      onTap: () => _procesarImagen(ImageSource.camera),
      child: AnimatedBuilder(
        animation: _borderColorAnimation,
        builder: (context, child) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColorAnimation.value ?? Colors.white,
                width: 2,
              ),
            ),
            child: _verificando
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  )
                : _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _imagenSeleccionada!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 60, color: Colors.white70),
          );
        },
      ),
    );
  }

  Widget _botonGaleria() {
    return TextButton.icon(
      onPressed: () => _procesarImagen(ImageSource.gallery),
      icon: const Icon(Icons.photo_library, color: Colors.white70),
      label: const Text(
        'Subir desde galería',
        style: TextStyle(color: Colors.white70),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _contenedorImagen(),
        const SizedBox(height: 8),
        _botonGaleria(),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}