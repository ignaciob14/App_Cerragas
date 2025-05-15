import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geo_firestore_flutter/geo_firestore_flutter.dart';
import 'perfil_tecnico.dart';

// StatefulWidget Modificado para aceptar ubicación y radio
class PantallaResultados extends StatefulWidget {
  final String especialidad;
  final String tarifa;
  final String calificacion;
  final String genero;
  final String distancia;
  final Position? ubicacionUsuario; // <-- Ubicación del usuario
  final double? radioKm; // <-- Radio de búsqueda en KM

  const PantallaResultados({
    super.key,
    this.especialidad = '',
    this.tarifa = '',
    this.calificacion = '',
    this.genero = '',
    this.distancia = '',
    this.ubicacionUsuario,
    this.radioKm,
  });

  @override
  State<PantallaResultados> createState() => _PantallaResultadosState();
}

class _PantallaResultadosState extends State<PantallaResultados> {
  late Future<List<Map<String, dynamic>>> _tecnicosFuture;

  @override
  void initState() {
    super.initState();
    _tecnicosFuture = _obtenerTecnicos(
      especialidad: widget.especialidad,
      tarifa: widget.tarifa,
      calificacion: widget.calificacion,
      genero: widget.genero,
      ubicacionDelUsuario: widget.ubicacionUsuario,
      radioEnKm: widget.radioKm,
    );
  }

  // --- Lógica para obtener técnicos (ADAPTADA para geo_firestore_flutter) ---
  Future<List<Map<String, dynamic>>> _obtenerTecnicos({
    required String especialidad,
    required String tarifa,
    required String calificacion,
    required String genero,
    Position? ubicacionDelUsuario,
    double? radioEnKm,
  }) async {
    print("Iniciando _obtenerTecnicos (usando geo_firestore_flutter)...");
    print("Ubicación Usuario (recibida): ${ubicacionDelUsuario?.latitude}, ${ubicacionDelUsuario?.longitude}");
    print("Radio Km (recibido): $radioEnKm");

    List<DocumentSnapshot> docs = [];
    const String campoGeoPoint = 'l';

    try {
      // --- CORRECCIÓN APLICADA AQUÍ ---
      // Añadir explícitamente el tipo <Map<String, dynamic>>
      final CollectionReference<Map<String, dynamic>> collectionRef = FirebaseFirestore.instance.collection('users');
      // --- FIN CORRECCIÓN ---


      if (ubicacionDelUsuario != null && radioEnKm != null && radioEnKm > 0) {
        print("Realizando consulta geográfica con geo_firestore_flutter...");
        // 1. Crear instancia de GeoFirestore (ahora usa la collectionRef tipada)
        final GeoFirestore geoFirestore = GeoFirestore(collectionRef);
        // 2. Crear GeoPoint para el centro
        final GeoPoint centro = GeoPoint(ubicacionDelUsuario.latitude, ubicacionDelUsuario.longitude);
        // 3. Ejecutar la consulta getAtLocation
        final List<DocumentSnapshot> docsGeo = await geoFirestore.getAtLocation(centro, radioEnKm);
        print("Docs encontrados por geo-query: ${docsGeo.length}");
        // 4. Filtrar por tipo 'tecnico' (necesario hacerlo en cliente)
        docs = docsGeo.where((doc) {
          final data = doc.data() as Map<String, dynamic>?; // Cast explícito
          return data != null && data['tipo'] == 'tecnico';
        }).toList();
        print("Docs filtrados por tipo 'tecnico': ${docs.length}");

      } else {
        print("Realizando consulta NO geográfica...");
        // Empezar con la referencia tipada y aplicar filtros
        Query<Map<String, dynamic>> query = collectionRef.where('tipo', isEqualTo: 'tecnico');

        if (especialidad.isNotEmpty) {
          query = query.where('especialidad', isEqualTo: especialidad);
        }
        double? califMin = double.tryParse(calificacion);
        if (califMin != null) {
          query = query.where('calificacion', isGreaterThanOrEqualTo: califMin);
          query = query.orderBy('calificacion', descending: true);
        } else {
          query = query.orderBy('calificacion', descending: true);
        }
        double? tarifaMax = double.tryParse(tarifa);
        if (tarifa.isNotEmpty && califMin == null && tarifaMax != null) {
          query = query.where('tarifa', isLessThanOrEqualTo: tarifaMax);
        }

        // Obtener el snapshot de la consulta tipada
        final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
        docs = snapshot.docs; // Los docs ya son del tipo correcto
        print("Docs encontrados por consulta NO geo: ${docs.length}");
      }

      // --- Procesar y Filtrar Resultados en Cliente ---
      List<Map<String, dynamic>> tecnicosData = [];
      double? tarifaMaxFiltroCliente = double.tryParse(tarifa);
      double? califMinFiltroCliente = (ubicacionDelUsuario != null && radioEnKm != null && radioEnKm > 0)
          ? double.tryParse(calificacion)
          : null;

      for (var doc in docs) { // doc es ahora DocumentSnapshot<Map<String, dynamic>>
        if (doc.exists) {
          // El data() ya es del tipo correcto Map<String, dynamic>?
          final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          data['docId'] = doc.id; // Añadir ID del documento
          bool pasaFiltros = true;

          // Aplicar filtros restantes...
          if (ubicacionDelUsuario != null && radioEnKm != null && radioEnKm > 0 && especialidad.isNotEmpty) {
            if (data['especialidad'] != especialidad) pasaFiltros = false;
          }
          if (pasaFiltros && califMinFiltroCliente != null) {
            final double? tecCalif = (data['calificacion'] as num?)?.toDouble();
            if (tecCalif == null || tecCalif < califMinFiltroCliente) pasaFiltros = false;
          }
          if (pasaFiltros && tarifaMaxFiltroCliente != null) {
            final double? tecTarifa = (data['tarifa'] as num?)?.toDouble();
            if (tecTarifa == null || tecTarifa > tarifaMaxFiltroCliente) pasaFiltros = false;
          }
          // TODO: Aplicar filtro de Género

          if (pasaFiltros) {
            // Calcular distancia (usando el campo 'l')
            if (ubicacionDelUsuario != null) {
              final dynamic locationData = data[campoGeoPoint]; // Obtener campo 'l'
              GeoPoint? tecGeoPoint;

              if (locationData is GeoPoint) { // Verificar si es GeoPoint
                tecGeoPoint = locationData;
              } else if (locationData is List && locationData.length == 2 && locationData[0] is num && locationData[1] is num) {
                // Verificar si es Lista [lat, lon]
                tecGeoPoint = GeoPoint((locationData[0] as num).toDouble(), (locationData[1] as num).toDouble());
              }

              if (tecGeoPoint != null) {
                final double distanciaMetros = Geolocator.distanceBetween(
                    ubicacionDelUsuario.latitude, ubicacionDelUsuario.longitude,
                    tecGeoPoint.latitude, tecGeoPoint.longitude
                );
                data['distanciaKm'] = distanciaMetros / 1000.0;
                print("Técnico ${data['nombre']} (${doc.id}) a ${data['distanciaKm']?.toStringAsFixed(1)} km");
              } else {
                data['distanciaKm'] = null;
                print("Técnico ${data['nombre']} (${doc.id}) no tiene datos de ubicación válidos en campo '$campoGeoPoint'.");
              }
            } else {
              data['distanciaKm'] = null;
            }
            tecnicosData.add(data);
          }
        }
      }

      // Ordenar por distancia si aplica
      if (ubicacionDelUsuario != null) {
        tecnicosData.sort((a, b) {
          final distA = a['distanciaKm'] as double?;
          final distB = b['distanciaKm'] as double?;
          if (distA == null && distB == null) return 0;
          if (distA == null) return 1;
          if (distB == null) return -1;
          return distA.compareTo(distB);
        });
      }

      print("Técnicos finales después de filtros/distancia: ${tecnicosData.length}");
      return tecnicosData;

    } catch (e) {
      print("Error completo en _obtenerTecnicos: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        throw Exception('Consulta requiere índice: Revisa el log de Firebase para crearlo.');
      }
      if (e is FirebaseException && e.code == 'permission-denied') {
        throw Exception('Permiso denegado por Firestore. Revisa reglas de seguridad.');
      }
      throw Exception('Error al cargar técnicos: ${e.toString()}');
    }
  }
  // --- Fin _obtenerTecnicos ---


  // --- Método Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Búsqueda'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tecnicosFuture,
        builder: (context, snapshot) {
          // Manejo de estados del Future (sin cambios)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding( // Añadido Padding para mejor visualización del error
              padding: const EdgeInsets.all(16.0),
              child: Text('Ocurrió un error al cargar los técnicos.\n${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding( // Añadido Padding
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No se encontraron técnicos que coincidan con tus criterios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Construcción de la lista (sin cambios en la lógica de visualización)
          final tecnicos = snapshot.data!;
          return ListView.builder(
            itemCount: tecnicos.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final tecnico = tecnicos[index];
              final tecnicoId = tecnico['docId'] as String?;
              final distanciaKm = tecnico['distanciaKm'] as double?;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: tecnico['fotoPerfil'] != null && (tecnico['fotoPerfil'] as String).isNotEmpty
                        ? NetworkImage(tecnico['fotoPerfil'])
                        : const AssetImage('assets/avatar.png') as ImageProvider,
                    onBackgroundImageError: (_, __) {
                      print("Error cargando imagen: ${tecnico['fotoPerfil']}");
                    },
                  ),
                  title: Text(tecnico['nombre'] ?? 'Nombre no disponible'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Especialidad: ${tecnico['especialidad'] ?? 'N/A'}'),
                      Text('Calificación: ${tecnico['calificacion']?.toStringAsFixed(1) ?? 'N/A'} ⭐'),
                      if (tecnico['tarifa'] != null)
                        Text('Tarifa base: \$${tecnico['tarifa']}'), // Asume tipo numérico
                      if (distanciaKm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Distancia: ${distanciaKm.toStringAsFixed(1)} km aprox.', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (tecnicoId != null) {
                      print("Navegando a perfil con ID: $tecnicoId");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaPerfilTecnico(
                            tecnicoID: tecnicoId,
                          ),
                        ),
                      );
                    } else {
                      print("Error: No se encontró 'docId' para este técnico en el mapa de datos.");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error interno: No se pudo obtener el ID del técnico.')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}