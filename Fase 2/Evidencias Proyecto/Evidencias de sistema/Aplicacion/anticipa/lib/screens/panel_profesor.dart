import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final String apiUrl = 'http://127.0.0.1:8000';

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
      final cursosResponse = await http.get(Uri.parse('$apiUrl/cursos/'));
      final estudiantesResponse = await http.get(
        Uri.parse('$apiUrl/estudiantes/usuario/${widget.idUsuarioProfesor}'),
      );

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
              );

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
      height: 190,
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
      child: Column(
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