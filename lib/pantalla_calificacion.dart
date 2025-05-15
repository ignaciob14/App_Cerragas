import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Asegúrate de tener este paquete
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import necesario

class PantallaCalificacionServicio extends StatefulWidget {
  final String servicioID;
  final String tecnicoID;

  const PantallaCalificacionServicio({
    super.key,
    required this.servicioID,
    required this.tecnicoID,
  });

  @override
  State<PantallaCalificacionServicio> createState() => _PantallaCalificacionServicioState();
}

class _PantallaCalificacionServicioState extends State<PantallaCalificacionServicio> {
  // Controller y estado
  final TextEditingController comentarioController = TextEditingController();
  File? imagenSeleccionada;
  double calificacion = 3.0; // Valor por defecto
  bool _isLoading = false; // Estado de carga para la subida

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  // --- Funciones de Imagen ---
  Future<void> _seleccionarImagen() async {
    if (_isLoading) return;
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      if (!mounted) return;
      setState(() {
        imagenSeleccionada = File(imagen.path);
      });
    }
  }

  Future<String?> _subirImagen(File imagen) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('calificaciones/${widget.servicioID}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imagen);
    return await ref.getDownloadURL();
  }
  // --- Fin Funciones de Imagen ---


  // --- Lógica Principal para Subir Calificación (VERSIÓN FINAL LIMPIA) ---
  Future<void> _subirCalificacion() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final comentario = comentarioController.text.trim();
    String? imagenUrl;
    bool exitoGeneral = false;

    // No necesitamos los prints de UID aquí en la versión final

    try {
      // 1. Subir imagen si existe
      if (imagenSeleccionada != null) {
        imagenUrl = await _subirImagen(imagenSeleccionada!);
      }

      // 2. Actualizar Servicio y Técnico en una Transacción
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final refServicio = FirebaseFirestore.instance.collection('servicios').doc(widget.servicioID);
        // Asegurar tipado de referencia para lectura dentro de transacción
        final refTecnico = FirebaseFirestore.instance.collection('users').doc(widget.tecnicoID) as DocumentReference<Map<String, dynamic>>;

        final snapshotTecnico = await transaction.get(refTecnico);
        if (!snapshotTecnico.exists) {
          throw Exception("El técnico no existe (ID: ${widget.tecnicoID})");
        }
        // Usar data()! después de verificar exists es seguro
        final dataTecnico = snapshotTecnico.data()!;
        final double calificacionActual = (dataTecnico['calificacion'] as num?)?.toDouble() ?? 0.0;
        final int totalServiciosActual = (dataTecnico['totalServicios'] as int?) ?? 0;

        final double nuevaCalificacionUsuario = calificacion;
        final int nuevoTotalServicios = totalServiciosActual + 1;
        // Evitar división por cero si es el primer servicio (aunque totalServiciosActual debería ser >= 0)
        final double nuevaMediaTecnico = (nuevoTotalServicios == 0)
            ? nuevaCalificacionUsuario // Si es el primero, la media es la calificación actual
            : ((calificacionActual * totalServiciosActual) + nuevaCalificacionUsuario) / nuevoTotalServicios;


        // Actualizar documento del Servicio
        transaction.update(refServicio, {
          'estrellas': nuevaCalificacionUsuario,
          'comentario': comentario.isEmpty ? null : comentario,
          'estado': 'calificado',
          'imagen_url': imagenUrl,
          'fechaCalificacion': FieldValue.serverTimestamp(),
        });

        // --- Actualización de Técnico REACTIVADA ---
        transaction.update(refTecnico, {
          'calificacion': nuevaMediaTecnico,
          'totalServicios': nuevoTotalServicios,
        });
        // --- FIN Actualización de Técnico ---
      }); // Fin Transacción

      exitoGeneral = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calificación enviada con éxito'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      // Mantenemos el log del error por si acaso
      print("Error al subir calificación (versión final): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar calificación: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted && !exitoGeneral) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- Fin _subirCalificacion ---


  // --- Método Build (Sin Cambios) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificación del Servicio'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: Colors.blue[400],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              // Selector de Imagen
              GestureDetector(
                onTap: _isLoading ? null : _seleccionarImagen,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white54, width: 1)
                  ),
                  child: imagenSeleccionada != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.file(imagenSeleccionada!, fit: BoxFit.cover),
                  )
                      : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.black54),
                        SizedBox(height: 8),
                        Text("Añadir foto (Opcional)", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Campo de Comentarios
              _campoTexto(
                label: 'Agregar comentarios (Opcional):',
                controller: comentarioController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 25),
              // Rating Bar
              const Text(
                'Calificación General:',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              IgnorePointer(
                ignoring: _isLoading,
                child: RatingBar.builder(
                  initialRating: calificacion,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 45,
                  unratedColor: Colors.grey[300]?.withAlpha(150),
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                  onRatingUpdate: (rating) { calificacion = rating; },
                ),
              ),
              const SizedBox(height: 40),
              // Botón Subir Calificación
              ElevatedButton(
                onPressed: _isLoading ? null : _subirCalificacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enviar Calificación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper local para campo de texto (Sin Cambios) ---
  Widget _campoTexto({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.multiline,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}