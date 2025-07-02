import 'package:flutter/material.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/drawer_widget.dart';

class EscaneoQRScreen extends StatelessWidget {
  const EscaneoQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return DegradadoFondoScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerMenuLateral(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'QR',//este es el titulo de la página que aparece arribita 
            style: TextStyle(color: Colors.white, fontSize: ancho * 0.05),
          ),
        ),
        body: Center(
          child: Text(
            'Página de escaneo QR',
            style: TextStyle(
              fontSize: ancho * 0.06,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}