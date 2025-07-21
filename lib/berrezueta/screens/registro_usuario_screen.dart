import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:instasafe/berrezueta/models/usuario_actual.dart';
import 'package:instasafe/berrezueta/services/formato_telefono_usuario.dart';
import 'package:instasafe/berrezueta/widgets/degradado_fondo_screen.dart';
import 'package:instasafe/berrezueta/widgets/menu_lateral_drawer_widget.dart';
import 'package:instasafe/berrezueta/widgets/registro/enviar_datos_registro_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/estilo_input_registro.dart';
import 'package:instasafe/berrezueta/widgets/registro/funciones_registrar_usuario.dart';
import 'package:instasafe/berrezueta/widgets/registro/icono_camara_registro.dart';
import 'package:instasafe/models/generadorplantilla.dart';

// Helper para generar plantilla facial en el isolate principal
Future<Map<String, dynamic>> _generateTemplate(String imagePath) async {
  final generador = GeneradorPlantillaFacial();
  await generador.inicializarModelo();
  return await generador.generarDesdeImagen(File(imagePath));
}

class Rol {
  final int id;
  final String nombre;
  Rol({required this.id, required this.nombre});
  factory Rol.fromJson(Map<String, dynamic> json) =>
      Rol(id: json['id'], nombre: json['nombre']);
}

class UsuarioLigero {
  final int id;
  final String nombre;
  final String correo;
  UsuarioLigero({required this.id, required this.nombre, required this.correo});
  factory UsuarioLigero.fromJson(Map<String, dynamic> json) => UsuarioLigero(
    id: json['id'],
    nombre: json['nombre'],
    correo: json['correo'],
  );
}

class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _imagenSeleccionada;
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  int? _rolSeleccionado;
  bool _ocultarPassword = true;

  List<Rol> roles = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _formularioValido = false;

  @override
  void initState() {
    super.initState();
    _cedulaController.addListener(_verificarFormulario);
    _nombreController.addListener(_verificarFormulario);
    _apellidoController.addListener(_verificarFormulario);
    _telefonoController.addListener(_verificarFormulario);
    _emailController.addListener(_verificarFormulario);
    _passwordController.addListener(_verificarFormulario);
    _obtenerRoles();
    // 🚩 Selecciona la fecha por defecto (18 años menos desde hoy)
    final now = DateTime.now();
    _fechaNacimiento = DateTime(now.year - 18, now.month, now.day);
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _verificarFormulario() {
    setState(() {
      _formularioValido = validarFormularioCompleto(
        cedulaController: _cedulaController,
        nombreController: _nombreController,
        apellidoController: _apellidoController,
        telefonoController: _telefonoController,
        emailController: _emailController,
        passwordController: _passwordController,
        imagenSeleccionada: _imagenSeleccionada,
        fechaNacimiento: _fechaNacimiento,
        generoSeleccionado: _generoSeleccionado,
        rolSeleccionado: _rolSeleccionado,
      );
    });
  }

  Future<void> _obtenerRoles() async {
    try {
      final uri = Uri.parse(
        'https://spring-instasafe-441403171241.us-central1.run.app/api/roles',
      );
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout al obtener roles'),
          );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => roles = data.map((e) => Rol.fromJson(e)).toList());
      } else {
        throw Exception('Error ${response.statusCode} al obtener roles');
      }
    } on TimeoutException catch (te) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⌛ ${te.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al obtener roles: $e')));
    }
  }

  void _manejarCambioFoto(bool esValida, File? archivo) {
    _imagenSeleccionada = archivo;
    _verificarFormulario();
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _cedulaController.clear();
    _nombreController.clear();
    _apellidoController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _imagenSeleccionada = null;
      // 🚩 Vuelve a poner la fecha a 18 años menos
      final now = DateTime.now();
      _fechaNacimiento = DateTime(now.year - 18, now.month, now.day);
      _generoSeleccionado = null;
      _rolSeleccionado = null;
      _ocultarPassword = true;
      _formularioValido = false;
    });
  }

  Future<void> _registrarUsuario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || _imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Complete todos los campos y seleccione una imagen'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Permite que el spinner pinte
    await Future.delayed(const Duration(milliseconds: 100));

    final accessToken = UsuarioActual.accessToken;
    final carpetaDriveId = UsuarioActual.carpetaDriveId;
    if (accessToken == null || carpetaDriveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Falta iniciar sesión con Google')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Inicializar modelo facial
      final generador = GeneradorPlantillaFacial();
      await generador.inicializarModelo().timeout(
        const Duration(seconds: 30),
        onTimeout:
            () => throw TimeoutException('Timeout inicializando modelo facial'),
      );

      // Generar plantilla
      final resultadoGeneracion = await generador
          .generarDesdeImagen(_imagenSeleccionada!)
          .timeout(
            const Duration(seconds: 30),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Timeout generando plantilla facial',
                    ),
          );

      final plantilla = resultadoGeneracion['plantilla'] as String?;
      if (plantilla == null) {
        throw Exception(
          resultadoGeneracion['mensaje'] ?? 'Error generando plantilla',
        );
      }

      // Enviar datos
      final resultado = await enviarDatosRegistroUsuario(
        cedula: _cedulaController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correo: _emailController.text.trim(),
        genero: _generoSeleccionado ?? 'SinGenero',
        fechaNacimiento: _fechaNacimiento ?? DateTime(2000, 1, 1),
        contrasena: _passwordController.text.trim(),
        idRol: _rolSeleccionado ?? 2,
        imagen: _imagenSeleccionada!,
        carpetaDriveId: carpetaDriveId,
        plantillaFacial: plantilla,
        plantillaFacialBase64: plantilla,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Timeout registrando usuario'),
      );

      final mensaje =
          resultado.startsWith('ok')
              ? '✅ Usuario registrado con éxito'
              : resultado;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));

      if (resultado.startsWith('ok')) {
        _limpiarFormulario();
      }
    } on TimeoutException catch (te) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⌛ ${te.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error inesperado: $e')));
    } finally {
      setState(() => _isLoading = false);
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
          child: AbsorbPointer(
            absorbing: isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    IconoCamaraRegistro(onFotoCambiada: _manejarCambioFoto),
                    const SizedBox(height: 30),

                    // Cédula
                    EstiloInputRegistro(
                      etiqueta: 'Cédula',
                      textoPlaceholder: '0123456789',
                      icono: Icons.perm_identity,
                      tipoCampo: 'cedula',
                      controller: _cedulaController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),

                    // Nombre
                    EstiloInputRegistro(
                      etiqueta: 'Nombre',
                      textoPlaceholder: 'Tanya',
                      icono: Icons.person,
                      tipoCampo: 'nombre',
                      controller: _nombreController,
                    ),

                    // Apellido
                    EstiloInputRegistro(
                      etiqueta: 'Apellido',
                      textoPlaceholder: 'Perez Andrade',
                      icono: Icons.person_outline,
                      tipoCampo: 'apellido',
                      controller: _apellidoController,
                    ),

                    // Teléfono
                    EstiloInputRegistro(
                      etiqueta: 'Teléfono',
                      textoPlaceholder: '+593... o 09...',
                      icono: Icons.phone,
                      tipoCampo: 'telefono',
                      controller: _telefonoController,
                      inputFormatters: [TelefonoInputFormatter()],
                    ),

                    // Fecha de nacimiento
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: GestureDetector(
                        onTap:
                            !isLoading
                                ? () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _fechaNacimiento!, // valor por defecto
                                    firstDate: DateTime(1900),
                                    lastDate: now,
                                    builder:
                                        (c, child) => Theme(
                                          data: ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: Colors.teal,
                                              onPrimary: Colors.white,
                                              surface: Color(0xFF0A2240),
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        ),
                                  );
                                  if (picked != null) {
                                    setState(() => _fechaNacimiento = picked);
                                    _verificarFormulario();
                                  }
                                }
                                : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            labelStyle: TextStyle(color: Colors.white),
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          child: Text(
                            _fechaNacimiento != null
                                ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                                : 'Seleccionar fecha',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    // Género
                    DropdownButtonFormField<String>(
                      value: _generoSeleccionado,
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
                      ],
                      onChanged:
                          isLoading
                              ? null
                              : (v) {
                                _generoSeleccionado = v;
                                _verificarFormulario();
                              },
                    ),
                    const SizedBox(height: 10),

                    // Rol
                    DropdownButtonFormField<int>(
                      value: _rolSeleccionado,
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
                      items:
                          roles
                              .where((r) => r.nombre != 'Administrador')
                              .map(
                                (r) => DropdownMenuItem<int>(
                                  value: r.id,
                                  child: Text(r.nombre),
                                ),
                              )
                              .toList(),
                      onChanged:
                          isLoading
                              ? null
                              : (v) {
                                _rolSeleccionado = v;
                                _verificarFormulario();
                              },
                    ),
                    const SizedBox(height: 10),

                    // Correo electrónico
                    EstiloInputRegistro(
                      etiqueta: 'Correo electrónico',
                      textoPlaceholder: 'correo@ejemplo.com',
                      icono: Icons.email,
                      tipoCampo: 'email',
                      controller: _emailController,
                    ),

                    // Contraseña
                    EstiloInputRegistro(
                      etiqueta: 'Contraseña',
                      textoPlaceholder: '••••••••',
                      icono: Icons.lock,
                      tipoCampo: 'password',
                      controller: _passwordController,
                      esContrasena: true,
                      ocultarTexto: _ocultarPassword,
                      onToggleVisibilidad: () {
                        setState(() => _ocultarPassword = !_ocultarPassword);
                      },
                    ),

                    const SizedBox(height: 30),
                    _RegistrarButton(
                      onPressed:
                          _formularioValido && !isLoading
                              ? _registrarUsuario
                              : null,
                      isLoading: isLoading,
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
      ),
    );
  }
}

class _RegistrarButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _RegistrarButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? Colors.blueAccent : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
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
