import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'politica_privacidad.dart';
import 'terminos_condiciones.dart';

class PantallaRegistroUsuario extends StatefulWidget {
  const PantallaRegistroUsuario({super.key});

  @override
  State<PantallaRegistroUsuario> createState() => _PantallaRegistroUsuarioState();
}

class _PantallaRegistroUsuarioState extends State<PantallaRegistroUsuario> {
  // Controllers
  late TextEditingController nombreController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController repetirPasswordController;
  late TextEditingController telefonoController;

  // Variables de estado
  bool _isLoading = false;
  String? _errorMessage;
  bool _aceptaTerminos = false; // Estado para el checkbox de términos

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final _telefonoRegexCL = RegExp(r'^\+?56\s?9\s?\d{8}$');


  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    repetirPasswordController = TextEditingController();
    telefonoController = TextEditingController();
  }

  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repetirPasswordController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    if (!_aceptaTerminos) {
      setState(() {
        _errorMessage = 'Debes aceptar los Términos y Condiciones y la Política de Privacidad para continuar.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final nombre = nombreController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final repetirPassword = repetirPasswordController.text.trim();
    final telefono = telefonoController.text.trim();

    // Validaciones
    if ([nombre, email, password, repetirPassword, telefono].any((e) => e.isEmpty)) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
        _isLoading = false;
      });
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'El correo ingresado no es válido';
        _isLoading = false;
      });
      return;
    }
    if (!_telefonoRegexCL.hasMatch(telefono)) {
      setState(() {
        _errorMessage = 'El formato del teléfono debe ser +56 9 XXXX XXXX';
        _isLoading = false;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
        _isLoading = false;
      });
      return;
    }
    if (password != repetirPassword) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
        _isLoading = false;
      });
      return;
    }

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
      await cred.user?.updateDisplayName(nombre);
      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nombre': nombre,
        'correo': email,
        'telefono': telefonoNormalizado,
        'tipo': 'usuario',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        String mensaje = 'Error al registrar';
        if (e.code == 'email-already-in-use') {
          mensaje = 'El correo electrónico ya está registrado.';
        } else if (e.code == 'weak-password') {
          mensaje = 'La contraseña proporcionada es muy débil.';
        } else {
          mensaje = 'Error: ${e.message ?? e.code}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
        );
        if (kDebugMode) {
          print('Error de Firebase Auth (Registro): (${e.code}) ${e.message}');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ocurrió un error inesperado. Inténtalo de nuevo.'),
              backgroundColor: Colors.redAccent
          ),
        );
        if (kDebugMode) {
          print('Error inesperado (Registro): $e');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset('assets/logo.png', width: 300, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CampoTexto(label: 'Nombre de Usuario:', controller: nombreController),
                    const SizedBox(height: 16),
                    CampoTexto(label: 'Email:', controller: emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    CampoTexto(
                        label: 'Teléfono (+56 9 XXXX XXXX):',
                        controller: telefonoController,
                        keyboardType: TextInputType.phone
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(label: 'Contraseña (mín 6 car.):', controller: passwordController, obscureText: true),
                    const SizedBox(height: 16),
                    CampoTexto(label: 'Repetir Contraseña:', controller: repetirPasswordController, obscureText: true),
                    const SizedBox(height: 16),

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
                          checkColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.3),
                              children: [
                                const TextSpan(text: 'He leído y acepto los '),
                                TextSpan(
                                  text: 'Términos y Condiciones',
                                  style: const TextStyle(
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
                                  style: const TextStyle(
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
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      // --- CORRECCIÓN AQUÍ ---
                      onPressed: (_isLoading || !_aceptaTerminos) ? null : _registerUser,
                      // --- FIN CORRECCIÓN ---
                      child: _isLoading
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Registrar Usuario', style: TextStyle(fontSize: 16)),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Volver al inicio',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
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

  const CampoTexto({super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
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
      ),
    );
  }
}