import 'package:flutter/material.dart';

class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({super.key});

  // IMPORTANTE: Texto de la Política de Privacidad
  final String textoPoliticaPrivacidad = """
Política de Privacidad de App Cerragas

Fecha de Última Actualización: 07 de mayo de 2025

Bienvenido a Cerragas en adelante, como Aplicación. Nos comprometemos a proteger la privacidad de nuestros usuarios y técnicos. Esta Política de Privacidad explica cómo recopilamos, usamos, divulgamos y protegemos su información cuando utiliza nuestra aplicación móvil.   

Al descargar, registrarse o utilizar la Aplicación, usted acepta las prácticas descritas en esta Política de Privacidad. Si no está de acuerdo con los términos de esta política, por favor no acceda ni utilice la Aplicación.   

**1. INFORMACIÓN QUE RECOPILAMOS**

Podemos recopilar información sobre usted de varias maneras. La información que podemos recopilar a través de la Aplicación incluye:   

a. Datos Personales Proporcionados por Usted:
Usuarios (Clientes):  
Nombre completo
Dirección de correo electrónico
Contraseña (almacenada de forma segura y encriptada por Firebase Authentication)
Número de teléfono
Ubicación (cuando utiliza la función de búsqueda geolocalizada o solicita un servicio)
Descripciones de los servicios solicitados
Calificaciones, comentarios y fotos (opcionales) de los servicios recibidos.
Técnicos:  
Nombre completo
Dirección de correo electrónico
Contraseña (almacenada de forma segura y encriptada por Firebase Authentication)
Número de teléfono
Especialidad (ej. Gasfitería, Cerrajería)
Dirección de referencia o zona de cobertura
Ubicación de referencia (geolocalización)
Foto de perfil (opcional)
Documentos que acrediten su oficio (opcional, ej. certificados)
Tarifas base por sus servicios
Disponibilidad.

b. Datos Generados por el Uso de la Aplicación:
Información sobre los servicios solicitados, aceptados, finalizados o cancelados.
Interacciones entre Usuarios y Técnicos a través de la plataforma (ej. registro de contacto).
Historial de servicios.

c. Datos Recopilados Automáticamente:
Información del Dispositivo:  Podemos recopilar información sobre su dispositivo móvil, como el modelo, sistema operativo, identificadores únicos del dispositivo (si aplica y con su consentimiento), e información de la red móvil.   
Datos de Uso:  Podemos recopilar información sobre cómo accede y utiliza la Aplicación, como su dirección IP, tipo de navegador, páginas visitadas, tiempo empleado en las páginas, y otras estadísticas de uso (a través de servicios como Firebase Analytics).
Datos de Ubicación (con su consentimiento):  Si otorga permiso, podemos recopilar información de geolocalización de su dispositivo móvil para ofrecerle servicios basados en la ubicación, como encontrar técnicos cercanos. Puede desactivar la recopilación de ubicación a través de los ajustes de su dispositivo.

**2. USO DE SU INFORMACIÓN**

Usamos la información recopilada para diversos fines, que incluyen:
Crear y gestionar su cuenta.
Facilitar la conexión entre Usuarios y Técnicos para la prestación de servicios de gasfitería y cerrajería.
Mostrar el perfil de los Técnicos a los Usuarios.
Permitir a los Usuarios buscar Técnicos por especialidad, ubicación, tarifa y calificación.
Procesar y mostrar las calificaciones y comentarios de los servicios.
Permitir la comunicación entre Usuarios y Técnicos respecto a un servicio solicitado.
Mejorar la Aplicación y nuestros servicios.
Monitorear y analizar el uso y las tendencias para mejorar su experiencia.
Enviar comunicaciones administrativas, como confirmaciones de cuenta, actualizaciones de servicio o cambios en nuestras políticas.
Responder a sus comentarios y preguntas y proporcionar servicio al cliente.
Proteger la seguridad e integridad de nuestra Aplicación (ej. mediante Firebase App Check).
Cumplir con las obligaciones legales.

**3. DIVULGACIÓN DE SU INFORMACIÓN**

Podemos compartir la información que hemos recopilado sobre usted en ciertas situaciones:
Entre Usuarios y Técnicos:  
La información del perfil del Técnico (nombre, especialidad, foto de perfil, calificación promedio, comentarios de otros usuarios, tarifa base, zonas de servicio) será visible para los Usuarios que buscan servicios.
Cuando un Usuario contacta a un Técnico y se registra un servicio, compartiremos la información de contacto necesaria entre ambas partes (ej. nombre y número de teléfono del Usuario con el Técnico, y viceversa si el Técnico lo tiene en su perfil) para facilitar la coordinación del servicio.
La ubicación del Usuario solo se utiliza para la búsqueda inicial y no se comparte directamente con el Técnico a menos que sea parte de la dirección del servicio proporcionada por el Usuario.
Con Proveedores de Servicios de Terceros:  
Utilizamos Firebase (Google) como nuestra plataforma de backend para servicios como autenticación, base de datos (Firestore), almacenamiento de archivos (Storage), análisis (Analytics) y seguridad (App Check). Firebase tiene sus propias políticas de privacidad que rigen el uso de la información procesada a través de sus servicios.
Por Requerimiento Legal:  
Si la divulgación es necesaria para responder a un proceso legal, investigar posibles violaciones de nuestras políticas, o proteger los derechos, propiedad y seguridad de otros.
Transferencias Comerciales:  
En caso de fusión, venta de activos de la empresa, financiación o adquisición de la totalidad o una parte de nuestro negocio por otra empresa, su información puede ser transferida.   

**4. ALMACENAMIENTO Y SEGURIDAD DE SU INFORMACIÓN**

Tomamos medidas razonables, incluyendo salvaguardas administrativas, técnicas y físicas, para ayudar a proteger su información personal contra pérdida, robo, uso indebido y acceso no autorizado, divulgación, alteración y destrucción. Utilizamos los servicios de Firebase, que implementan medidas de seguridad estándar de la industria.   
Sin embargo, ningún sistema de seguridad es impenetrable y no podemos garantizar la seguridad absoluta de su información. Cualquier información que transmita es bajo su propio riesgo. Es su responsabilidad mantener la confidencialidad de su contraseña y restringir el acceso a su cuenta.

**5. SUS DERECHOS SOBRE SU INFORMACIÓN (DERECHOS ARCO)**

De acuerdo con la Ley N° 19.628, usted tiene ciertos derechos con respecto a sus datos personales:
Acceso:  Derecho a solicitar información sobre los datos personales que tenemos sobre usted.
Rectificación:  Derecho a solicitar la corrección de datos personales inexactos o incompletos.
Cancelación (Supresión):  Derecho a solicitar la eliminación de sus datos personales cuando ya no sean necesarios para los fines para los que fueron recopilados, o cuando retire su consentimiento (sujeto a ciertas excepciones legales).   
Oposición:  Derecho a oponerse al tratamiento de sus datos personales en determinadas circunstancias.
Para ejercer estos derechos, o si tiene alguna pregunta sobre sus datos personales, por favor contáctenos a través de Appcerragas@gmail.com. Responderemos a su solicitud dentro de los plazos legales.

**6. RETENCIÓN DE DATOS**

Retendremos su información personal durante el tiempo que su cuenta esté activa o según sea necesario para proporcionarle los servicios de la Aplicación, cumplir con nuestras obligaciones legales, resolver disputas y hacer cumplir nuestros acuerdos. Las calificaciones y comentarios pueden permanecer visibles de forma anónima o asociada al perfil del técnico incluso si la cuenta del usuario que los emitió es eliminada, para mantener la integridad del sistema de reputación.

**7. USO DE COOKIES Y TECNOLOGÍAS SIMILARES**

La Aplicación puede utilizar identificadores de dispositivo, almacenamiento local y tecnologías similares (incluidas las proporcionadas por Firebase SDKs) para facilitar el funcionamiento de la aplicación, recordar sus preferencias, realizar análisis y mejorar la seguridad.

**8. PRIVACIDAD DE MENORES DE EDAD**

Nuestra Aplicación no está dirigida a personas menores de 18 años. No recopilamos intencionadamente información personal de menores de 18 años. Si usted es padre o tutor y cree que su hijo nos ha proporcionado información personal sin su consentimiento, por favor contáctenos.   

**9. CAMBIOS A ESTA POLÍTICA DE PRIVACIDAD**

Podemos actualizar esta Política de Privacidad de vez en cuando. Le notificaremos cualquier cambio publicando la nueva Política de Privacidad en esta página y actualizando la "Fecha de Última Actualización" en la parte superior.

**10. CONTACTO**

Si tiene preguntas o comentarios sobre esta Política de Privacidad, por favor contáctenos en: 
Appcerragas@gmail.com

**11. LEY APLICABLE**

Esta Política de Privacidad se rige e interpreta de acuerdo con las leyes de la República de Chile.
""";
  // FIN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: Colors.blueAccent, // O el color de tu AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          textoPoliticaPrivacidad,
          style: const TextStyle(fontSize: 15, height: 1.5), // Estilo para legibilidad
        ),
      ),
    );
  }
}