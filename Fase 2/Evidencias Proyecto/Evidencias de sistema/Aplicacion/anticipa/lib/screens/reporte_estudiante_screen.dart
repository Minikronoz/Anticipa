import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ReporteEstudianteScreen extends StatefulWidget {
  final int idEstudiante;
  final String nombreEstudiante;

  const ReporteEstudianteScreen({
    super.key,
    required this.idEstudiante,
    required this.nombreEstudiante,
  });

  @override
  State<ReporteEstudianteScreen> createState() => _ReporteEstudianteScreenState();
}

class _ReporteEstudianteScreenState extends State<ReporteEstudianteScreen> {
  List<Map<String, dynamic>> actividades = [];
  List<Map<String, dynamic>> pictogramas = [];
  int estrellas = 0;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarReporte();
  }

  Future<void> cargarReporte() async {
    try {
      final resActividades = await http.get(
        Uri.parse('${AppConstants.baseUrl}/actividades/estudiante/${widget.idEstudiante}'),
      );

      final resPictogramas = await http.get(
        Uri.parse('${AppConstants.baseUrl}/pictogramas/'),
      );

      final resEstrellas = await http.get(
        Uri.parse('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}'),
      );

      if (resActividades.statusCode == 200) {
        actividades = List<Map<String, dynamic>>.from(jsonDecode(resActividades.body));
      }

      if (resPictogramas.statusCode == 200) {
        pictogramas = List<Map<String, dynamic>>.from(jsonDecode(resPictogramas.body));
      }

      if (resEstrellas.statusCode == 200) {
        final listaEstrellas = List<Map<String, dynamic>>.from(jsonDecode(resEstrellas.body));
        estrellas = listaEstrellas.fold<int>(
          0,
          (total, item) => total + ((item['estrellas_ganadas'] ?? 0) as int),
        );
      }

      setState(() => cargando = false);
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  int get totalActividades => actividades.length;

  int get completadas =>
      actividades.where((a) => a['es_completada'] == true).length;

  int get pendientes => totalActividades - completadas;

  double get porcentaje =>
      totalActividades == 0 ? 0 : (completadas / totalActividades) * 100;

  String categoriaActividad(Map<String, dynamic> actividad) {
    final idPicto = actividad['pictograma_id_pictograma'];

    final picto = pictogramas.firstWhere(
      (p) => p['id_pictograma'] == idPicto,
      orElse: () => {},
    );

    return picto['categoria']?.toString() ?? 'Sin categoría';
  }

  Map<String, int> categoriasPendientes() {
    final Map<String, int> conteo = {};

    for (final actividad in actividades) {
      if (actividad['es_completada'] == true) continue;

      final categoria = categoriaActividad(actividad);
      conteo[categoria] = (conteo[categoria] ?? 0) + 1;
    }

    return conteo;
  }

  String observacionAutomatica() {
    if (totalActividades == 0) {
      return 'El estudiante no tiene actividades registradas.';
    }

    if (porcentaje >= 80) {
      return 'El estudiante presenta un buen nivel de cumplimiento en sus actividades.';
    }

    final pendientesPorCategoria = categoriasPendientes();

    if (pendientesPorCategoria.isEmpty) {
      return 'El estudiante completó todas sus actividades registradas.';
    }

    final categoriaDificultad = pendientesPorCategoria.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return 'El estudiante presenta mayor dificultad en actividades relacionadas con $categoriaDificultad. Se recomienda reforzar esta categoría.';
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      appBar: AppBar(
        title: const Text('Reporte del estudiante'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nombreEstudiante,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF061A40),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Métricas generales',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _metricCard('$totalActividades', 'Actividades', Icons.assignment)),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('$completadas', 'Completadas', Icons.check_circle)),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _metricCard('$pendientes', 'Pendientes', Icons.pending)),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('$estrellas', 'Estrellas', Icons.star)),
              ],
            ),

            const SizedBox(height: 20),

            _metricCard(
              '${porcentaje.toStringAsFixed(1)}%',
              'Cumplimiento total',
              Icons.bar_chart,
            ),

            const SizedBox(height: 25),

            const Text(
              'Categorías con pendientes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (categoriasPendientes().isEmpty)
              const Card(
                child: ListTile(
                  title: Text('Sin pendientes'),
                  subtitle: Text('El estudiante no tiene actividades pendientes.'),
                ),
              )
            else
              ...categoriasPendientes().entries.map(
                (e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(e.key),
                    subtitle: Text('${e.value} actividades pendientes'),
                  ),
                ),
              ),

            const SizedBox(height: 25),

            const Text(
              'Observación',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  observacionAutomatica(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _metricCard(String valor, String titulo, IconData icono) {
    return Card(
      color: const Color(0xFFDFF1FF),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icono, size: 34, color: Color(0xFF0F4EA8)),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4EA8),
              ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}

//En este commit se implementó la pantalla de reporte del estudiante,
// la cual permite visualizar métricas generales relacionadas con sus actividades, pictogramas y estrellas acumuladas.
// El código consume información desde la API para obtener las actividades asignadas, 
//los pictogramas registrados y las estrellas ganadas por el estudiante. A partir de estos datos,
// se calculan automáticamente indicadores como el total de actividades, 
//actividades completadas, pendientes, porcentaje de cumplimiento y categorías con mayor cantidad de tareas pendientes.
// Además, se incorporó una observación automática que entrega una interpretación del
// desempeño del estudiante, permitiendo identificar si mantiene un buen nivel de
// cumplimiento o si necesita refuerzo en una categoría específica.
