import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/berrezueta/widgets/registro/enviar_datos_registro_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/funciones_registrar_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/icono_camara_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/estilo_input_registro.dart';
import 'package:instasafe/illescas/screens/comparadorfacial_ligero.dart';
import 'package:instasafe/models/generadorplantilla.dart';
import 'package:instasafe/illescas/screens/usuarioLigero.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/models/plantillafacial.dart';
import 'dart:convert';
import '../widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/registro/validaciones_registro.dart';

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
    cedulaController.addListener(verificarEstadoFormulario);
    nombreController.addListener(verificarEstadoFormulario);
    apellidoController.addListener(verificarEstadoFormulario);
    telefonoController.addListener(verificarEstadoFormulario);
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

  Future<List<UsuarioLigero>> obtenerUsuariosLigero() async {
    final response = await http.get(
      Uri.parse(
        'https://spring-instasafe-441403171241.us-central1.run.app/api/usuarios/plantillas',
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => UsuarioLigero.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener usuarios');
    }
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
      );

      final generador = GeneradorPlantillaFacial();
      await generador.inicializarModelo();
      final plantillaCodificada = await generador.generarDesdeImagen(
        imagenSeleccionada!,
      );

      if (plantillaCodificada == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No se pudo generar plantilla facial'),
          ),
        );
        return;
      }

      final usuarios = await obtenerUsuariosLigero();
      final resultadoComparacion = ComparadorFacialLigero.comparar(
        PlantillaFacial.fromBase64(plantillaCodificada),
        usuarios,
      );

      if (resultadoComparacion != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Ya existe un usuario con rostro similar (cédula: ${resultadoComparacion['usuario'].cedula})',
            ),
          ),
        );
        return;
      }

      final resultado = await enviarDatosRegistroUsuario(
        cedula: cedulaController.text.trim(),
        nombre: nombreController.text.trim(),
        apellido: apellidoController.text.trim(),
        correo: emailController.text.trim(),
        genero: generoSeleccionado ?? 'SinGenero',
        idResponsable: 1,
        fechaNacimiento: fechaNacimiento ?? DateTime(2000, 1, 1),
        contrasena: passwordController.text.trim(),
        idRol: rolSeleccionado ?? 2,
        imagen: imagenSeleccionada!,
        accessToken: accessToken,
        carpetaDriveId: carpetaDriveId,
        plantillaFacial: plantillaCodificada,
        plantillaFacialBase64: plantillaCodificada,
      );

      Navigator.of(context).pop();
      final mensaje =
          resultado.startsWith('ok')
              ? '✅ Usuario registrado con éxito'
              : resultado;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
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
                    textoPlaceholder: 'Tanya',
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

                  // 📅 Fecha de nacimiento (actualizado y estilizado)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: now,
                          helpText: 'Selecciona tu fecha de nacimiento',
                          cancelText: 'Cancelar',
                          confirmText: 'Aceptar',
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.teal,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF0A2240),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => fechaNacimiento = picked);
                          verificarEstadoFormulario();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        child: Text(
                          fechaNacimiento != null
                              ? '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}'
                              : 'Seleccionar fecha',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // ⬇ Género y Rol (igual que antes)
                  DropdownButtonFormField<String>(
                    value: generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.wc, color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: const Color(0xFF0A2240),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'Masculino',
                        child: Text('Masculino'),
                      ),
                      DropdownMenuItem(
                        value: 'Femenino',
                        child: Text('Femenino'),
                      ),
                      DropdownMenuItem(value: 'Otro', child: Text('Gei')),
                    ],
                    onChanged: (valor) {
                      setState(() => generoSeleccionado = valor);
                      verificarEstadoFormulario();
                    },
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<int>(
                    value: rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.badge, color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: const Color(0xFF0A2240),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Administrador')),
                      DropdownMenuItem(value: 2, child: Text('Estudiante')),
                      DropdownMenuItem(value: 3, child: Text('Profesor')),
                    ],
                    onChanged: (valor) {
                      setState(() => rolSeleccionado = valor);
                      verificarEstadoFormulario();
                    },
                  ),

                  const SizedBox(height: 10),

                  // ✅ Correo y Contraseña al final como debe ser
                  EstiloInputRegistro(
                    etiqueta: 'Correo electrónico',
                    textoPlaceholder: 'correo@ejemplo.com',
                    icono: Icons.email,
                    tipoCampo: 'email',
                    controller: emailController,
                  ),

                  EstiloInputRegistro(
                    etiqueta: 'Contraseña',
                    textoPlaceholder: '••••••••',
                    icono: Icons.lock,
                    tipoCampo: 'password',
                    controller: passwordController,
                    esContrasena: true,
                    ocultarTexto: ocultarPassword,
                    onToggleVisibilidad: () {
                      setState(() => ocultarPassword = !ocultarPassword);
                    },
                  ),

                  const SizedBox(height: 30),
                  _RegistrarButton(
                    onPressed: formularioValido ? registrarUsuario : null,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '©IstaSafe',
                    style: TextStyle(color: Colors.white70),
                  ),
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
