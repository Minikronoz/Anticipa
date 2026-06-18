import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_theme.dart';
import 'theme_settings_screen.dart';

// ═══════════════════════════════════════════════════════════
// PANEL ESTUDIANTE — Modo kiosko simplificado
// Solo actividades de HOY, completar con ⭐, tira de días
// ═══════════════════════════════════════════════════════════
class PanelEstudiante extends StatefulWidget {
  final int idEstudiante;
  final int idUsuario;
  final String rol;
  final String nombreEstudiante;
  final ThemeConfig themeConfig;
  final Function(ThemeConfig) onThemeChanged;

  const PanelEstudiante({
    super.key,
    required this.idEstudiante,
    required this.idUsuario,
    required this.rol,
    required this.nombreEstudiante,
    required this.themeConfig,
    required this.onThemeChanged,
  });

  @override
  State<PanelEstudiante> createState() => _PanelEstudianteState();
}

class _PanelEstudianteState extends State<PanelEstudiante> {
  // ── Estado ──────────────────────────────────────────────
  List<Map<String, dynamic>> _actividades = [];
  List<Map<String, dynamic>> _pictogramas = [];
  int _estrellas = 0;
  bool _cargando = true;
  final Set<int> _completandoIds = {};
  DateTime _fechaSeleccionada = DateTime.now();

  ThemeColors get _c => widget.themeConfig.colors;

  String get _fechaFormateada => _fechaSeleccionada.toIso8601String().split('T')[0];

  static const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _diasLargos = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  // ── Carga de datos desde API ────────────────────────────
  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final res = await Future.wait([
        _get('${AppConstants.baseUrl}/actividades/estudiante/${widget.idEstudiante}?fecha=$_fechaFormateada'),
        _get('${AppConstants.baseUrl}/pictogramas/'),
        _get('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}'),
      ]);
      setState(() {
        _actividades = res[0];
        _pictogramas = res[1];
        _estrellas = _totalEstrellas(res[2]);
        _cargando = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos'), backgroundColor: Colors.red));
      setState(() => _cargando = false);
    }
  }

  Future<List<Map<String, dynamic>>> _get(String url) async {
    final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    return r.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(r.body)) : [];
  }

  int _totalEstrellas(List<Map<String, dynamic>> data) {
    int total = 0;
    for (final e in data) {
      total += (e['estrellas_ganadas'] ?? 0) as int;
    }
    return total;
  }

  int get _completadas => _actividades.where((a) => a['es_completada'] == true).length;

  String? _pictoUrl(int? id) {
    if (id == null) return null;
    for (final p in _pictogramas) {
      if (p['id_pictograma'] == id) return p['url']?.toString();
    }
    return null;
  }

  // ── Helpers de fecha y pictogramas ──────────────────────
  String _fechaBonita() {
    final f = _fechaSeleccionada;
    return '${_diasLargos[f.weekday - 1]}, ${f.day} de ${_meses[f.month - 1]}';
  }

  String _fechaLabel(DateTime d) {
    final hoy = DateTime.now();
    final fmt = d.toIso8601String().split('T')[0];
    if (fmt == hoy.toIso8601String().split('T')[0]) return 'HOY';
    final manana = hoy.add(const Duration(days: 1));
    if (fmt == manana.toIso8601String().split('T')[0]) return 'Mañana';
    final ayer = hoy.subtract(const Duration(days: 1));
    if (fmt == ayer.toIso8601String().split('T')[0]) return 'Ayer';
    return '${_diasSemana[d.weekday - 1]} ${d.day}';
  }

  // ── Navegación entre días ───────────────────────────────
  List<DateTime> get _diasVisibles {
    final dias = <DateTime>[];
    for (int i = -3; i <= 3; i++) {
      dias.add(_fechaSeleccionada.add(Duration(days: i)));
    }
    return dias;
  }

  void _moverSemana(int direccion) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: 7 * direccion));
    });
    _cargarTodo();
  }

  void _seleccionarDia(DateTime d) {
    setState(() => _fechaSeleccionada = d);
    _cargarTodo();
  }

  // ── Completar / desmarcar actividad ─────────────────────
  Future<void> _completar(int id) async {
    setState(() => _completandoIds.add(id));
    try {
      final r = await http.patch(Uri.parse('${AppConstants.baseUrl}/actividades/$id/completar')).timeout(const Duration(seconds: 60));
      if (r.statusCode == 200) await _cargarTodo();
      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo completar'), backgroundColor: Colors.red));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al completar actividad'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _completandoIds.remove(id));
    }
  }

  // ── Construcción de UI ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _c.background,
      body: SafeArea(
        child: Column(children: [
          _barraSuperior(),
          _tiraDias(),
          Expanded(child: _actividades.isEmpty ? _vacio() : _listaActividades()),
          if (_actividades.isNotEmpty) _barraInferior(),
        ]),
      ),
    );
  }

  // Barra superior: saludo, fecha, estrellas totales, logout
  Widget _barraSuperior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      decoration: BoxDecoration(
        color: _c.appBar,
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.face, size: 36, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¡Hola ${widget.nombreEstudiante}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(_fechaBonita(), style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ])),
        Column(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 4),
            Text('$_estrellas', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          const Text('estrellas', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70, size: 22),
          tooltip: 'Cerrar sesión',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
        ),
        IconButton(
          icon: const Icon(Icons.palette, color: Colors.white70, size: 22),
          tooltip: 'Personalizar colores',
          onPressed: () async {
            final result = await Navigator.push<ThemeConfig>(
              context,
              MaterialPageRoute(
                builder: (context) => ThemeSettingsScreen(currentConfig: widget.themeConfig),
              ),
            );
            if (result != null && mounted) {
              widget.onThemeChanged(result);
            }
          },
        ),
      ]),
    );
  }

  Widget _vacio() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📭', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 16),
      Text('No hay actividades para este día', style: TextStyle(fontSize: 20, color: _c.textPrimary)),
      const SizedBox(height: 8),
      Text('Pídele a tu profesor o apoderado\nque te agregue actividades', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _c.textSecondary)),
    ]));
  }

  // Tira horizontal: navegación entre días (HOY, Mañana, etc.)
  Widget _tiraDias() {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final dias = _diasVisibles;

    return Container(
      color: _c.appBar,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 24),
          onPressed: () => _moverSemana(-1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: dias.map((d) {
              final df = d.toIso8601String().split('T')[0];
              final seleccionado = df == _fechaFormateada;
              final esHoy = df == hoy;

              return GestureDetector(
                onTap: () => _seleccionarDia(d),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: seleccionado ? Colors.white : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                    border: esHoy && !seleccionado ? Border.all(color: Colors.yellowAccent, width: 2) : null,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_fechaLabel(d), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: seleccionado ? _c.primary : Colors.white)),
                    const SizedBox(height: 2),
                    Text('${d.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: seleccionado ? _c.primary : Colors.white)),
                  ]),
                ),
              );
            }).toList()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
          onPressed: () => _moverSemana(1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
        ),
      ]),
    );
  }

  // ── Línea de tiempo: nodos conectados con indicadores de estado
  Widget _listaActividades() {
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
        itemCount: _actividades.length,
        itemBuilder: (_, i) => _nodoTimeline(_actividades[i], i, _actividades.length),
      ),
    );
  }

  Widget _nodoTimeline(Map<String, dynamic> a, int index, int total) {
    final idRaw = a['id_actividad'];
    if (idRaw == null) return const SizedBox.shrink();
    final id = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;
    if (id == 0) return const SizedBox.shrink();
    final completada = a['es_completada'] == true;
    final completando = _completandoIds.contains(id);

    bool _esActividadPasada(Map<String, dynamic> act) {
      final f = act['fecha_actividad'];
      if (f == null) return false;
      final fechaStr = f.toString().split('T')[0];
      final hoy = DateTime.now().toIso8601String().split('T')[0];
      return fechaStr.compareTo(hoy) < 0;
    }

    final esPasado = _esActividadPasada(a);
    final ahora = DateTime.now();
    final horaActual = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    final horaRaw = (a['hora_inicio']?.toString() ?? '');
    final horaFormateada = horaRaw.length >= 5 ? horaRaw.substring(0, 5) : '--:--';
    final fechaActStr = a['fecha_actividad']?.toString().split('T')[0] ?? '';
    final esFutura = !esPasado && fechaActStr.compareTo(DateTime.now().toIso8601String().split('T')[0]) > 0;
    final esFuturaMismoDia = !esPasado && !esFutura && horaFormateada.compareTo(horaActual) > 0;
    final picto = _pictoUrl(a['pictograma_id_pictograma']);
    final hora = horaFormateada;

    final esPrimero = index == 0;
    final esUltimo = index == total - 1;
    final anteriorCompletado = !esPrimero && _actividades[index - 1]['es_completada'] == true;
    final siguienteCompletado = !esUltimo && _actividades[index + 1]['es_completada'] == true;
    final colorLineaArriba = (completada && anteriorCompletado) ? const Color(0xFF22C55E) : Colors.grey.shade300;
    final colorLineaAbajo = (completada && siguienteCompletado) ? const Color(0xFF22C55E) : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!esPrimero)
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: Container(width: 4, color: colorLineaArriba),
                    ),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  margin: EdgeInsets.only(top: esPrimero ? 32 : 0),
                  decoration: BoxDecoration(
                    color: completada ? const Color(0xFF22C55E) : const Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  child: Align(
                    alignment: Alignment(0, 0.2),
                    child: completada
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : const Text('●', style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
                if (!esUltimo)
                  Expanded(
                    child: Center(
                      child: Container(width: 4, color: colorLineaAbajo),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: esPasado
                    ? Colors.grey.shade200
                    : completada
                        ? const Color(0xFFF0FDF4)
                        : _c.card,
                borderRadius: BorderRadius.circular(24),
                border: completada
                    ? Border.all(color: const Color(0xFF22C55E), width: 3)
                    : esPasado
                        ? Border.all(color: Colors.grey.shade400)
                        : Border.all(color: _c.primary.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Stack(children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Text(
                    (a['usuario_rol'] ?? '').toString().toLowerCase().contains('profesor')
                        ? '🎓'
                        : (a['usuario_rol'] ?? '').toString().toLowerCase().contains('apodera')
                            ? '👤'
                            : '👤',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Column(children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: _c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: picto != null
                          ? Image.network(picto, width: 56, height: 56, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('📌', style: TextStyle(fontSize: 40)))
                          : const Text('📌', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (esPasado)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(8)),
                      child: const Text('🔒 Día pasado', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      a['nombre_tarea'] ?? 'Actividad',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _c.textPrimary, decoration: completada ? TextDecoration.lineThrough : null),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.access_time, size: 16, color: _c.primary),
                    const SizedBox(width: 4),
                    Text(hora, style: TextStyle(fontSize: 16, color: _c.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: completando || esPasado || esFutura || esFuturaMismoDia ? null : () => _completar(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: completada ? const Color(0xFF22C55E) : (esPasado || esFutura || esFuturaMismoDia ? Colors.grey : _c.primary),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (completando)
                          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        else ...[
                          Icon(completada ? Icons.check_circle : Icons.star, size: 22),
                          const SizedBox(width: 8),
                          Text(completada ? '¡COMPLETADO!' : (esFutura || esFuturaMismoDia ? 'PRÓXIMO' : 'COMPLETAR'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ]),
            ]),
          ),
      )],
      ),
    );
  }

  // Barra inferior: progreso del día (X de Y completadas)
  Widget _barraInferior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(color: _c.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$_completadas de ${_actividades.length} completadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _c.textPrimary)),
        const SizedBox(width: 8),
        if (_completadas == _actividades.length && _actividades.isNotEmpty) const Text('🎉', style: TextStyle(fontSize: 28)),
      ]),
    );
  }
}
