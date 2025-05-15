import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'editar_perfil_tecnico.dart';
import 'login.dart';

class PantallaPerfilTecnico extends StatefulWidget {
  final String tecnicoID;

  const PantallaPerfilTecnico({
    super.key,
    required this.tecnicoID,
  });

  @override
  State<PantallaPerfilTecnico> createState() => _PantallaPerfilTecnicoState();
}

class _PantallaPerfilTecnicoState extends State<PantallaPerfilTecnico> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _tecnicoDataFuture;
  late Future<List<Map<String, dynamic>>> _comentariosFuture;
  late Future<int> _contactosSemanaFuture;
  bool esTecnicoActual = false;
  bool _isLoadingContact = false;
  bool _isLoggingOut = false;

  // --- NUEVO: Variable para almacenar el nombre del técnico una vez cargado ---
  String? _nombreDelTecnicoActual;
  // --- FIN NUEVO ---

  @override
  void initState() {
    super.initState();
    _tecnicoDataFuture = _fetchTecnicoData();
    _comentariosFuture = _fetchComentarios();
    _contactosSemanaFuture = _fetchContactosSemana();
    _verificarTipoUsuario();

    // --- NUEVO: Cargar el nombre del técnico para usarlo después ---
    _tecnicoDataFuture.then((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        setState(() {
          _nombreDelTecnicoActual = data?['nombre'] as String?;
        });
      }
    }).catchError((error) {
      print("Error al precargar nombre del técnico: $error");
      // Manejar el error como sea apropiado, quizás _nombreDelTecnicoActual quede null
    });
    // --- FIN NUEVO ---
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchTecnicoData() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.tecnicoID)
        .get();
  }

  Future<List<Map<String, dynamic>>> _fetchComentarios() async {
    print("Fetching comentarios para tecnicoID: ${widget.tecnicoID}");
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .where('tecnicoID', isEqualTo: widget.tecnicoID)
          .where('estado', isEqualTo: 'calificado')
          .where('comentario', isNotEqualTo: null)
          .where('comentario', isNotEqualTo: '')
          .orderBy('fechaCalificacion', descending: true)
          .limit(10)
          .get();
      print("Comentarios encontrados: ${querySnapshot.docs.length}");
      List<Map<String, dynamic>> comentarios = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        comentarios.add(data);
      }
      return comentarios;
    } catch (e) {
      print("Error al cargar comentarios: $e");
      throw Exception("Error al cargar comentarios: $e");
    }
  }

  Future<int> _fetchContactosSemana() async {
    print("Fetching contactos semana para tecnicoID: ${widget.tecnicoID}");
    try {
      final DateTime ahora = DateTime.now();
      final DateTime hace7Dias = ahora.subtract(const Duration(days: 7));
      final Timestamp timestampHace7Dias = Timestamp.fromDate(hace7Dias);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .where('tecnicoID', isEqualTo: widget.tecnicoID)
          .where('fecha', isGreaterThanOrEqualTo: timestampHace7Dias)
          .count()
          .get();
      print("Contactos encontrados en la última semana: ${querySnapshot.count}");
      return querySnapshot.count ?? 0;
    } catch (e) {
      print("Error al cargar contador de contactos: $e");
      return 0;
    }
  }

  Future<void> _verificarTipoUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid == widget.tecnicoID) {
      if (!mounted) return;
      setState(() {
        esTecnicoActual = true;
      });
    }
  }

  // --- Lógica de Registro de Servicio (MODIFICADA) ---
  Future<void> _registrarServicio(String medio, String? tecnicoNombre) async { // <-- MODIFICADO: Acepta tecnicoNombre
    if (!mounted) return;
    setState(() => _isLoadingContact = true);
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      try {
        String? usuarioNombre = usuario.displayName;
        String? usuarioTelefono;

        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(usuario.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            usuarioNombre = (userData?['nombre'] as String?) ?? usuarioNombre ?? "Cliente";
            usuarioTelefono = userData?['telefono'] as String?;
          } else {
            usuarioNombre = usuarioNombre ?? "Cliente";
            print("Advertencia: No se encontró el documento del usuario ${usuario.uid} para obtener teléfono.");
          }
        } catch (e) {
          print("Error al obtener datos del usuario cliente: $e");
          usuarioNombre = usuarioNombre ?? "Cliente";
          usuarioTelefono = null;
        }

        await FirebaseFirestore.instance.collection('servicios').add({
          "usuarioID": usuario.uid,
          "usuarioNombre": usuarioNombre,
          "usuarioTelefono": usuarioTelefono,
          "tecnicoID": widget.tecnicoID,
          // --- NUEVO: Guardar nombre del técnico ---
          "tecnicoNombre": tecnicoNombre ?? "Técnico no especificado", // Nombre del técnico de este perfil
          // --- FIN NUEVO ---
          "fecha": Timestamp.now(),
          "descripcion": "Servicio contratado vía $medio",
          "estado": "solicitado",
          "estrellas": null,
          "comentario": null,
          "imagen_url": null,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio registrado con éxito'), backgroundColor: Colors.green),
        );

        if (mounted) {
          setState(() {
            _contactosSemanaFuture = _fetchContactosSemana();
          });
        }

      } catch (e) {
        print("Error al registrar servicio: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar el servicio: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (!mounted) return;
        setState(() => _isLoadingContact = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Debes iniciar sesión para registrar un servicio.'), backgroundColor: Colors.redAccent),
      );
      if(mounted) setState(() => _isLoadingContact = false);
    }
  }

  // --- Lógica de Confirmación (MODIFICADA) ---
  Future<void> _confirmarYRegistrar(String medio, String? telefonoTecnico, String? nombreTecnico) async { // <-- MODIFICADO: Acepta nombreTecnico
    if (telefonoTecnico == null || telefonoTecnico.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono no disponible.')),
      );
      return;
    }

    Uri? url;
    if (medio == "llamada") {
      url = Uri.parse('tel:$telefonoTecnico');
    } else if (medio == "WhatsApp") {
      String whatsAppNumber = telefonoTecnico.replaceAll(RegExp(r'[^0-9]'), '');
      // Ajustar formato para WhatsApp (ej. +569xxxxxxxx -> 569xxxxxxxx)
      if (whatsAppNumber.startsWith('+') && whatsAppNumber.length > 1) {
        whatsAppNumber = whatsAppNumber.substring(1);
      }
      // Asumiendo que el número ya tiene el código de país correcto para wa.me
      url = Uri.parse('https://wa.me/$whatsAppNumber?text=Hola,%20vi%20tu%20perfil%20en%20Cerragas');
    }

    if (url != null) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;

          final bool? confirmacion = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Registrar Servicio'),
              content: const Text('¿Contactaste a este técnico para solicitar un servicio?\n(Registrar permite calificar después)'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No / Aún no')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, Contacté')),
              ],
            ),
          );

          if (confirmacion == true) {
            // --- MODIFICADO: Pasar nombreTecnico ---
            await _registrarServicio(medio, nombreTecnico);
            // --- FIN MODIFICADO ---
          }
        } else {
          throw Exception('No se pudo lanzar $url');
        }
      } catch (e) {
        print("Error al lanzar URL o en diálogo: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo $medio. Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logoutTecnico() async {
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
      print("Error al cerrar sesión (técnico): $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
      );
      setState(() => _isLoggingOut = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final appBarController = DefaultAppBarController.maybeOf(context);

    return Scaffold(
      appBar: AppBar(
        // --- MODIFICADO: Usar _nombreDelTecnicoActual si está disponible para el título ---
        title: Text(appBarController == null
            ? (_nombreDelTecnicoActual != null ? 'Perfil de $_nombreDelTecnicoActual' : "Perfil Técnico")
            : "Cargando..."),
        // --- FIN MODIFICADO ---
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: esTecnicoActual ? 'Cerrar Sesión / Volver' : 'Volver',
          onPressed: _isLoggingOut
              ? null
              : () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              if (esTecnicoActual) {
                _logoutTecnico();
              }
            }
          },
        ),
        actions: [
          if (esTecnicoActual)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar Perfil',
              onPressed: _isLoggingOut ? null : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaEditarPerfilTecnico(tecnicoID: widget.tecnicoID),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {
                    _tecnicoDataFuture = _fetchTecnicoData();
                    // --- NUEVO: Actualizar nombre y contactos si se edita ---
                    _tecnicoDataFuture.then((snapshot) {
                      if (snapshot.exists && mounted) {
                        final data = snapshot.data();
                        setState(() {
                          _nombreDelTecnicoActual = data?['nombre'] as String?;
                        });
                      }
                    });
                    _contactosSemanaFuture = _fetchContactosSemana();
                    // --- FIN NUEVO ---
                  });
                }
              },
            ),
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            ),
        ],
      ),
      backgroundColor: Colors.grey[300],
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _tecnicoDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !(snapshot.data?.exists ?? false)) {
            print("Error en FutureBuilder: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el perfil del técnico.${snapshot.error != null ? "\nDetalle: ${snapshot.error}" : "\nPerfil no encontrado."}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final tecnicoData = snapshot.data!.data()!;
          // --- MODIFICADO: Usar _nombreDelTecnicoActual si ya se cargó, sino el de tecnicoData ---
          final nombre = _nombreDelTecnicoActual ?? tecnicoData['nombre'] as String? ?? 'Nombre no disponible';
          // --- FIN MODIFICADO ---
          final fotoUrl = tecnicoData['fotoPerfil'] as String?;
          final calificacion = tecnicoData['calificacion'] as num? ?? 0.0;
          final tarifa = tecnicoData['tarifa'] as num?;
          final telefono = tecnicoData['telefono'] as String?;
          final int totalServicios = (tecnicoData['totalServicios'] as int?) ?? 0;

          // Actualizar título del AppBar si no se hizo con _nombreDelTecnicoActual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && appBarController != null && appBarController.setTitle != null && _nombreDelTecnicoActual == null) {
              appBarController.setTitle!(Text('Perfil de $nombre'));
            }
          });

          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: const BorderRadius.all(Radius.circular(40)),
              ),
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                        ? NetworkImage(fotoUrl)
                        : const AssetImage('assets/avatar.png') as ImageProvider,
                    onBackgroundImageError: (_, __) { print("Error cargando imagen de perfil: $fotoUrl"); },
                  ),
                  const SizedBox(height: 10),
                  Text(nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.yellowAccent, size: 24),
                      const SizedBox(width: 8),
                      Text(calificacion.toStringAsFixed(1), style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(' ($totalServicios Servicios)', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tarifa != null) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text('Tarifa base: \$${tarifa.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: _contactosSemanaFuture,
                    builder: (context, snapshotContactos) {
                      Widget displayWidget;
                      if (snapshotContactos.connectionState == ConnectionState.waiting) {
                        displayWidget = const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                      } else if (snapshotContactos.hasError) {
                        displayWidget = const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 20);
                        print("Error en FutureBuilder contactos: ${snapshotContactos.error}");
                      } else {
                        final int count = snapshotContactos.data ?? 0;
                        displayWidget = Text(
                          '$count',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.contact_phone_outlined, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          const Text('Contactos (últimos 7 días): ', style: TextStyle(fontSize: 16, color: Colors.white)),
                          displayWidget,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  if (!esTecnicoActual) ...[
                    ElevatedButton.icon(
                      // --- MODIFICADO: Pasar nombre del técnico ---
                      onPressed: _isLoadingContact || _isLoggingOut ? null : () => _confirmarYRegistrar("llamada", telefono, nombre),
                      // --- FIN MODIFICADO ---
                      icon: _isLoadingContact ? _buildLoadingIndicator() : const Icon(Icons.phone),
                      label: const Text('Llamar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      // --- MODIFICADO: Pasar nombre del técnico ---
                      onPressed: _isLoadingContact || _isLoggingOut ? null : () => _confirmarYRegistrar("WhatsApp", telefono, nombre),
                      // --- FIN MODIFICADO ---
                      icon: _isLoadingContact ? _buildLoadingIndicator() : const FaIcon(FontAwesomeIcons.whatsapp),
                      label: const Text('Enviar WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 20),
                  const Text(
                    'Últimas Calificaciones Recibidas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _comentariosFuture,
                    builder: (context, snapshotComentarios) {
                      if (snapshotComentarios.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                        );
                      }
                      if (snapshotComentarios.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(child: Text('Error al cargar comentarios.', style: TextStyle(color: Colors.red[100]))),
                        );
                      }
                      if (!snapshotComentarios.hasData || snapshotComentarios.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Text('Aún no hay calificaciones para mostrar.', style: TextStyle(color: Colors.white70))),
                        );
                      }

                      final comentarios = snapshotComentarios.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comentarios.length,
                        itemBuilder: (context, index) {
                          final comentarioData = comentarios[index];
                          final String textoComentario = comentarioData['comentario'] as String? ?? 'Sin comentario escrito.';
                          final double estrellas = (comentarioData['estrellas'] as num?)?.toDouble() ?? 0.0;
                          final Timestamp? fechaTimestamp = comentarioData['fechaCalificacion'] as Timestamp?;
                          final String fechaFormateada = fechaTimestamp != null
                              ? DateFormat('dd MMM yy', 'es_CL').format(fechaTimestamp.toDate())
                              : 'Fecha no disp.';
                          final String? usuarioNombre = comentarioData['usuarioNombre'] as String?;

                          bool mostrarComentarioCard = true;
                          if ((comentarioData['comentario'] == null || (comentarioData['comentario'] as String).isEmpty) && estrellas == 0.0) {
                            mostrarComentarioCard = false;
                          }

                          if (!mostrarComentarioCard) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            color: Colors.white.withOpacity(0.15),
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      RatingBarIndicator(
                                        rating: estrellas,
                                        itemBuilder: (context, index) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 18.0,
                                        unratedColor: Colors.amber.withAlpha(80),
                                        direction: Axis.horizontal,
                                      ),
                                      Text(fechaFormateada, style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    ],
                                  ),
                                  if (usuarioNombre != null && usuarioNombre.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text("De: $usuarioNombre", style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic)),
                                  ],
                                  if (textoComentario != 'Sin comentario escrito.' && textoComentario.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      textoComentario,
                                      style: TextStyle(color: Colors.white, fontSize: 14),
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
    );
  }
}

class DefaultAppBarController extends InheritedWidget {
  final Function(Widget?) setTitle;
  const DefaultAppBarController({super.key, required this.setTitle, required Widget child}) : super(child: child);

  static DefaultAppBarController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DefaultAppBarController>();
  }

  @override
  bool updateShouldNotify(DefaultAppBarController oldWidget) {
    return setTitle != oldWidget.setTitle;
  }
}
