import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/berrezueta/widgets/registro/enviar_datos_registro_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/icono_camara_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/estilo_input_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';
import '../widgets/degradado_fondo_screen.dart';

class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final formKey = GlobalKey<FormState>();

  final cedulaController = TextEditingController();
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  File? imagenSeleccionada;
  bool formularioValido = false;
  bool imagenSubida = false;

  void verificarEstadoFormulario() {
    final inputsLlenos = cedulaController.text.isNotEmpty &&
        nombreController.text.isNotEmpty &&
        telefonoController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        imagenSeleccionada != null;

    final camposValidos =
        ValidacionesRegistro.validarCedula(cedulaController.text) == null &&
        ValidacionesRegistro.validarNombre(nombreController.text) == null &&
        ValidacionesRegistro.validarTelefono(telefonoController.text) == null &&
        ValidacionesRegistro.validarEmail(emailController.text) == null &&
        ValidacionesRegistro.validarPassword(passwordController.text) == null;

    setState(() {
      formularioValido = inputsLlenos && camposValidos && imagenSubida;
    });
  }

  @override
  void initState() {
    super.initState();

    cedulaController.addListener(() {
      final texto = cedulaController.text;
      final limpio = texto.replaceAll(RegExp(r'[^0-9]'), '');
      if (texto != limpio) {
        cedulaController.text = limpio;
        cedulaController.selection = TextSelection.collapsed(offset: limpio.length);
      }
      verificarEstadoFormulario();
    });

    nombreController.addListener(() {
      final texto = nombreController.text;
      final limpio = texto.replaceAll(RegExp(r'[^a-zA-ZÁÉÍÓÚÑáéíóúñ\s]'), '');
      if (texto != limpio) {
        nombreController.text = limpio;
        nombreController.selection = TextSelection.collapsed(offset: limpio.length);
      }
      verificarEstadoFormulario();
    });

    telefonoController.addListener(() {
      final texto = telefonoController.text;
      final limpio = texto.replaceAll(RegExp(r'[^0-9+]'), '');
      if (texto != limpio) {
        telefonoController.text = limpio;
        telefonoController.selection = TextSelection.collapsed(offset: limpio.length);
      }
      verificarEstadoFormulario();
    });

    emailController.addListener(verificarEstadoFormulario);
    passwordController.addListener(verificarEstadoFormulario);
  }

  @override
  void dispose() {
    cedulaController.dispose();
    nombreController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void manejarCambioFoto(bool esValida, File? archivo) {
    imagenSubida = esValida;
    imagenSeleccionada = archivo;
    verificarEstadoFormulario();
  }

  void registrarUsuario() async {
  FocusScope.of(context).unfocus();

  if (formKey.currentState!.validate() && imagenSeleccionada != null) {
    final resultado = await enviarDatosRegistroUsuario(
      cedula: cedulaController.text,
      nombre: nombreController.text,
      apellido: 'SinApellido',
      correo: emailController.text,
      genero: 'SinGenero',
      idResponsable: 1,
      fechaNacimiento: DateTime(2000, 1, 1),
      contrasena: passwordController.text,
      idRol: 1,
      imagen: imagenSeleccionada!,
    );

    final mensaje = resultado.startsWith('ok')
        ? '✅ Usuario registrado con éxito'
        : resultado;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

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
            'Registrar Usuario',
            style: TextStyle(color: Colors.white, fontSize: ancho * 0.05),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  IconoCamaraRegistro(
                    onFotoCambiada: manejarCambioFoto,
                  ),
                  const SizedBox(height: 30),
                  EstiloInputRegistro(
                    etiqueta: 'Cédula',
                    textoPlaceholder: '0123456789',
                    icono: Icons.perm_identity,
                    tipoCampo: 'cedula',
                    controller: cedulaController,
                  ),
                  EstiloInputRegistro(
                    etiqueta: 'Nombre',
                    textoPlaceholder: 'Tanya Myroniuk',
                    icono: Icons.person,
                    tipoCampo: 'nombre',
                    controller: nombreController,
                  ),
                  EstiloInputRegistro(
                    etiqueta: 'Teléfono',
                    textoPlaceholder: '+593...',
                    icono: Icons.phone,
                    tipoCampo: 'telefono',
                    controller: telefonoController,
                  ),
                  EstiloInputRegistro(
                    etiqueta: 'Email',
                    textoPlaceholder: 'correo@ejemplo.com',
                    icono: Icons.email,
                    tipoCampo: 'email',
                    controller: emailController,
                  ),
                  EstiloInputRegistro(
                    etiqueta: 'Contraseña',
                    textoPlaceholder: '********',
                    icono: Icons.lock,
                    tipoCampo: 'contraseña',
                    esPassword: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 30),
                  _RegistrarButton(
                    onPressed: formularioValido ? registrarUsuario : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('©IstaSafe', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrarButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _RegistrarButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? Colors.blueAccent : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          'Registrar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}