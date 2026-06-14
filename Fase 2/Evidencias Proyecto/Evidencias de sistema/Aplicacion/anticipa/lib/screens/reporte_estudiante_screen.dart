import 'package:flutter/material.dart';

class ReporteEstudianteScreen extends StatelessWidget {
  final int idEstudiante;
  final String nombreEstudiante;

  const ReporteEstudianteScreen({
    super.key,
    required this.idEstudiante,
    required this.nombreEstudiante,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte del estudiante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Encabezado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreEstudiante,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Resumen semanal'),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Métricas generales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    '23',
                    'Actividades',
                    Icons.assignment,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    '15',
                    'Completadas',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    '8',
                    'Pendientes',
                    Icons.pending,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    '12',
                    'Estrellas',
                    Icons.star,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Categorías',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Icon(Icons.school),
                title: Text('Educación'),
                subtitle: Text('8 actividades completadas'),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(Icons.clean_hands),
                title: Text('Higiene'),
                subtitle: Text('4 pendientes'),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(Icons.restaurant),
                title: Text('Alimentación'),
                subtitle: Text('6 completadas'),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Observación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'El estudiante presenta mayor dificultad en actividades relacionadas con higiene. Se recomienda reforzar estas rutinas durante la semana.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _metricCard(
    String valor,
    String titulo,
    IconData icono,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, size: 35),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}