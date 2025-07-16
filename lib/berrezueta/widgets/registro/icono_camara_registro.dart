import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class IconoCamaraRegistro extends StatefulWidget {
  final void Function(bool, File?)? onFotoCambiada;

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
  begin: Colors.blueAccent.shade700, // tenue
  end: const Color.fromARGB(255, 183, 224, 244),   // el color que tú pediste
).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);



  }

 Future<void> _procesarImagen() async {
  final seleccion = await _picker.pickImage(
    source: ImageSource.camera, // siempre cámara
    preferredCameraDevice: CameraDevice.rear, // cámara trasera
  );
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
    widget.onFotoCambiada?.call(true, archivo);
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
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    final rostros = await detector.processImage(inputImage);
    await detector.close();

    if (rostros.isEmpty) return '❌ No se detectó ningún rostro.';
    if (rostros.length > 1) return '❌ Solo se permite un rostro en la imagen.';

    final rostro = rostros.first;

    // Validar expresión neutral (sin sonreír exageradamente)
    final sonrisa = rostro.smilingProbability ?? 0;
    if (sonrisa > 0.6) {
      return '❌ Expresión muy sonriente detectada. Usa una expresión neutral.';
    }

    // Validar que los ojos estén abiertos (sin lentes oscuros)
    final ojosAbiertos = (rostro.leftEyeOpenProbability ?? 0) > 0.5 &&
                         (rostro.rightEyeOpenProbability ?? 0) > 0.5;
    if (!ojosAbiertos) {
      return '❌ Ojos cerrados o lentes detectados. Usa rostro despejado.';
    }

    // Validar orientación del rostro (frontal, no inclinado ni girado)
    final orientacionCorrecta = (rostro.headEulerAngleY ?? 0).abs() < 15 &&
                                (rostro.headEulerAngleZ ?? 0).abs() < 15;
    if (!orientacionCorrecta) {
      return '❌ Rostro mal alineado. Mira de frente a la cámara.';
    }

    // Validar que el rostro no esté demasiado lejos (muy pequeño)
    final boundingBox = rostro.boundingBox;
    if (boundingBox.width < 100 || boundingBox.height < 100) {
      return '❌ Rostro muy pequeño. Acércate un poco más.';
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
    onTapDown: (_) => _controller.forward(),
    onTapUp: (_) {
      _controller.reverse();
      _procesarImagen();
    },
    onTapCancel: () => _controller.reverse(),
    child: AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.95).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.transparent, // Fondo transparente
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColorAnimation.value ?? const Color.fromRGBO(8, 66, 92, 1),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _verificando
                  ? const Center(
                      child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 255, 255)),
                    )
                  : _imagenSeleccionada != null
                      ? Image.file(
                          _imagenSeleccionada!,
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        )
                      : const Icon(Icons.camera_alt, size: 60, color: Color.fromARGB(255, 255, 255, 255)),
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
      _contenedorImagen(),
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


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
