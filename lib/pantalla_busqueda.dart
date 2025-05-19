import 'historial_usuario.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'pantalla_calificacion.dart';
import 'resultado_busqueda.dart';


class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({super.key});

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> with WidgetsBindingObserver {
  // Controllers para los campos de texto
  final TextEditingController especialidadController = TextEditingController();
  final TextEditingController tarifaController = TextEditingController();
  final TextEditingController calificacionController = TextEditingController();
  final TextEditingController generoController = TextEditingController();
  final TextEditingController distanciaController = TextEditingController();

  // Variables de estado para la UI y la lógica
  bool _isLoading = false; // Para el botón de logout y otras cargas generales si es necesario
  bool _isCheckingRating = false; // Para el botón de calificar servicio
  Position? _ubicacionActual; // Almacena la ubicación actual del usuario
  bool _buscandoUbicacion = false; // Indica si se está obteniendo la ubicación
  String? _errorUbicacion; // Mensaje de error si falla la obtención de ubicación
  bool _ubicacionActivable = true; // Controla si se puede intentar obtener la ubicación


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    especialidadController.dispose();
    tarifaController.dispose();
    calificacionController.dispose();
    generoController.dispose();
    distanciaController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_buscandoUbicacion) {
      if (kDebugMode) {
        print("App Resumed - Re-checking location status...");
      }
      _obtenerUbicacionActual();
    }
  }

  Future<Position?> _obtenerUbicacionActual() async {
    if (_buscandoUbicacion) return _ubicacionActual;
    if (!_ubicacionActivable && _errorUbicacion != null) {
      if(mounted && _buscandoUbicacion) {
        setState(() => _buscandoUbicacion = false);
      }
      return null;
    }

    if (!mounted) return null;
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
    });

    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      const mensajeError = 'Los servicios de ubicación están desactivados.';
      setState(() {
        _errorUbicacion = mensajeError;
        _buscandoUbicacion = false;
        _ubicacionActivable = false;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(mensajeError),
            backgroundColor: Colors.orange[700],
            action: SnackBarAction(
              label: 'ACTIVAR', textColor: Colors.white,
              onPressed: () { Geolocator.openLocationSettings(); },
            ),
            duration: const Duration(seconds: 7),
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        setState(() {
          _errorUbicacion = 'Permiso de ubicación denegado.';
          _buscandoUbicacion = false;
          _ubicacionActivable = false;
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacion!), backgroundColor: Colors.redAccent));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      setState(() {
        _errorUbicacion = 'Permiso denegado permanentemente.';
        _buscandoUbicacion = false;
        _ubicacionActivable = false;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorUbicacion!), backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'AJUSTES', textColor: Colors.white,
              onPressed: () { Geolocator.openAppSettings(); },
            ),
            duration: const Duration(seconds: 7),
          ),
        );
      }
      return null;
    }

    if(mounted && !_ubicacionActivable) {
      setState(() => _ubicacionActivable = true );
    }
    if (kDebugMode) {
      print("Obteniendo ubicación actual...");
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return null;
      setState(() {
        _ubicacionActual = position;
        _buscandoUbicacion = false;
        _errorUbicacion = null;
        _ubicacionActivable = true;
      });
      if (kDebugMode) {
        print("Ubicación obtenida: $_ubicacionActual");
      }
      return position;
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener ubicación: $e");
      }
      if (!mounted) return null;
      setState(() {
        _errorUbicacion = 'No se pudo obtener la ubicación.';
        _buscandoUbicacion = false;
        _ubicacionActivable = false;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacion!), backgroundColor: Colors.redAccent));
      return null;
    }
  }

  String _normalizarEspecialidad(String input) {
    if (input.isEmpty) return "";
    String textoNormalizado = input.toLowerCase();
    textoNormalizado = textoNormalizado
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
    if (textoNormalizado == "gasfiter" || textoNormalizado == "gasfiteria" || textoNormalizado == "gasfitería") {
      return "gasfiteria";
    } else if (textoNormalizado == "cerrajero" || textoNormalizado == "cerrajeria" || textoNormalizado == "cerrajería") {
      return "cerrajeria";
    }
    if (kDebugMode) {
      print("Especialidad no reconocida para normalización: '$input', se usará tal cual: '${input.trim()}'");
    }
    return input.trim();
  }

  Future<void> _buscarTecnicos() async {
    if (_buscandoUbicacion || _isLoading) return;
    final Position? ubicacionObtenida = await _obtenerUbicacionActual();
    if (kDebugMode) {
      print(ubicacionObtenida == null ? "Continuando búsqueda SIN ubicación." : "Continuando búsqueda CON ubicación.");
    }
    final String especialidadInput = especialidadController.text.trim();
    final String especialidadParaFirestore = especialidadInput.isNotEmpty ? _normalizarEspecialidad(especialidadInput) : "";
    if (kDebugMode) {
      print("Especialidad ingresada: '$especialidadInput'");
    }
    if (kDebugMode) {
      print("Especialidad normalizada para Firestore: '$especialidadParaFirestore'");
    }
    final tarifaStr = tarifaController.text.trim();
    final calificacionStr = calificacionController.text.trim();
    final distanciaStr = distanciaController.text.trim();
    double? distanciaKm;

    if (ubicacionObtenida != null) {
      if (distanciaStr.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Con ubicación activa, por favor ingresa una distancia máxima (Km).'), backgroundColor: Colors.orangeAccent),
          );
        }
        return;
      }
      distanciaKm = double.tryParse(distanciaStr);
      if (distanciaKm == null || distanciaKm <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La distancia debe ser un número válido y mayor a cero (Km).'), backgroundColor: Colors.orangeAccent),
          );
        }
        return;
      }
    } else {
      distanciaKm = null;
    }
    if (kDebugMode) {
      print("--- Iniciando Navegación a Resultados ---");
    }
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaResultados(
            especialidad: especialidadParaFirestore,
            tarifa: tarifaStr,
            calificacion: calificacionStr,
            genero: generoController.text.trim(),
            distancia: distanciaStr,
            ubicacionUsuario: ubicacionObtenida,
            radioKm: distanciaKm,
          ),
        ),
      );
    }
  }

  Future<void> _navegarACalificacion() async {
    if (!mounted) return;
    setState(() => _isCheckingRating = true);
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      setState(() => _isCheckingRating = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .where('usuarioID', isEqualTo: usuario.uid)
          .where('estado', isEqualTo: 'pendiente_calificacion')
          .limit(1)
          .get();
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final tecnicoID = data.containsKey('tecnicoID') ? data['tecnicoID'] as String? : null;
        if (tecnicoID != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaCalificacionServicio(servicioID: doc.id, tecnicoID: tecnicoID),
            ),
          );
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se encontró el ID del técnico en el servicio.')));
        }
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay servicios pendientes por calificar.')));
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al buscar servicio pendiente: $e");
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al verificar calificaciones: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isCheckingRating = false);
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PantallaLogin()), (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error al cerrar sesión: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Función para navegar al historial del usuario
  void _navegarAHistorialUsuario() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaHistorialUsuario(usuarioID: currentUser.uid),
        ),
      );
    } else {
      // Esto no debería pasar si el usuario está en esta pantalla, pero por si acaso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado para ver historial.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: const Text('Buscar Técnico'),
        automaticallyImplyLeading: false,
        actions: [
          // Botón de Historial de Usuario
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mi Historial de Servicios',
            onPressed: _isLoading ? null : _navegarAHistorialUsuario,
          ),

          _isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 10.0, left: 10.0), // Ajustar padding si es necesario
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
          )
              : IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset('assets/logo.png', width: 300, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),

            if (_buscandoUbicacion)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10), Text("Obteniendo ubicación...")
                ]),
              ),
            if (_ubicacionActual != null && !_buscandoUbicacion)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                child: Text("Ubicación obtenida ✓", style: TextStyle(fontSize: 12, color: Colors.green[800]), textAlign: TextAlign.center),
              ),
            if (_errorUbicacion != null && !_buscandoUbicacion)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                child: Text(_errorUbicacion!, style: TextStyle(fontSize: 12, color: Colors.redAccent[700]), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 10),

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
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CampoTexto(label: 'Especialidad (Ej: Gasfitería o Cerrajería):', controller: especialidadController),
                      const SizedBox(height: 16),
                      CampoTexto(label: 'Tarifa Máxima (Ej: 50000):', controller: tarifaController, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      CampoTexto(label: 'Calificación Mínima (Ej: 4):', controller: calificacionController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 16),
                      CampoTexto(
                        label: 'Distancia Máxima (Km):',
                        controller: distanciaController,
                        keyboardType: TextInputType.number,
                        enabled: _ubicacionActivable && !_buscandoUbicacion,
                        hintText: !_ubicacionActivable ? '(Ubicación no disponible)' : null,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _buscandoUbicacion || _isLoading ? null : _buscarTecnicos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _buscandoUbicacion
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Buscar Técnicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isLoading || _isCheckingRating ? null : _navegarACalificacion,
                        icon: _isCheckingRating
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.star),
                        label: const Text('Calificar un Servicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

// Widget reutilizable para campos de texto
class CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final String? hintText;

  const CampoTexto({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.hintText,
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
        hintText: hintText,
        filled: true,
        fillColor: enabled ? Colors.grey[200] : Colors.grey[350],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}