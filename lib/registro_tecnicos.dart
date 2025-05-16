import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geo_firestore_flutter/geo_firestore_flutter.dart';
import 'politica_privacidad.dart';
import 'terminos_condiciones.dart';

class PantallaRegistroTecnico extends StatefulWidget {
  const PantallaRegistroTecnico({super.key});

  @override
  State<PantallaRegistroTecnico> createState() => _PantallaRegistroTecnicoState();
}

class _PantallaRegistroTecnicoState extends State<PantallaRegistroTecnico> {
  // Controllers
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repetirPasswordController = TextEditingController();
  final TextEditingController especialidadController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();

  // Estado para archivos y carga
  File? _fotoPerfil;
  List<File> _documentos = [];
  bool _isLoading = false; // Para el registro general
  String? _errorMessage; // Errores de validación

  // Estado para el checkbox de términos
  bool _aceptaTerminos = false;

  // Variables de Estado para Ubicación
  Position? _ubicacionTecnico;
  bool _buscandoUbicacionTecnico = false;
  String? _errorUbicacionTecnico;

  //  Regex para teléfono chileno con +56 9 XXXX XXXX
  final _telefonoRegexCL = RegExp(r'^\+?56\s?9\s?\d{8}$');

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');


  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repetirPasswordController.dispose();
    especialidadController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFotoPerfil() async {
    if (_isLoading || _buscandoUbicacionTecnico) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      setState(() {
        _fotoPerfil = File(result.files.single.path!);
      });
    }
  }

  Future<void> _seleccionarDocumentos() async {
    if (_isLoading || _buscandoUbicacionTecnico) return;
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _documentos = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<String> _subirArchivo(File archivo, String ruta) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(ruta);
      await ref.putFile(archivo);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Error al subir archivo a Storage: (${e.code}) ${e.message}');
      }
      throw Exception('Error al subir archivo: ${e.code}');
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado al subir archivo: $e');
      }
      throw Exception('Error inesperado al subir archivo.');
    }
  }

  Future<void> _obtenerUbicacionActualTecnico() async {
    if (_isLoading || _buscandoUbicacionTecnico) return;
    if (!mounted) return;

    setState(() {
      _buscandoUbicacionTecnico = true;
      _errorUbicacionTecnico = null;
    });

    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() { _errorUbicacionTecnico = 'Servicios de ubicación desactivados.'; _buscandoUbicacionTecnico = false; });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.orange[700]));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() { _errorUbicacionTecnico = 'Permiso de ubicación denegado.'; _buscandoUbicacionTecnico = false; });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.redAccent));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() { _errorUbicacionTecnico = 'Permiso denegado permanentemente.'; _buscandoUbicacionTecnico = false; });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.redAccent));
      return;
    }

    if (kDebugMode) {
      print("Obteniendo ubicación actual del técnico...");
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _ubicacionTecnico = position;
        _buscandoUbicacionTecnico = false;
        _errorUbicacionTecnico = null;
      });
      if (kDebugMode) {
        print("Ubicación de Técnico obtenida: $_ubicacionTecnico");
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación obtenida con éxito.'), duration: Duration(seconds: 2), backgroundColor: Colors.green));
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener ubicación del técnico: $e");
      }
      if (!mounted) return;
      setState(() {
        _errorUbicacionTecnico = 'No se pudo obtener la ubicación: ${e.toString()}';
        _buscandoUbicacionTecnico = false;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _registrarTecnico() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    // --- NUEVO: Validación de aceptación de términos ---
    if (!_aceptaTerminos) {
      setState(() {
        _errorMessage = 'Debes aceptar los Términos y Condiciones y la Política de Privacidad para continuar.';
      });
      return;
    }
    // --- FIN NUEVO ---

    final nombre = nombreController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final repetirPassword = repetirPasswordController.text.trim();
    final especialidad = especialidadController.text.trim();
    final telefono = telefonoController.text.trim();
    final direccion = direccionController.text.trim();

    setState(() { _errorMessage = null; });

    if ([nombre, email, password, repetirPassword, especialidad, telefono, direccion].any((e) => e.isEmpty)) {
      setState(() { _errorMessage = 'Por favor completa todos los campos obligatorios'; });
      return;
    }
    if (!_emailRegex.hasMatch(email)) { // Validación de email
      setState(() {
        _errorMessage = 'El correo ingresado no es válido';
      });
      return;
    }
    if (!_telefonoRegexCL.hasMatch(telefono)) { // Validación de teléfono
      setState(() {
        _errorMessage = 'El formato del teléfono debe ser +56 9 XXXX XXXX';
      });
      return;
    }
    if (password.length < 6) {
      setState(() { _errorMessage = 'La contraseña debe tener al menos 6 caracteres'; });
      return;
    }
    if (password != repetirPassword) {
      setState(() { _errorMessage = 'Las contraseñas no coinciden'; });
      return;
    }
    if (_ubicacionTecnico == null) {
      setState(() { _errorMessage = 'Por favor, obtén tu ubicación actual antes de registrar.'; });
      return;
    }

    setState(() { _isLoading = true; });

    String? fotoUrl;
    List<String> urlsDocs = [];
    User? user;

    //  Normalizar número de teléfono antes de guardar
    String telefonoNormalizado = telefono.replaceAll(RegExp(r'\s+'), '');
    if (!telefonoNormalizado.startsWith('+')) {
      if (telefonoNormalizado.startsWith('569')) {
        telefonoNormalizado = '+$telefonoNormalizado';
      } else if (telefonoNormalizado.startsWith('9')) {
        telefonoNormalizado = '+56$telefonoNormalizado';
      }
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = cred.user;
      if (user == null) {
        throw Exception("No se pudo crear el usuario en Firebase Auth.");
      }
      await user.updateDisplayName(nombre); // Actualizar nombre en Auth
      final uid = user.uid;

      if (_fotoPerfil != null) {
        fotoUrl = await _subirArchivo(_fotoPerfil!, 'tecnicos/$uid/fotoPerfil.jpg');
      }
      if (_documentos.isNotEmpty) {
        for (int i = 0; i < _documentos.length; i++) {
          final docFile = _documentos[i];
          final nombreArchivo = docFile.path.split('/').last;
          final url = await _subirArchivo(docFile, 'tecnicos/$uid/docs/${i}_$nombreArchivo');
          urlsDocs.add(url);
        }
      }
      if (kDebugMode) {
        print("Guardando datos principales del técnico...");
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nombre': nombre,
        'correo': email,
        'tipo': 'tecnico',
        'especialidad': especialidad,
        'telefono': telefonoNormalizado, // Guardar teléfono normalizado
        'direccion': direccion,
        'fotoPerfil': fotoUrl,
        'documentos': urlsDocs,
        'calificacion': 0.0,
        'totalServicios': 0,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print("Datos principales guardados.");
      }
      if (kDebugMode) {
        print("Guardando ubicación con GeoFirestore...");
      }
      final GeoFirestore geoFirestore = GeoFirestore(FirebaseFirestore.instance.collection('users'));
      final GeoPoint punto = GeoPoint(_ubicacionTecnico!.latitude, _ubicacionTecnico!.longitude);
      await geoFirestore.setLocation(uid, punto);
      if (kDebugMode) {
        print("Ubicación GeoFirestore guardada.");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Técnico registrado con éxito'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje = 'Error al registrar';
      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo electrónico ya está registrado.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña proporcionada es muy débil.';
      } else {
        mensaje = 'Error de autenticación: ${e.message ?? e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent));
      if (kDebugMode) {
        print('Error de Firebase Auth (Registro Técnico): (${e.code}) ${e.message}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error general en registro de técnico: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar: ${e.toString()}'), backgroundColor: Colors.redAccent)
        );
      }
      if (user != null) {
        try {
          await user.delete();
          if (kDebugMode) {
            print("Usuario de Auth borrado debido a error en registro.");
          }
        } catch (deleteError) {
          if (kDebugMode) {
            print("Error al intentar borrar usuario de Auth después de fallo: $deleteError");
          }
        }
      }
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Técnico'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _fotoPerfil != null ? FileImage(_fotoPerfil!) : null,
                    child: _fotoPerfil == null ? const Icon(Icons.person_add_alt_1, size: 50, color: Colors.grey) : null,
                  ),
                  TextButton(
                    onPressed: _isLoading || _buscandoUbicacionTecnico ? null : _seleccionarFotoPerfil,
                    child: const Text('Subir foto de Perfil'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CampoTexto(label: 'Nombre de Usuario:', controller: nombreController),
              const SizedBox(height: 12),
              CampoTexto(label: 'Email:', controller: emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              CampoTexto(label: 'Contraseña (mín 6 car.):', controller: passwordController, obscureText: true),
              const SizedBox(height: 12),
              CampoTexto(label: 'Repetir Contraseña:', controller: repetirPasswordController, obscureText: true),
              const SizedBox(height: 12),
              CampoTexto(label: 'Especialidad (Ej: Gasfitería):', controller: especialidadController),
              const SizedBox(height: 12),
              CampoTexto(label: 'Teléfono (+56 9 XXXX XXXX):', controller: telefonoController, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              CampoTexto(label: 'Dirección (Referencia textual):', controller: direccionController),
              const SizedBox(height: 20),

              const Text('Ubicación de Referencia (Taller/Domicilio)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (_buscandoUbicacionTecnico)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              if (!_buscandoUbicacionTecnico && _ubicacionTecnico != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Ubicación Obtenida ✓\n(${_ubicacionTecnico!.latitude.toStringAsFixed(4)}, ${_ubicacionTecnico!.longitude.toStringAsFixed(4)})",
                    style: TextStyle(color: Colors.green[800]),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!_buscandoUbicacionTecnico && _errorUbicacionTecnico != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_errorUbicacionTecnico!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                ),
              ElevatedButton.icon(
                onPressed: _isLoading || _buscandoUbicacionTecnico ? null : _obtenerUbicacionActualTecnico,
                icon: const Icon(Icons.my_location),
                label: const Text('Obtener Mi Ubicación Actual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _isLoading || _buscandoUbicacionTecnico ? null : _seleccionarDocumentos,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Subir documentos (Opcional)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              if (_documentos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Documentos seleccionados: ${_documentos.length}", style: const TextStyle(color: Colors.black54)),
                ),
              const SizedBox(height: 16), // Espacio antes de checkbox

              //  Checkbox y texto de aceptación de términos
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (bool? value) {
                      setState(() {
                        _aceptaTerminos = value ?? false;
                      });
                    },
                    activeColor: Colors.blueAccent,
                    checkColor: Colors.white, // Color de la marca de verificación
                    // Cambiar color del borde para que sea visible sobre fondo gris claro
                    side: WidgetStateBorderSide.resolveWith(
                          (states) => BorderSide(width: 2, color: states.contains(WidgetState.selected) ? Colors.blueAccent : Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3), // Color de texto para fondo claro
                        children: [
                          const TextSpan(text: 'He leído y acepto los '),
                          TextSpan(
                            text: 'Términos y Condiciones',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor, // Usar color primario del tema
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TerminosCondicionesScreen()),
                                );
                              },
                          ),
                          const TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor, // Usar color primario del tema
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),

              ElevatedButton(
                // Deshabilitar si no acepta términos o si está cargando
                onPressed: _isLoading || _buscandoUbicacionTecnico || !_aceptaTerminos ? null : _registrarTecnico,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Registrar Técnico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget CampoTexto reutilizable
class CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;

  const CampoTexto(
      {super.key, required this.label, required this.controller, this.keyboardType = TextInputType.text, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
}