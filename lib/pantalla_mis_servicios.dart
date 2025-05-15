import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login.dart';
import 'perfil_tecnico.dart';
import 'pantalla_historial_servicios.dart';

class PantallaMisServicios extends StatefulWidget {
  final String tecnicoID;

  const PantallaMisServicios({
    super.key,
    required this.tecnicoID,
  });

  @override
  State<PantallaMisServicios> createState() => _PantallaMisServiciosState();
}

class _PantallaMisServiciosState extends State<PantallaMisServicios> {
  bool _isLoggingOut = false;
  Stream<QuerySnapshot>? _serviciosStream;
  Map<String, bool> _isUpdatingService = {};

  @override
  void initState() {
    super.initState();
    _cargarServiciosStream();
    print("Dashboard del técnico ${widget.tecnicoID} iniciado.");
  }

  void _cargarServiciosStream() {
    if (!mounted) return;
    _serviciosStream = FirebaseFirestore.instance
        .collection('servicios')
        .where('tecnicoID', isEqualTo: widget.tecnicoID)
        .where('estado', whereNotIn: ['calificado', 'rechazado', 'cancelado'])
        .orderBy('fecha', descending: true)
        .snapshots();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PantallaLogin()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error al cerrar sesión (desde Mis Servicios): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _aceptarServicio(String servicioId) async {
    if (_isUpdatingService[servicioId] == true) return;
    if (!mounted) return;
    setState(() => _isUpdatingService[servicioId] = true);
    try {
      await FirebaseFirestore.instance.collection('servicios').doc(servicioId).update({
        'estado': 'aceptado',
      });
    } catch (e) {
      print("Error al aceptar servicio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al aceptar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingService[servicioId] = false);
      }
    }
  }

  Future<void> _rechazarServicio(String servicioId) async {
    if (_isUpdatingService[servicioId] == true) return;
    if (!mounted) return;
    setState(() => _isUpdatingService[servicioId] = true);

    print("Intentando RECHAZAR servicio: $servicioId");
    // --- AÑADE O VERIFICA ESTE PRINT ---
    final Map<String, dynamic> datosParaActualizar = {'estado': 'rechazado'};
    print("Datos que se enviarán para rechazar: $datosParaActualizar");
    // --- FIN AÑADE O VERIFICA ---
    try {
      await FirebaseFirestore.instance.collection('servicios').doc(servicioId).update({
        'estado': 'rechazado',
      });
    } catch (e) {
      print("Error al rechazar servicio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al rechazar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingService[servicioId] = false);
      }
    }
  }

  Future<void> _marcarComoFinalizado(String servicioId) async {
    if (_isUpdatingService[servicioId] == true) return;
    if (!mounted) return;
    setState(() => _isUpdatingService[servicioId] = true);
    try {
      await FirebaseFirestore.instance.collection('servicios').doc(servicioId).update({
        'estado': 'pendiente_calificacion',
        'fechaFinalizacionTecnico': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al finalizar servicio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al finalizar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingService[servicioId] = false);
      }
    }
  }

  Future<void> _llamarCliente(String? telefono) async {
    if (telefono == null || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono del cliente no disponible.')),
      );
      return;
    }
    final Uri url = Uri.parse('tel:$telefono');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw Exception('No se pudo iniciar la llamada a $url');
      }
    } catch (e) {
      print("Error al intentar llamar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo realizar la llamada: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _contactarClienteWhatsApp(String? telefono, String nombreCliente) async {
    if (telefono == null || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono del cliente no disponible.')),
      );
      return;
    }
    String numeroWhatsApp = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroWhatsApp.startsWith('9') && numeroWhatsApp.length == 9) {
      numeroWhatsApp = '56$numeroWhatsApp';
    } else if (numeroWhatsApp.startsWith('569') && numeroWhatsApp.length == 11) {
      // Correct format
    } else {
      if (telefono.startsWith('+') && telefono.length > 1) {
        numeroWhatsApp = telefono.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formato de teléfono no compatible con WhatsApp.')),
        );
        return;
      }
    }
    final String mensaje = Uri.encodeComponent("Hola $nombreCliente, soy el técnico de Cerragas en camino.");
    final Uri url = Uri.parse('https://wa.me/$numeroWhatsApp?text=$mensaje');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir WhatsApp para $url');
      }
    } catch (e) {
      print("Error al intentar abrir WhatsApp: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir WhatsApp: ${e.toString()}')),
        );
      }
    }
  }

  void _navegarAHistorialServicios() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaHistorialServicios(tecnicoID: widget.tecnicoID),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Servicios Activos'),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Ver/Editar Mi Perfil',
            onPressed: _isLoggingOut ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaPerfilTecnico(tecnicoID: widget.tecnicoID),
                ),
              );
            },
          ),
          _isLoggingOut
              ? const Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
          )
              : IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _serviciosStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error en StreamBuilder MisServicios: ${snapshot.error}");
            return Center(child: Text('Error al cargar servicios: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No tienes servicios activos en este momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final services = snapshot.data!.docs;
          return ListView.builder(
            itemCount: services.length,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemBuilder: (context, index) {
              final serviceDoc = services[index];
              final data = serviceDoc.data() as Map<Object?, Object?>? ?? {};
              final String descripcion = (data['descripcion'] as String?) ?? 'Sin descripción';
              final String estado = (data['estado'] as String?) ?? 'desconocido';
              final Timestamp? fechaTimestamp = data['fecha'] as Timestamp?;
              final String fechaStr = fechaTimestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm', 'es_CL').format(fechaTimestamp.toDate())
                  : 'Fecha no disponible';
              final String usuarioID = (data['usuarioID'] as String?) ?? 'Usuario desconocido';
              final String usuarioNombre = (data['usuarioNombre'] as String?) ?? usuarioID;
              final String? usuarioTelefono = data['usuarioTelefono'] as String?;
              final bool isUpdatingThisService = _isUpdatingService[serviceDoc.id] ?? false;
              Widget? trailingWidget;

              if (estado == 'solicitado') {
                trailingWidget = isUpdatingThisService
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: isUpdatingThisService ? null : () => _aceptarServicio(serviceDoc.id),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 11)
                      ),
                      child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: isUpdatingThisService ? null : () => _rechazarServicio(serviceDoc.id),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 11)
                      ),
                      child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              } else if (estado == 'aceptado') {
                trailingWidget = isUpdatingThisService
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Tooltip(
                  message: 'Marcar este servicio como completado',
                  child: ElevatedButton(
                    onPressed: isUpdatingThisService ? null : () => _marcarComoFinalizado(serviceDoc.id),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    ),
                    child: const Text('Finalizar', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                );
              } else {
                trailingWidget = Tooltip(
                  message: 'Servicio $estado',
                  child: Icon(
                      estado == 'pendiente_calificacion' ? Icons.hourglass_bottom_outlined :
                      estado == 'calificado' ? Icons.check_circle_outline :
                      Icons.info_outline,
                      color: Colors.grey.shade500),
                );
              }

              // --- MODIFICADO: Estructura del Card para nuevo layout ---
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 3, // Un poco más de elevación para destacar
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordes más suaves
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row( // Fila principal para dividir izquierda (info+contacto) y derecha (acciones)
                    crossAxisAlignment: CrossAxisAlignment.start, // Alinear contenido de las columnas al inicio
                    children: [
                      // Columna izquierda para información y botones de contacto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              descripcion,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Cliente: $usuarioNombre'),
                            Text('Estado: $estado', style: TextStyle(color: estado == 'solicitado' ? Colors.orange.shade700 : (estado == 'aceptado' ? Colors.blue.shade700 : Colors.grey.shade700), fontWeight: FontWeight.w500)),
                            Text('Fecha: $fechaStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            // Fila para botones de contacto (si hay teléfono)
                            if (usuarioTelefono != null && usuarioTelefono.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start, // Alinear al inicio
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone_forwarded_outlined),
                                    color: Colors.blueAccent,
                                    tooltip: 'Llamar a $usuarioNombre ($usuarioTelefono)',
                                    iconSize: 24,
                                    onPressed: isUpdatingThisService ? null : () => _llamarCliente(usuarioTelefono),
                                  ),
                                  const SizedBox(width: 16), // Espacio entre botones
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.whatsapp),
                                    color: Colors.green,
                                    tooltip: 'Enviar WhatsApp a $usuarioNombre ($usuarioTelefono)',
                                    iconSize: 24,
                                    onPressed: isUpdatingThisService ? null : () => _contactarClienteWhatsApp(usuarioTelefono, usuarioNombre),
                                  ),
                                ],
                              )
                            else
                              Padding( // Si no hay teléfono, mostrar un texto o dejar vacío
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Teléfono del cliente no disponible.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Widget de acciones a la derecha (trailing)
                      if (trailingWidget != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0), // Espacio entre info y acciones
                          child: trailingWidget,
                        ),
                    ],
                  ),
                ),
              );
              // --- FIN MODIFICADO ---
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoggingOut ? null : _navegarAHistorialServicios,
        tooltip: 'Ver Historial de Servicios',
        icon: const Icon(Icons.history, color: Colors.white),
        label: const Text('Historial',
            style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

