import 'package:flutter/material.dart';

class PanelProfesor extends StatelessWidget {
  const PanelProfesor({super.key});

  final List<Map<String, dynamic>> cursos = const [
    {
      'nombre': '1° Básico A',
      'alumnos': [
        {'nombre': 'Mateo', 'puntos': 45, 'emoji': ''},
        {'nombre': 'Sofía', 'puntos': 52, 'emoji': ''},
      ],
    },
    {
      'nombre': '1° Básico B',
      'alumnos': [
        {'nombre': 'Lucas', 'puntos': 38, 'emoji': ''},
        {'nombre': 'Valentina', 'puntos': 60, 'emoji': ''},
      ],
    },
    {
      'nombre': '2° Básico A',
      'alumnos': [
        {'nombre': 'Diego', 'puntos': 41, 'emoji': ''},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        title: const Text('Panel Profesor'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
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
            'Organiza tus alumnos por curso y gestiona sus calendarios de actividades.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 35),

          for (final curso in cursos) _cursoSection(context, curso),
        ],
      ),
    );
  }

  Widget _cursoSection(BuildContext context, Map<String, dynamic> curso) {
    final alumnos = curso['alumnos'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: Color(0xFF4F46E5), size: 28),
            const SizedBox(width: 8),
            Text(
              curso['nombre'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF061A40),
              ),
            ),
            const Spacer(),
            Text(
              '${alumnos.length} alumnos',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: alumnos.map((alumno) {
            return _alumnoCard(context, alumno);
          }).toList(),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _alumnoCard(BuildContext context, Map<String, dynamic> alumno) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seleccionaste a ${alumno['nombre']}'),
          ),
        );
      },
      child: Container(
        width: 270,
        height: 170,
        padding: const EdgeInsets.all(18),
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
              style: const TextStyle(fontSize: 46),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFFEAB308), size: 22),
                const SizedBox(width: 5),
                Text(
                  '${alumno['puntos']}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFEAB308),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}