import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class RecompensasScreen extends StatefulWidget {
  final int idEstudiante;
  final String nombreEstudiante;

  const RecompensasScreen({
    super.key,
    required this.idEstudiante,
    required this.nombreEstudiante,
  });

  @override
  State<RecompensasScreen> createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends State<RecompensasScreen> {
  bool isLoading = true;
  String error = '';
  int estrellas = 0;

  final List<Map<String, dynamic>> recompensas = [
    {
      'id': 1,
      'nombre': '5 minutos de juego educativo',
      'meta': 20,
      'icono': Icons.sports_esports,
    },
    {
      'id': 2,
      'nombre': 'Elegir actividad favorita',
      'meta': 40,
      'icono': Icons.palette,
    },
    {
      'id': 3,
      'nombre': 'Medalla virtual de logro',
      'meta': 60,
      'icono': Icons.emoji_events,
    },
  ];

  final Set<int> recompensasCanjeadas = {};

  @override
  void initState() {
    super.initState();
    _cargarEstrellas();
  }

  Future<void> _cargarEstrellas() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final r = await http
          .get(Uri.parse('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}'))
          .timeout(const Duration(seconds: 60));

      if (r.statusCode != 200) {
        setState(() {
          estrellas = 0;
          error = 'No se pudieron cargar las estrellas.';
          isLoading = false;
        });
        return;
      }

      final data = List<Map<String, dynamic>>.from(jsonDecode(r.body));

      final total = data.fold<int>(
        0,
        (sum, e) => sum + ((e['estrellas_ganadas'] ?? 0) as int),
      );

      setState(() {
        estrellas = total;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        error = 'Error de conexión al cargar estrellas.';
        isLoading = false;
      });
    }
  }

  void _confirmarCanje(Map<String, dynamic> recompensa) {
    final int id = recompensa['id'];
    final String nombre = recompensa['nombre'];
    final int meta = recompensa['meta'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Canjear recompensa'),
        content: Text('¿Deseas canjear "$nombre" por $meta estrellas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);

              setState(() {
                recompensasCanjeadas.add(id);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recompensa canjeada: $nombre'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recompensas'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstrellas,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  widget.nombreEstudiante,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Estrellas disponibles: $estrellas ⭐'),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Recompensas disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (error.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

            ...recompensas.map((r) {
              final int id = r['id'];
              final String nombre = r['nombre'];
              final int meta = r['meta'];
              final IconData icono = r['icono'];

              final bool canjeada = recompensasCanjeadas.contains(id);
              final bool disponible = estrellas >= meta && !canjeada;
              final int faltan = meta - estrellas;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        child: Icon(icono, size: 30),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canjeada
                                  ? 'Recompensa ya canjeada'
                                  : disponible
                                      ? 'Disponible por $meta ⭐'
                                      : 'Meta: $meta ⭐ · Faltan $faltan ⭐',
                            ),
                          ],
                        ),
                      ),

                      if (canjeada)
                        const Chip(label: Text('Canjeada'))
                      else if (disponible)
                        ElevatedButton(
                          onPressed: () => _confirmarCanje(r),
                          child: const Text('Canjear'),
                        )
                      else
                        const Chip(label: Text('Bloqueada')),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}