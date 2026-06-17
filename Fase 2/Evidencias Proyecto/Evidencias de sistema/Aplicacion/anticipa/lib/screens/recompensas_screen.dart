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
  List<Map<String, dynamic>> recompensas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final res = await Future.wait([
        _fetchEstrellas(),
        _fetchRecompensas(),
      ]);

      setState(() {
        estrellas = res[0] as int;
        recompensas = res[1] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error al cargar recompensas';
        isLoading = false;
      });
    }
  }

  Future<int> _fetchEstrellas() async {
    final r = await http
        .get(Uri.parse('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}'))
        .timeout(const Duration(seconds: 60));

    if (r.statusCode != 200) return 0;

    final data = List<Map<String, dynamic>>.from(jsonDecode(r.body));

    return data.fold<int>(
      0,
      (sum, e) => sum + ((e['estrellas_ganadas'] ?? 0) as int),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecompensas() async {
    final r = await http
        .get(Uri.parse('${AppConstants.baseUrl}/recompensas/estudiante/${widget.idEstudiante}'))
        .timeout(const Duration(seconds: 60));

    if (r.statusCode != 200) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(r.body));
  }

  void _canjear(Map<String, dynamic> recompensa) {
    final nombre = recompensa['nombre_recompensa'] ?? 'Recompensa';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Canjear recompensa'),
        content: Text('¿Deseas canjear "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Recompensa asignada: $nombre')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  IconData _iconoRecompensa(String nombre) {
    final n = nombre.toLowerCase();

    if (n.contains('juego')) return Icons.sports_esports;
    if (n.contains('actividad')) return Icons.palette;
    if (n.contains('medalla')) return Icons.emoji_events;
    if (n.contains('descanso')) return Icons.self_improvement;
    if (n.contains('cuento')) return Icons.menu_book;

    return Icons.card_giftcard;
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
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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

            if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),

            if (recompensas.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay recompensas registradas para este estudiante.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...recompensas.map((r) {
                final nombre = r['nombre_recompensa']?.toString() ?? 'Sin nombre';
                final meta = r['meta_estrellas'] ?? 0;
                final lograda = r['estado_logro'] == true;
                final disponible = estrellas >= meta && !lograda;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _iconoRecompensa(nombre),
                      size: 34,
                    ),
                    title: Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lograda
                          ? 'Recompensa ya canjeada'
                          : 'Meta: $meta ⭐',
                    ),
                    trailing: lograda
                        ? const Chip(label: Text('Canjeada'))
                        : disponible
                            ? ElevatedButton(
                                onPressed: () => _canjear(r),
                                child: const Text('Canjear'),
                              )
                            : const Chip(label: Text('Bloqueada')),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}