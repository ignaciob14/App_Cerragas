import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'perfil_tecnico.dart';

class PantallaHistorialUsuario extends StatefulWidget {
  final String usuarioID;

  const PantallaHistorialUsuario({
    super.key,
    required this.usuarioID,
  });

  @override
  State<PantallaHistorialUsuario> createState() => _PantallaHistorialUsuarioState();
}

class _PantallaHistorialUsuarioState extends State<PantallaHistorialUsuario> {
  late Future<List<Map<String, dynamic>>> _historialServiciosFuture;

  @override
  void initState() {
    super.initState();
    _historialServiciosFuture = _fetchHistorialServicios();
  }

  Future<List<Map<String, dynamic>>> _fetchHistorialServicios() async {
    print("Fetching historial de servicios para usuarioID: ${widget.usuarioID}");
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .where('usuarioID', isEqualTo: widget.usuarioID)
      // Podrías querer ordenar por 'fecha' (creación del servicio) o 'fechaCalificacion' si existe
          .orderBy('fecha', descending: true)
          .get();

      print("Servicios en historial de usuario encontrados: ${querySnapshot.docs.length}");
      List<Map<String, dynamic>> historial = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Guardar el ID del documento del servicio
        historial.add(data);
      }
      return historial;
    } catch (e) {
      print("Error al cargar historial de servicios del usuario: $e");
      // Propagar el error para que FutureBuilder lo maneje
      throw Exception("Error al cargar historial: $e");
    }
  }

  // Función para obtener un texto legible del estado del servicio
  String _getDisplayEstado(String? estadoDB) {
    switch (estadoDB) {
      case 'solicitado':
        return 'Solicitado';
      case 'aceptado':
        return 'Aceptado por Técnico';
      case 'pendiente_calificacion':
        return 'Finalizado - Pendiente Calificación';
      case 'calificado':
        return 'Completado y Calificado';
      case 'rechazado':
        return 'Rechazado por Técnico';
      case 'cancelado_usuario': // Asumiendo que podrías tener este estado
        return 'Cancelado por Usuario';
      case 'cancelado_tecnico': // Asumiendo que podrías tener este estado
        return 'Cancelado por Técnico';
      default:
        return estadoDB ?? 'Desconocido';
    }
  }

  // Función para navegar al perfil del técnico
  void _navegarAPerfilTecnico(String tecnicoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaPerfilTecnico(tecnicoID: tecnicoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Servicios'),
        backgroundColor: Colors.blueAccent,
        // El color de los iconos y texto del AppBar se hereda del tema global
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historialServiciosFuture,
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
                  'No tienes servicios en tu historial.',
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

              // Extracción segura de datos
              final String descripcion = servicioData['descripcion'] as String? ?? 'Sin descripción';
              final String? estadoDB = servicioData['estado'] as String?;
              final String estadoDisplay = _getDisplayEstado(estadoDB);

              final Timestamp? fechaTimestamp = servicioData['fecha'] as Timestamp?;
              final String fechaStr = fechaTimestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm', 'es_CL').format(fechaTimestamp.toDate())
                  : 'Fecha no disponible';

              // Nombre del técnico (denormalizado)
              final String tecnicoNombre = servicioData['tecnicoNombre'] as String? ?? 'Técnico Desconocido';
              final String? tecnicoID = servicioData['tecnicoID'] as String?; // Necesario para navegar al perfil

              // Color para el estado
              Color estadoColor = Colors.grey.shade700;
              if (estadoDB == 'calificado' || estadoDB == 'aceptado' || estadoDB == 'pendiente_calificacion') {
                estadoColor = Colors.green.shade700;
              } else if (estadoDB == 'rechazado' || estadoDB == 'cancelado_usuario' || estadoDB == 'cancelado_tecnico') {
                estadoColor = Colors.red.shade700;
              } else if (estadoDB == 'solicitado') {
                estadoColor = Colors.orange.shade700;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descripcion,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text('Técnico: $tecnicoNombre', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Estado: ', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                          Text(
                            estadoDisplay,
                            style: TextStyle(fontSize: 14, color: estadoColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Fecha Solicitud: $fechaStr', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      if (tecnicoID != null) // Mostrar botón solo si hay ID de técnico
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.person_search_outlined, size: 18),
                            label: const Text('Ver Técnico'),
                            onPressed: () => _navegarAPerfilTecnico(tecnicoID),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13)
                            ),
                          ),
                        ),
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