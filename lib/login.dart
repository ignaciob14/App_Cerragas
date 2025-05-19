import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pantalla_busqueda.dart';
import 'pantalla_mis_servicios.dart';

// PantallaLogin StatefulWidget
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controllers
  late TextEditingController emailController;
  late TextEditingController passwordController;

  //  Estado para visibilidad de contraseña
  bool _isPasswordVisible = false;

  // Variables de estado
  bool _isLoading = false; // Para el botón de login
  //  Estado de carga para reset password
  bool _isResettingPassword = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Lógica de inicio de sesión
  Future<void> _login() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Por favor, complete todos los campos.";
        _isLoading = false;
      });
      return;
    }

    User? user;

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      user = userCredential.user;

      if (user != null) {
        try {
          final docSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

          if (mounted && docSnap.exists) {
            final data = docSnap.data();
            final userType = data?['tipo'] as String?;

            if (kDebugMode) {
              print("Usuario autenticado: ${user.email}, Tipo: $userType");
            }

            if (userType == 'tecnico') {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaMisServicios(tecnicoID: user!.uid),
                ),
              );
            } else if (userType == 'usuario') {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PantallaBusqueda()),
              );
            } else {
              // Tipo desconocido
              if (!mounted) return;
              setState(() {
                _errorMessage = "Error: Tipo de usuario desconocido.";
                _isLoading = false;
              });
              await FirebaseAuth.instance.signOut();
            }
          } else {
            // Datos no encontrados
            if (!mounted) return;
            setState(() {
              _errorMessage = "Error: Datos de usuario no encontrados.";
              _isLoading = false;
            });
            await FirebaseAuth.instance.signOut();
          }
        } catch (e) {
          // Error leyendo Firestore
          if (kDebugMode) {
            print("Error al leer datos de Firestore: $e");
          }
          if (!mounted) return;
          setState(() {
            _errorMessage = "Error al obtener datos del usuario.";
            _isLoading = false;
          });
          // Desconectar el usuario en caso de error al leer datos después de autenticar
          await FirebaseAuth.instance.signOut();
        }
      }

      if (mounted && _isLoading && _errorMessage != null) {
        setState(() => _isLoading = false);
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          _errorMessage = 'El correo electrónico no es válido o no está registrado.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'La contraseña es incorrecta.';
        } else {
          _errorMessage = 'Error de autenticación. Intenta de nuevo.'; // Mensaje genérico
        }
        if (kDebugMode) {
          print('Error de Firebase Auth (Login): (${e.code}) ${e.message}');
        }
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado en login: $e');
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = "Ocurrió un error inesperado.";
        _isLoading = false;
      });
    }

  }

  //  Lógica para recuperar contraseña
  Future<void> _resetPassword() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu correo electrónico para recuperar la contraseña.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isResettingPassword = true;
      _errorMessage = null; // Limpiar errores previos
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado un correo para restablecer tu contraseña.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Error al enviar correo de recuperación: (${e.code}) ${e.message}");
      }
      if (!mounted) return;
      String mensajeError = 'Error al enviar el correo.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        mensajeError = 'El correo electrónico no está registrado o no es válido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error inesperado en recuperación: $e");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado al intentar recuperar la contraseña.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo Email (sin cambios)
                      CampoTexto(
                        label: 'Email:',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading && !_isResettingPassword, // Deshabilitar si carga algo
                      ),
                      const SizedBox(height: 20),

                      //  Campo Contraseña con visibilidad
                      CampoTexto(
                        label: 'Contraseña:',
                        controller: passwordController,
                        obscureText: !_isPasswordVisible, // Controlado por estado
                        enabled: !_isLoading && !_isResettingPassword, // Deshabilitar si carga algo
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            //  permitir cambiar si no está cargando
                            if (!_isLoading && !_isResettingPassword) {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            }
                          },
                        ),
                      ),

                      // Botón Recuperar Contraseña
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 10.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            // Deshabilitar si alguna operación está en curso
                            onPressed: _isLoading || _isResettingPassword ? null : _resetPassword,
                            child: _isResettingPassword
                                ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20), // Espacio ajustado

                      // Botón Entrar
                      ElevatedButton(
                        // Deshabilitar si alguna operación está en curso
                        onPressed: _isLoading || _isResettingPassword ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text('Entrar', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 10),

                      // Mensaje de Error
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Botón Volver
                      TextButton(
                        // Deshabilitar si alguna operación está en curso
                        onPressed: _isLoading || _isResettingPassword ? null : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PantallaInicio()),
                          );
                        },
                        child: const Text(
                          'Volver al inicio',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Widget CampoTexto reutilizable
class CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;

  const CampoTexto({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        //  Cambiar color si está deshabilitado
        fillColor: enabled ? Colors.grey[200] : Colors.grey[350],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorText: null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}