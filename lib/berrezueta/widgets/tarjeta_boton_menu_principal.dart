import 'package:flutter/material.dart';

class TarjetaBotonMenuPrincipal extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onPressed;

  const TarjetaBotonMenuPrincipal({
    Key? key,
    required this.icono,
    required this.titulo,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;

    final anchoBoton = ancho * 0.44;
    final altoBoton = alto * 0.18;
    final tamanoIcono = ancho * 0.16;
    final tamanoTexto = ancho * 0.036;

    return SizedBox(
      width: anchoBoton,
      height: altoBoton,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(19, 27, 45, 1),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color.fromRGBO(8, 66, 92, 1), width: 1.5),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: tamanoIcono, color: Colors.white),
            SizedBox(height: altoBoton * 0.1),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: tamanoTexto,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}