import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/menuPrincipal/boton_iniciar_sesion_google.dart';
import 'package:instasafe/suqui/theme/theme.dart';
import 'package:instasafe/suqui/widgets/crazy_logo.dart';
import 'package:instasafe/suqui/widgets/email_input.dart';
import 'package:instasafe/suqui/widgets/login_button.dart';
import 'package:instasafe/suqui/widgets/password_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final correo = _emailCtrl.text.trim();
    final clave  = _passCtrl.text;
    if (correo.isEmpty || clave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes completar correo y contraseña'))
      );
      return;
    }

    setState(() => _loading = true);
    final ok = await UsuarioActual.iniciarSesion(correo, clave);
    setState(() => _loading = false);

    if (ok) {
      context.go('/menu');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo o Contraseña incorrectos'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const CrazyLogo(),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar Sesión',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: ancho * 0.07,
                                color: Colors.white,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        EmailInput(controller: _emailCtrl),
                        const SizedBox(height: 24),
                        PasswordInput(
                          controller: _passCtrl,
                          obscure: _obscure,
                          toggleObscure: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        const SizedBox(height: 32),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else
                          LoginButton(onPressed: _handleLogin),
                        const SizedBox(height: 16),
                        const BotonIniciarSesionGoogle(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '© IstaSafe',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: ancho * 0.033,
                          color: Colors.white70,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
