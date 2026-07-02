import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'panel_detalle_estudiante.dart';

class PanelProfesor extends StatefulWidget {
  final int idUsuarioProfesor;

  const PanelProfesor({
    super.key,
    required this.idUsuarioProfesor,
  });

  @override
  State<PanelProfesor> createState() => _PanelProfesorState();
}

class _PanelProfesorState extends State<PanelProfesor> {
  final String apiUrl = AppConstants.baseUrl;

  List<dynamic> estudiantes = [];
  List<dynamic> cursos = [];
  bool cargando = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final cursosResponse = await http.get(Uri.parse('$apiUrl/cursos/')).timeout(const Duration(seconds: 60));
      final estudiantesResponse = await http.get(
        Uri.parse('$apiUrl/estudiantes/usuario/${widget.idUsuarioProfesor}'),
      ).timeout(const Duration(seconds: 60));

      if (cursosResponse.statusCode == 200 &&
          estudiantesResponse.statusCode == 200) {
        setState(() {
          cursos = jsonDecode(cursosResponse.body);
          estudiantes = jsonDecode(estudiantesResponse.body);
          cargando = false;
        });
      } else {
        setState(() {
          error = 'No se pudieron cargar los datos.';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error de conexión con la API.';
        cargando = false;
      });
    }
  }

  Future<void> vincularPorCodigo() async {
    final codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vincular estudiante'),
        content: TextField(
          controller: codigoController,
          decoration: const InputDecoration(
            labelText: 'Código de vinculación',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final codigo = codigoController.text.trim();

              if (codigo.isEmpty) return;

              final response = await http.post(
                Uri.parse(
                  '$apiUrl/vinculaciones/codigo/$codigo?id_usuario=${widget.idUsuarioProfesor}&rol_id_rol=2',
                ),
              ).timeout(const Duration(seconds: 60));

              Navigator.pop(context);

              if (response.statusCode == 201) {
                await cargarDatos();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Estudiante vinculado correctamente.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código inválido o estudiante ya vinculado.'),
                  ),
                );
              }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  String obtenerNombreCurso(dynamic estudiante) {
    final idCurso = estudiante['curso_id_curso'];

    final curso = cursos.firstWhere(
      (c) => c['id_curso'] == idCurso,
      orElse: () => null,
    );

    if (curso == null) return 'Sin curso';

    final nivel = curso['nivel_academico'] ?? '';
    final letra = curso['letra_academica'] ?? '';

    return '$nivel $letra'.trim();
  }

  String obtenerEmoji(dynamic estudiante) {
    final nombre = estudiante['nombre'].toString().toLowerCase();

    if (nombre.endsWith('a')) {
      return '👧';
    }

    return '👦';
  }

  void cerrarSesion() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  void abrirDetalleEstudiante(dynamic estudiante) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PanelDetalleEstudiante(
          idEstudiante: estudiante['id_estudiante'],
          idUsuario: widget.idUsuarioProfesor,
          rol: 'Profesor',
          nombreEstudiante: estudiante['nombre'] ?? 'Estudiante',
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoGestionTutores(dynamic estudiante) async {
    final codigoController = TextEditingController();
    List<dynamic> tutores = [];
    bool cargandoTutores = true;
    String? errorTutores;
    bool primeraVez = true;

    Future<void> cargarTutores(StateSetter setDlg) async {
      setDlg(() { cargandoTutores = true; errorTutores = null; });
      try {
        final r = await http.get(
          Uri.parse('$apiUrl/vinculaciones/estudiante/${estudiante['id_estudiante']}'),
        ).timeout(const Duration(seconds: 60));
        if (r.statusCode == 200) {
          setDlg(() {
            tutores = jsonDecode(r.body);
            cargandoTutores = false;
          });
        } else {
          setDlg(() {
            errorTutores = 'Error al cargar tutores';
            cargandoTutores = false;
          });
        }
      } catch (e) {
        setDlg(() {
          errorTutores = 'Error de conexión';
          cargandoTutores = false;
        });
      }
    }

    Future<void> vincularTutor(StateSetter setDlg) async {
      final codigo = codigoController.text.trim();
      if (codigo.isEmpty) return;
      try {
        final r = await http.post(
          Uri.parse('$apiUrl/vinculaciones/profesor'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'codigo_tutor': codigo,
            'id_estudiante': estudiante['id_estudiante'],
            'id_usuario_profesor': widget.idUsuarioProfesor,
          }),
        ).timeout(const Duration(seconds: 60));
        if (r.statusCode == 201) {
          codigoController.clear();
          await cargarTutores(setDlg);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tutor vinculado correctamente.')),
            );
          }
        } else {
          String msg = 'Error al vincular tutor';
          try {
            final data = jsonDecode(r.body);
            msg = data['detail'] ?? msg;
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red),
          );
        }
      }
    }

    Future<void> desvincularTutor(int idVinculo, StateSetter setDlg) async {
      final motivoController = TextEditingController();
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Desvincular tutor'),
          content: TextField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: 'Motivo de desvinculación',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desvincular'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;

      try {
        final motivo = Uri.encodeComponent(motivoController.text.trim());
        final r = await http.patch(
          Uri.parse('$apiUrl/vinculaciones/$idVinculo/desvincular?id_usuario=${widget.idUsuarioProfesor}&motivo=$motivo'),
        ).timeout(const Duration(seconds: 60));
        if (r.statusCode == 200) {
          await cargarTutores(setDlg);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tutor desvinculado correctamente.')),
            );
          }
        } else {
          String msg = 'Error al desvincular tutor';
          try {
            final data = jsonDecode(r.body);
            msg = data['detail'] ?? msg;
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red),
          );
        }
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          if (primeraVez) {
            primeraVez = false;
            cargarTutores(setDlg);
          }
          return AlertDialog(
            title: Text('Gestionar tutores - ${estudiante['nombre'] ?? 'Estudiante'}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cargandoTutores)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (errorTutores != null)
                      Text(errorTutores!, style: const TextStyle(color: Colors.red))
                    else if (tutores.where((t) => t['rol_id_rol'] == 3).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('No hay tutores vinculados.'),
                      )
                    else
                      ...tutores.where((t) => t['rol_id_rol'] == 3).map((t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t['nombre_tutor'] ?? 'Tutor'),
                        subtitle: const Text('Tutor'),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off, color: Colors.red),
                          tooltip: 'Desvincular',
                          onPressed: () => desvincularTutor(t['id_vinculo'], setDlg),
                        ),
                      )),
                    const Divider(),
                    TextField(
                      controller: codigoController,
                      decoration: const InputDecoration(
                        labelText: 'Código del tutor (T-XXX)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => vincularTutor(setDlg),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Vincular tutor'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  abrirDetalleEstudiante(estudiante);
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Ver calendario'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        title: const Text('Panel Profesor'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Mis estudiantes vinculados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF061A40),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ingresa un código de vinculación del estudiante',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 35),
                    if (estudiantes.isEmpty)
                      const Center(
                        child: Text(
                          'Aún no tienes estudiantes vinculados.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: estudiantes.map((estudiante) {
                        return _estudianteCard(estudiante);
                      }).toList(),
                    ),
                    const SizedBox(height: 35),
                    _vincularEstudianteButton(),
                    const SizedBox(height: 25),
                    const Center(
                      child: Text(
                        '🛡 Uso pedagógico autorizado — Ley 21.545',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _estudianteCard(dynamic estudiante) {
    return Container(
      width: 270,
      height: 245,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                obtenerEmoji(estudiante),
                style: const TextStyle(fontSize: 42),
              ),
              const SizedBox(height: 8),
              Text(
                estudiante['nombre'] ?? 'Sin nombre',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF061A40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                obtenerNombreCurso(estudiante),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⭐ ${estudiante['puntos_totales'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFEAB308),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => abrirDetalleEstudiante(estudiante),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Ver calendario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _mostrarDialogoGestionTutores(estudiante),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vincularEstudianteButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: vincularPorCodigo,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link,
              size: 50,
              color: Color(0xFF4F46E5),
            ),
            SizedBox(height: 10),
            Text(
              'Vincular estudiante con código',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF061A40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// La vista Panel Profesor permite al docente visualizar 
//y gestionar los estudiantes que tiene vinculados dentro de la plataforma. 
//Esta pantalla consume información desde la API para cargar los cursos
// y los estudiantes asociados al profesor, mostrando datos como el nombre, 
//curso y estrellas acumuladas de cada estudiante. Además, incorpora la funcionalidad
// de vinculación mediante un código ingresado por el profesor,
// actualizando automáticamente la información cuando el proceso es exitoso.
// La vista también permite acceder al calendario y detalle individual de cada estudiante, 
//e incluye manejo de estados de carga, errores de conexión y una interfaz diseñada para facilitar
// la administración y seguimiento de los alumnos.

// Como resultado, se obtuvo una vista funcional para la gestión de estudiantes por parte del profesor,
// centralizando el acceso a la información de sus alumnos y facilitando tanto la vinculación mediante 
//códigos como la navegación hacia el detalle de cada estudiante. Esto mejora la organización 
//del trabajo docente y permite un seguimiento más eficiente dentro del sistema Anticipa.

