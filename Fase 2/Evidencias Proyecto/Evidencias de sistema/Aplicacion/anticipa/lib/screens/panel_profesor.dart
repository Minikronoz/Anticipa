import 'package:flutter/material.dart';

class PanelProfesor extends StatefulWidget {
  const PanelProfesor({super.key});

  @override
  State<PanelProfesor> createState() => _PanelProfesorState();
}

class _PanelProfesorState extends State<PanelProfesor> {
  List<Map<String, dynamic>> cursos = [
    {
      'nombre': '1° Básico A',
      'alumnos': [
        {'nombre': 'Mateo', 'puntos': 45, 'emoji': '👦'},
        {'nombre': 'Sofía', 'puntos': 52, 'emoji': '👧'},
      ],
    },
    {
      'nombre': '1° Básico B',
      'alumnos': [
        {'nombre': 'Lucas', 'puntos': 38, 'emoji': '👦'},
        {'nombre': 'Valentina', 'puntos': 60, 'emoji': '👧'},
      ],
    },
    {
      'nombre': '2° Básico A',
      'alumnos': [
        {'nombre': 'Diego', 'puntos': 41, 'emoji': '👦'},
      ],
    },
  ];

  void mostrarAgregarAlumno() {
    final nombreController = TextEditingController();
    String cursoSeleccionado = cursos.first['nombre'];
    String emojiSeleccionado = '👦';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar alumno'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre alumno',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: cursoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Curso',
                      border: OutlineInputBorder(),
                    ),
                    items: cursos.map((curso) {
                      return DropdownMenuItem<String>(
                        value: curso['nombre'],
                        child: Text(curso['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        cursoSeleccionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: emojiSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Icono',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '👦', child: Text('👦 Niño')),
                      DropdownMenuItem(value: '👧', child: Text('👧 Niña')),
                      DropdownMenuItem(value: '🧒', child: Text('🧒 Estudiante')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        emojiSeleccionado = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nombreController.text.trim().isEmpty) return;

                    setState(() {
                      final curso = cursos.firstWhere(
                        (c) => c['nombre'] == cursoSeleccionado,
                      );

                      (curso['alumnos'] as List).add({
                        'nombre': nombreController.text.trim(),
                        'puntos': 0,
                        'emoji': emojiSeleccionado,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Mis cursos y alumnos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF061A40),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Organiza tus alumnos por curso y gestiona actividades.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 35),
          for (final curso in cursos) _cursoSection(curso),
          _agregarAlumnoButton(),
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

  Widget _cursoSection(Map<String, dynamic> curso) {
    final alumnos = curso['alumnos'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF4F46E5)),
            const SizedBox(width: 10),
            Text(
              curso['nombre'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF061A40),
              ),
            ),
            const Spacer(),
            Text('${alumnos.length} alumnos'),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: alumnos.map((alumno) {
            return _alumnoCard(alumno);
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _alumnoCard(Map<String, dynamic> alumno) {
    return Container(
      width: 270,
      height: 170,
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
            alumno['emoji'],
            style: const TextStyle(fontSize: 42),
          ),
          const SizedBox(height: 8),
          Text(
            alumno['nombre'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF061A40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '⭐ ${alumno['puntos']}',
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

  Widget _agregarAlumnoButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: mostrarAgregarAlumno,
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
              Icons.add,
              size: 50,
              color: Color(0xFF4F46E5),
            ),
            SizedBox(height: 10),
            Text(
              'Agregar alumno',
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