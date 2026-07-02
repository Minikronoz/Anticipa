import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../theme/app_theme.dart';

class RecompensasScreen extends StatefulWidget {
  final int idEstudiante;
  final String nombreEstudiante;
  final ThemeConfig themeConfig;

  const RecompensasScreen({
    super.key,
    required this.idEstudiante,
    required this.nombreEstudiante,
    required this.themeConfig,
  });

  @override
  State<RecompensasScreen> createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends State<RecompensasScreen> {
  bool isLoading = true;
  String error = '';
  int estrellas = 0;
  List<Map<String, dynamic>> recompensas = [];
  final Set<int> recompensasCanjeadas = {};

  ThemeColors get _c => widget.themeConfig.colors;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final resEstrellas = await http
          .get(Uri.parse('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}'))
          .timeout(const Duration(seconds: 60));
      final resRecompensas = await http
          .get(Uri.parse('${AppConstants.baseUrl}/recompensas/estudiante/${widget.idEstudiante}'))
          .timeout(const Duration(seconds: 60));

      if (resEstrellas.statusCode == 200 && resRecompensas.statusCode == 200) {
        final dataEstrellas = List<Map<String, dynamic>>.from(jsonDecode(resEstrellas.body));
        final total = dataEstrellas.fold<int>(0, (sum, e) => sum + ((e['estrellas_ganadas'] ?? 0) as int));

        final dataRecompensas = List<Map<String, dynamic>>.from(jsonDecode(resRecompensas.body));

        setState(() {
          estrellas = total;
          recompensas = dataRecompensas;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'No se pudieron cargar los datos.';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        error = 'Error de conexión.';
        isLoading = false;
      });
    }
  }

  Future<void> _canjear(int idRecompensa, String nombre, int meta) async {
    try {
      final r = await http
          .post(Uri.parse('${AppConstants.baseUrl}/recompensas/$idRecompensa/canjear'))
          .timeout(const Duration(seconds: 60));

      if (r.statusCode == 200) {
        setState(() {
          recompensasCanjeadas.add(idRecompensa);
        });
        await _cargarTodo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Recompensa "$nombre" canjeada!'), backgroundColor: Colors.green),
          );
        }
      } else if (r.statusCode == 400) {
        final body = jsonDecode(r.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['detail'] ?? 'No se pudo canjear'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al canjear recompensa'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarCanje(int id, String nombre, int meta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Canjear recompensa'),
        content: Text('¿Canjeas "$nombre" por $meta ⭐?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _canjear(id, nombre, meta);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  IconData _iconoPorNombre(String? nombre) {
    if (nombre == null) return Icons.card_giftcard;
    final n = nombre.toLowerCase();
    if (n.contains('juego') || n.contains('game')) return Icons.sports_esports;
    if (n.contains('actividad') || n.contains('favorita')) return Icons.palette;
    if (n.contains('medalla') || n.contains('logro')) return Icons.emoji_events;
    if (n.contains('comida') || n.contains('almuerzo')) return Icons.restaurant;
    if (n.contains('salida') || n.contains('paseo')) return Icons.park;
    if (n.contains('pelicula') || n.contains('cine')) return Icons.movie;
    if (n.contains('deber') || n.contains('libre')) return Icons.check_circle;
    return Icons.card_giftcard;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _c.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _c.background,
      body: SafeArea(
        child: Column(children: [
          _barraSuperior(),
          Expanded(
            child: error.isNotEmpty
                ? Center(child: Text(error, style: TextStyle(color: Colors.red.shade700, fontSize: 16)))
                : _listaRecompensas(),
          ),
        ]),
      ),
    );
  }

  Widget _barraSuperior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: _c.appBar,
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.card_giftcard, size: 28, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¡Hola ${widget.nombreEstudiante}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Tus recompensas', style: TextStyle(fontSize: 13, color: Colors.white70)),
        ])),
        Column(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 4),
            Text('$estrellas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          const Text('estrellas', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ]),
    );
  }

  Widget _listaRecompensas() {
    if (recompensas.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.card_giftcard, size: 80, color: _c.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Sin recompensas aún', style: TextStyle(fontSize: 20, color: _c.textSecondary)),
          const SizedBox(height: 8),
          Text('Tu apoderado creará\nrecompensas para ti', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _c.textSecondary)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarTodo,
      color: _c.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: recompensas.length,
        itemBuilder: (ctx, i) => _cardRecompensa(recompensas[i]),
      ),
    );
  }

  Widget _cardRecompensa(Map<String, dynamic> r) {
    final id = r['id_recompensa'] as int;
    final nombre = r['nombre_recompensa'] as String? ?? 'Recompensa';
    final meta = r['meta_estrellas'] as int? ?? 0;
    final canjeada = (r['estado_logro'] == true) || recompensasCanjeadas.contains(id);
    final disponible = estrellas >= meta && !canjeada;
    final faltan = meta - estrellas;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: canjeada
            ? Colors.grey.shade100
            : disponible
                ? const Color(0xFFF0FDF4)
                : _c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canjeada
              ? Colors.grey.shade400
              : disponible
                  ? const Color(0xFF22C55E)
                  : _c.primary.withValues(alpha: 0.2),
          width: canjeada ? 1 : 2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: canjeada
                  ? Colors.grey.shade300
                  : disponible
                      ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                      : _c.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _iconoPorNombre(nombre),
              size: 32,
              color: canjeada ? Colors.grey : (disponible ? const Color(0xFF22C55E) : _c.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              nombre,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: canjeada ? Colors.grey : _c.textPrimary,
                decoration: canjeada ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$meta estrellas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: canjeada ? Colors.grey : (disponible ? const Color(0xFF22C55E) : _c.primary)),
              ),
            ]),
            if (!canjeada && !disponible) ...[
              const SizedBox(height: 2),
              Text('Necesitas $faltan estrellas más', style: TextStyle(fontSize: 12, color: _c.textSecondary)),
            ],
            if (canjeada) ...[
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.check_circle, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Canjeada', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ]),
            ],
          ])),
          if (!canjeada && disponible)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmarCanje(id, nombre, meta),
              child: const Text('Canjear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            )
          else if (!canjeada)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Bloqueada', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }
}

// En esta vista  se implementó la pantalla de recompensas para el estudiante, la cual permite visualizar
// las estrellas acumuladas y las recompensas disponibles mediante el consumo de datos desde la API.
// Además, se desarrolló la funcionalidad de canje de recompensas a través de solicitudes HTTP al backend, incorporando
// una ventana de confirmación antes de realizar el canje para evitar acciones accidentales. 
//Tras un canje exitoso, la información se actualiza automáticamente para reflejar el nuevo estado de las estrellas y las recompensas.
// También se añadió el manejo de estados de carga, errores de conexión y mensajes informativos mediante SnackBar,
// junto con una interfaz dinámica que diferencia visualmente las recompensas disponibles, bloqueadas y canjeadas,
// asignando además iconos representativos según el tipo de recompensa para mejorar la experiencia del usuario.

// Como resultado, se obtuvo un módulo de recompensas completamente funcional e integrado con el backend,
// permitiendo que los estudiantes visualicen sus estrellas acumuladas,
// consulten las recompensas disponibles y realicen canjes de forma segura. 
//La implementación mejora la experiencia del usuario mediante una interfaz intuitiva,
// actualización automática de la información y un manejo adecuado de errores, garantizando 
//un funcionamiento confiable y una interacción fluida con el sistema.

