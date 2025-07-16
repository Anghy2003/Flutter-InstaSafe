import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';

class EscanearScreen extends StatefulWidget {
  const EscanearScreen({Key? key}) : super(key: key);

  @override
  State<EscanearScreen> createState() => _EscanearScreenState();
}

class _EscanearScreenState extends State<EscanearScreen> {
  String? _token;
  Timer? _timer;

  final double avatarRadius = 45; // tamaño más grande
  final double borderWidth = 1.4; // borde más delgado

  @override
  void initState() {
    super.initState();
    _generarNuevoToken();
    _iniciarTimer();
  }

  void _generarNuevoToken() async {
    final nuevoToken = await UsuarioActual.generarQrToken();
    if (mounted) {
      setState(() {
        _token = nuevoToken;
      });
    }
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _generarNuevoToken();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final nombre =
        '${UsuarioActual.nombre ?? ''} ${UsuarioActual.apellido ?? ''}'.trim();

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          centerTitle: true,
          title: const Text(
            'Escanea',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
        body: _token == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Avatar + Contenedor QR
                    Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: ancho * 0.75,
                          padding: EdgeInsets.only(
                            top: avatarRadius + 12,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white,
                              width: borderWidth,
                            ),
                          ),
                          child: Column(
                            children: [
                              BarcodeWidget(
                                barcode: Barcode.qrCode(
                                  errorCorrectLevel:
                                      BarcodeQRCorrectionLevel.high,
                                ),
                                data: _token!,
                                width: ancho * 0.55,
                                height: ancho * 0.55,
                                color: Colors.white,
                                backgroundColor: Colors.transparent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                nombre.isNotEmpty ? nombre : 'Usuario',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontFamily: 'instasafe',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -(avatarRadius + borderWidth),
                          child: CircleAvatar(
                            radius: avatarRadius + borderWidth,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: avatarRadius,
                              backgroundImage: (UsuarioActual.fotoUrl != null &&
                                      UsuarioActual.fotoUrl!.isNotEmpty)
                                  ? NetworkImage(UsuarioActual.fotoUrl!)
                                  : const AssetImage(
                                      'assets/avatar_placeholder.png',
                                    ) as ImageProvider,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Credenciales/Código QR',
                      style: TextStyle(
                        color: Color.fromARGB(179, 69, 150, 200),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '@instasafe',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
