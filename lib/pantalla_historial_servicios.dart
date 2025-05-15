import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Para mostrar estrellas

class PantallaHistorialServicios extends StatefulWidget {
  final String tecnicoID;

  const PantallaHistorialServicios({
    super.key,
    required this.tecnicoID,
  });

  @override
  State<PantallaHistorialServicios> createState() => _PantallaHistorialServiciosState();
}

class _PantallaHistorialServiciosState extends State<PantallaHistorialServicios> {
  late Future<List<Map<String, dynamic>>> _historialFuture;

  @override
  void initState() {
    super.initState();
    _historialFuture = _fetchHistorialServicios();
  }

  Future<List<Map<String, dynamic>>> _fetchHistorialServicios() async {
    print("Fetching historial de servicios para tecnicoID: ${widget.tecnicoID}");
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .where('tecnicoID', isEqualTo: widget.tecnicoID)
          .where('estado', whereIn: ['calificado', 'rechazado', 'cancelado_usuario', 'cancelado_tecnico']) // Estados finales
          .orderBy('fecha', descending: true) // O 'fechaCalificacion'/'fechaFinalizacionTecnico' si es más relevante
          .limit(50) // Limitar para no cargar demasiado de golpe
          .get();

      print("Servicios en historial encontrados: ${querySnapshot.docs.length}");
      List<Map<String, dynamic>> historial = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Guardar el ID por si lo necesitas
        historial.add(data);
      }
      return historial;
    } catch (e) {
      print("Error al cargar historial de servicios: $e");
      throw Exception("Error al cargar historial: $e");
    }
  }

  String _getDisplayEstado(String estadoDB) {
    switch (estadoDB) {
      case 'calificado':
        return 'Completado y Calificado';
      case 'rechazado':
        return 'Rechazado por Técnico';
      case 'cancelado_usuario': // Asumiendo que podrías tener este estado
        return 'Cancelado por Cliente';
      case 'cancelado_tecnico': // Asumiendo que podrías tener este estado
        return 'Cancelado por Técnico';
      default:
        return estadoDB; // Muestra el estado crudo si no está mapeado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Servicios'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error al cargar el historial: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No hay servicios en tu historial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final serviciosDelHistorial = snapshot.data!;

          return ListView.builder(
            itemCount: serviciosDelHistorial.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final servicioData = serviciosDelHistorial[index];
              final String descripcion = servicioData['descripcion'] as String? ?? 'Sin descripción';
              final String estadoDB = servicioData['estado'] as String? ?? 'desconocido';
              final String estadoDisplay = _getDisplayEstado(estadoDB); // Usar función para estado legible

              final Timestamp? fechaTimestamp = servicioData['fecha'] as Timestamp?; // Fecha de solicitud
              // Podrías querer mostrar fecha de finalización o calificación si es más relevante
              final Timestamp? fechaFinalTimestamp = servicioData['fechaFinalizacionTecnico'] as Timestamp? ?? servicioData['fechaCalificacion'] as Timestamp? ?? fechaTimestamp;


              final String fechaStr = fechaFinalTimestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm', 'es_CL').format(fechaFinalTimestamp.toDate())
                  : 'Fecha no disponible';

              final String usuarioNombre = servicioData['usuarioNombre'] as String? ?? 'Cliente Desconocido';
              final double? estrellas = (servicioData['estrellas'] as num?)?.toDouble();
              final String comentario = servicioData['comentario'] as String? ?? '';

              Color estadoColor = Colors.grey;
              if (estadoDB == 'calificado') estadoColor = Colors.green;
              if (estadoDB == 'rechazado' || estadoDB.startsWith('cancelado')) estadoColor = Colors.redAccent;


              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding( // Usar Padding en lugar de ListTile para más control
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(descripcion, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Cliente: $usuarioNombre'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Estado: ', style: TextStyle(color: Colors.grey[700])),
                          Text(estadoDisplay, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Fecha: $fechaStr', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (estadoDB == 'calificado') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Calificación: ', style: TextStyle(color: Colors.grey[700])),
                            if (estrellas != null && estrellas > 0)
                              RatingBarIndicator(
                                rating: estrellas,
                                itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                itemCount: 5,
                                itemSize: 18.0,
                                unratedColor: Colors.amber.withAlpha(80),
                              )
                            else
                              const Text('No calificado con estrellas', style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        if (comentario.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Comentario: "$comentario"', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}