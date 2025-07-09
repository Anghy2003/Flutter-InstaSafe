import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/berrezueta/widgets/registro/enviar_datos_registro_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/funciones_registrar_usuario.dart';
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
  final apellidoController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  File? imagenSeleccionada;
  bool formularioValido = false;
  bool imagenSubida = false;
  DateTime? fechaNacimiento;
  String? generoSeleccionado;
  int? rolSeleccionado;
  bool ocultarPassword = true;

  void verificarEstadoFormulario() {
    setState(() {
      formularioValido = validarFormularioCompleto(
        cedulaController: cedulaController,
        nombreController: nombreController,
        apellidoController: apellidoController,
        telefonoController: telefonoController,
        emailController: emailController,
        passwordController: passwordController,
        imagenSeleccionada: imagenSeleccionada,
        fechaNacimiento: fechaNacimiento,
        generoSeleccionado: generoSeleccionado,
        rolSeleccionado: rolSeleccionado,
      );
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

    apellidoController.addListener(() {
      final texto = apellidoController.text;
      final limpio = texto.replaceAll(RegExp(r'[^a-zA-ZÁÉÍÓÚÑáéíóúñ\s]'), '');
      if (texto != limpio) {
        apellidoController.text = limpio;
        apellidoController.selection = TextSelection.collapsed(offset: limpio.length);
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
    apellidoController.dispose();
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
    final accessToken = UsuarioActual.accessToken;
    final carpetaDriveId = UsuarioActual.carpetaDriveId;

    if (accessToken == null || carpetaDriveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Falta iniciar sesión con Google')),
      );
      return;
    }

    // 🌀 Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false, // no cerrar al tocar afuera
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        );
      },
    );

    // 📤 Enviar datos mientras se muestra el indicador
    final resultado = await enviarDatosRegistroUsuario(
      cedula: cedulaController.text.trim(),
      nombre: nombreController.text.trim(),
      apellido: apellidoController.text.trim(),
      correo: emailController.text.trim(),
      genero: generoSeleccionado ?? 'SinGenero',
      idResponsable: 1,
      fechaNacimiento: fechaNacimiento ?? DateTime(2000, 1, 1),
      contrasena: passwordController.text.trim(),
      idRol: 2,
      imagen: imagenSeleccionada!,
      accessToken: accessToken,
      carpetaDriveId: carpetaDriveId,
    );

    Navigator.of(context).pop(); // ❌ Cierra el indicador de carga

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
                  IconoCamaraRegistro(onFotoCambiada: manejarCambioFoto),
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
                    etiqueta: 'Apellido',
                    textoPlaceholder: 'Perez Andrade',
                    icono: Icons.person_outline,
                    tipoCampo: 'apellido',
                    controller: apellidoController,
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.white),
                      hintText: '********',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            ocultarPassword = !ocultarPassword;
                          });
                        },
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) => ValidacionesRegistro.validarPassword(value ?? ''),
                    onChanged: (_) => verificarEstadoFormulario(),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      fechaNacimiento == null
                          ? 'Selecciona tu fecha de nacimiento'
                          : 'Fecha: ${fechaNacimiento!.toLocal().toString().split(" ")[0]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: () async {
                      final seleccionada = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (seleccionada != null) {
                        setState(() {
                          fechaNacimiento = seleccionada;
                          verificarEstadoFormulario();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: Colors.black,
                    items: ['Masculino', 'Femenino'].map((genero) {
                      return DropdownMenuItem(
                        value: genero,
                        child: Text(genero),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        generoSeleccionado = valor;
                        verificarEstadoFormulario();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: Colors.black,
                    items: [ 2, 3, 4].map((rol) {
                      return DropdownMenuItem(
                        value: rol,
                        child: Text('Rol $rol'),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        rolSeleccionado = valor;
                        verificarEstadoFormulario();
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  _RegistrarButton(onPressed: formularioValido ? registrarUsuario : null),
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
