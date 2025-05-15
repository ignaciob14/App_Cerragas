import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'login.dart';
import 'registro_usuarios.dart';
import 'registro_tecnicos.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Inicializaciones estándar
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_CL', null);
  print("Datos de localización 'es_CL' inicializados.");
  // Activacion de App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Pruebas en emulador
    // appleProvider: AppleProvider.appAttest, // Para producción en iOS
  );
  runApp(const CerragasApp());
}

class CerragasApp extends StatelessWidget {
  const CerragasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cerragas',
      // --- NUEVO: ThemeData para estilos globales ---
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Estilo para todas las AppBars de la aplicación
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          titleTextStyle: TextStyle(
            color: Colors.white, // Color del texto del título
            fontSize: 20,        // Tamaño de fuente estándar para títulos de AppBar
            fontWeight: FontWeight.bold, // O FontWeight.w500 si prefieres un poco menos grueso
          ),

          // Estilo para los iconos en el leading ( flecha de atrás)
          iconTheme: IconThemeData(
            color: Colors.white, // Color de los iconos de leading
          ),
          actionsIconTheme: IconThemeData(
            color: Colors.white, // Color de los iconos de actions
          ),

          // Para asegurar que el brillo del AppBar sea oscuro, lo que hace que los iconos
          // y texto de estado (hora, batería del sistema) tiendan a ser blancos.
          // Esto es más relevante si no estableces foregroundColor.
          // brightness: Brightness.dark, // Comentado porque foregroundColor debería manejarlo
        ),
      ),
      // --- FIN NUEVO ---
      home: const PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Fondo gris atras del área azul
      body: SafeArea(
        child: Column( // Columna principal que ocupa toda la SafeArea
          children: [
            // Espacio superior
            const SizedBox(height: 40),

            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding horizontal
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'assets/logo.png', // ruta correcta del logo en pubspec.yaml
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 40), // Espacio entre logo y área azul

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
                padding:
                const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BotonInicio(
                      texto: 'Iniciar Sesión',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PantallaLogin()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    BotonInicio(
                      texto: 'Registro de Usuarios',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PantallaRegistroUsuario()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    BotonInicio(
                      texto: 'Registro de Técnicos',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PantallaRegistroTecnico()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BotonInicio extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonInicio({super.key, required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
