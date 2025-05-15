import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geo_firestore_flutter/geo_firestore_flutter.dart';

class PantallaEditarPerfilTecnico extends StatefulWidget {
  final String tecnicoID;
  const PantallaEditarPerfilTecnico({super.key, required this.tecnicoID});

  @override
  State<PantallaEditarPerfilTecnico> createState() => _PantallaEditarPerfilTecnicoState();
}

class _PantallaEditarPerfilTecnicoState extends State<PantallaEditarPerfilTecnico> {
  // Controllers
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController especialidadController = TextEditingController();
  final TextEditingController comunasController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController tarifaController = TextEditingController();

  // Estados
  bool cargando = true;
  bool guardando = false;
  String? _errorCarga;

  // --- Variables de Estado para Ubicación ---
  Position? _nuevaUbicacionTecnico; // Guarda la *nueva* posición si se obtiene
  bool _buscandoUbicacionTecnico = false; // Indicador mientras se busca
  String? _errorUbicacionTecnico; // Mensaje de error de ubicación
  // --- Fin Variables Ubicación ---


  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    // Desechar controllers
    nombreController.dispose();
    especialidadController.dispose();
    comunasController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    tarifaController.dispose();
    super.dispose();
  }

  // --- Cargar Datos Iniciales ---
  Future<void> cargarDatos() async {
    // ... (Tu función cargarDatos existente, sin cambios necesarios aquí) ...
    if (!mounted) return;
    setState(() { cargando = true; _errorCarga = null; });
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.tecnicoID).get();
      final data = doc.data();
      if (mounted && data != null) {
        nombreController.text = data['nombre'] ?? '';
        especialidadController.text = data['especialidad'] ?? '';
        comunasController.text = data['comunas'] ?? '';
        telefonoController.text = data['telefono'] ?? '';
        direccionController.text = data['direccion'] ?? '';
        tarifaController.text = (data['tarifa'] != null) ? data['tarifa'].toString() : '';
        // No cargamos la ubicación aquí, el usuario debe presionar el botón para actualizarla
      } else if (mounted && !doc.exists) {
        _errorCarga = "No se encontró el perfil del técnico.";
      }
    } catch (e) {
      print("Error al cargar datos del perfil: $e");
      if (mounted) { _errorCarga = "Error al cargar los datos. Intenta de nuevo."; }
    } finally {
      if (mounted) { setState(() { cargando = false; }); }
    }
  }
  // --- Fin cargarDatos ---

  // --- Función para obtener/actualizar ubicación ---
  Future<void> _obtenerUbicacionActualTecnico() async {
    if (guardando || _buscandoUbicacionTecnico) return;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.orange[700]));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() { _errorUbicacionTecnico = 'Permiso de ubicación denegado.'; _buscandoUbicacionTecnico = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.redAccent));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() { _errorUbicacionTecnico = 'Permiso denegado permanentemente.'; _buscandoUbicacionTecnico = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.redAccent));
      return;
    }

    print("Obteniendo ubicación actual del técnico...");
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _nuevaUbicacionTecnico = position; // Guardar la *nueva* ubicación
        _buscandoUbicacionTecnico = false;
        _errorUbicacionTecnico = null;
      });
      print("Nueva ubicación de Técnico obtenida: ${_nuevaUbicacionTecnico}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación obtenida. Guarda los cambios para aplicarla.'), duration: Duration(seconds: 3), backgroundColor: Colors.green));
    } catch (e) {
      print("Error al obtener ubicación del técnico: $e");
      if (!mounted) return;
      setState(() {
        _errorUbicacionTecnico = 'No se pudo obtener la ubicación: ${e.toString()}';
        _buscandoUbicacionTecnico = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorUbicacionTecnico!), backgroundColor: Colors.redAccent));
    }
  }
  // --- Fin Función Obtener Ubicación ---


  // --- Guardar Cambios (MODIFICADA para incluir ubicación con GeoFirestore) ---
  Future<void> guardarCambios() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    // Validaciones
    if ([nombreController, especialidadController, comunasController, telefonoController, direccionController, tarifaController]
        .any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
      );
      return;
    }
    final double? tarifa = double.tryParse(tarifaController.text.trim());
    if (tarifa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarifa debe ser un número válido')),
      );
      return;
    }

    if (!mounted) return;
    setState(() { guardando = true; });

    try {
      // 1. Actualizar datos principales en Firestore (SIN ubicación)
      print("Actualizando datos principales...");
      await FirebaseFirestore.instance.collection('users').doc(widget.tecnicoID).update({
        'nombre': nombreController.text.trim(),
        'especialidad': especialidadController.text.trim(),
        'comunas': comunasController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'direccion': direccionController.text.trim(),
        'tarifa': tarifa,
        // NO incluimos 'position' aquí
      });
      print("Datos principales actualizados.");

      // 2. Actualizar ubicación usando GeoFirestore SI se obtuvo una nueva
      if (_nuevaUbicacionTecnico != null) {
        print("Actualizando ubicación con GeoFirestore...");
        try {
          final GeoFirestore geoFirestore = GeoFirestore(FirebaseFirestore.instance.collection('users'));
          final GeoPoint punto = GeoPoint(_nuevaUbicacionTecnico!.latitude, _nuevaUbicacionTecnico!.longitude);
          await geoFirestore.setLocation(widget.tecnicoID, punto); // Actualiza 'g' y 'l'
          print("Ubicación GeoFirestore actualizada.");
        } catch (e) {
          print("Error al actualizar ubicación con GeoFirestore: $e");
          // Opcional: Mostrar un warning, pero no detener el flujo principal
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Perfil actualizado, pero hubo un error guardando la nueva ubicación: ${e.toString()}'), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        print("No se seleccionó nueva ubicación, omitiendo actualización de GeoFirestore.");
      }

      // --- Éxito (al menos de los datos principales) ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Indica que se guardó
      }

    } catch (e) {
      // Error al actualizar los datos principales
      print("Error al guardar cambios principales: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cambios: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() { guardando = false; });
      }
    }
  }
  // --- Fin guardarCambios ---


  @override
  Widget build(BuildContext context) {
    // --- Código del build con la sección de ubicación añadida ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Técnico'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorCarga!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Campos de texto existentes
            campo('Nombre', nombreController),
            campo('Especialidad', especialidadController),
            campo('Comunas donde atiende', comunasController),
            campo('Teléfono', telefonoController, TextInputType.phone),
            campo('Dirección (Referencia)', direccionController),
            campo('Tarifa Base (CLP)', tarifaController, TextInputType.number),
            const SizedBox(height: 20),

            // --- NUEVA SECCIÓN UBICACIÓN ---
            const Divider(),
            const SizedBox(height: 10),
            const Text('Actualizar Ubicación de Referencia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (_buscandoUbicacionTecnico)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            if (!_buscandoUbicacionTecnico && _nuevaUbicacionTecnico != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Nueva Ubicación Obtenida ✓\n(${_nuevaUbicacionTecnico!.latitude.toStringAsFixed(4)}, ${_nuevaUbicacionTecnico!.longitude.toStringAsFixed(4)})\n(Se guardará al presionar 'Guardar Cambios')",
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
              onPressed: guardando || _buscandoUbicacionTecnico ? null : _obtenerUbicacionActualTecnico,
              icon: const Icon(Icons.my_location),
              label: const Text('Obtener/Actualizar Mi Ubicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            // --- FIN NUEVA SECCIÓN ---

            const SizedBox(height: 20), // Espacio antes del botón guardar

            // Botón Guardar
            ElevatedButton(
              onPressed: guardando || _buscandoUbicacionTecnico ? null : guardarCambios, // Deshabilitar si busca ubicación también
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: guardando
                  ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper local para TextFields
  Widget campo(String label, TextEditingController controller, [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
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