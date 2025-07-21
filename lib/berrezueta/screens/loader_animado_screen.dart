import 'package:flutter/material.dart';

class LoaderAnimado extends StatelessWidget {
  final ValueNotifier<String> mensajeNotifier;
  const LoaderAnimado({super.key, required this.mensajeNotifier});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 22),
              ValueListenableBuilder<String>(
                valueListenable: mensajeNotifier,
                builder: (context, mensaje, _) => Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
