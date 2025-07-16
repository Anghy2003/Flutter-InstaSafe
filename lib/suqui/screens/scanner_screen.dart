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
  late Future<String?> _tokenFut;

  @override
  void initState() {
    super.initState();
    _tokenFut = UsuarioActual.generarQrToken();
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
            builder: (ctx) =>
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          ),
          centerTitle: true,
          title: const Text('Escanea'),
        ),
        body: FutureBuilder<String?>(
          future: _tokenFut,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final token = snap.data;
            if (token == null) {
              return Center(
                child: Text(
                  'No se pudo generar el QR',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            // <-- Aquí envolvemos en Center para que todo el bloque quede centrado
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // avatar
                  CircleAvatar(
                    radius: ancho * 0.15,
                    backgroundImage: (UsuarioActual.fotoUrl != null && UsuarioActual.fotoUrl!.isNotEmpty)
                        ? NetworkImage(UsuarioActual.fotoUrl!) as ImageProvider
                        : const AssetImage('assets/avatar_placeholder.png'),
                  ),
                  const SizedBox(height: 24),

                  // contenedor del QR
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // <-- BarcodeWidget con color personalizado
                        BarcodeWidget(
                          barcode: Barcode.qrCode(
                            errorCorrectLevel: BarcodeQRCorrectionLevel.high,
                          ),
                          data: token,
                          width: ancho * 0.6,
                          height: ancho * 0.6,
                          color: Colors.lightBlueAccent,      // color de los módulos
                          backgroundColor: Colors.transparent, // fondo transparente
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nombre.isNotEmpty ? nombre : 'Usuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
