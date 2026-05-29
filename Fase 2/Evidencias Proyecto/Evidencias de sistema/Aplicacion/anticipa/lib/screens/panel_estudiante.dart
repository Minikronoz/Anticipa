import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class PanelEstudiante extends StatefulWidget {
  final int idEstudiante;
  final int idUsuario;
  final String rol;
  final String nombreEstudiante;

  const PanelEstudiante({
    super.key,
    required this.idEstudiante,
    required this.idUsuario,
    required this.rol,
    required this.nombreEstudiante,
  });

  @override
  State<PanelEstudiante> createState() => _PanelEstudianteState();
}

class _PanelEstudianteState extends State<PanelEstudiante> {
  List<Map<String, dynamic>> _actividades = [];
  List<Map<String, dynamic>> _pictogramas = [];
  int _estrellas = 0;
  bool _cargando = true;
  final Set<int> _completandoIds = {};
  DateTime _fechaSeleccionada = DateTime.now();

  String get _fechaFormateada => _fechaSeleccionada.toIso8601String().split('T')[0];

  static const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _diasLargos = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

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
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<List<Map<String, dynamic>>> _get(String url) async {
    final r = await http.get(Uri.parse(url));
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

  Future<void> _completar(int id) async {
    setState(() => _completandoIds.add(id));
    try {
      final r = await http.patch(Uri.parse('${AppConstants.baseUrl}/actividades/$id/completar'));
      if (r.statusCode == 200) await _cargarTodo();
    } catch (_) {
    } finally {
      setState(() => _completandoIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
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

  Widget _barraSuperior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
          Row(children: List.generate(_estrellas.clamp(0, 5), (_) => const Text('⭐', style: TextStyle(fontSize: 26)))),
          Text('$_estrellas estrellas', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      ]),
    );
  }

  Widget _vacio() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📭', style: TextStyle(fontSize: 72)),
      const SizedBox(height: 16),
      Text('No hay actividades para este día', style: const TextStyle(fontSize: 20, color: Color(0xFF061A40))),
      const SizedBox(height: 8),
      const Text('Pídele a tu profesor o apoderado\nque te agregue actividades', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
    ]));
  }

  Widget _tiraDias() {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final dias = _diasVisibles;

    return Container(
      color: const Color(0xFF4F46E5),
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
                    Text(_fechaLabel(d), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: seleccionado ? const Color(0xFF4F46E5) : Colors.white)),
                    const SizedBox(height: 2),
                    Text('${d.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: seleccionado ? const Color(0xFF4F46E5) : Colors.white)),
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

  Widget _listaActividades() {
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _actividades.length,
        itemBuilder: (_, i) => _tarjetaActividad(_actividades[i]),
      ),
    );
  }

  Widget _tarjetaActividad(Map<String, dynamic> a) {
    final id = a['id_actividad'] as int;
    final completada = a['es_completada'] == true;
    final completando = _completandoIds.contains(id);
    final picto = _pictoUrl(a['pictograma_id_pictograma']);
    final hora = (a['hora_inicio'] ?? '').toString().substring(0, 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: completada ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: completada ? Border.all(color: const Color(0xFF22C55E), width: 3) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(24)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: picto != null
                ? Image.network(picto, width: 100, height: 100, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('📌', style: TextStyle(fontSize: 64)))
                : const Text('📌', style: TextStyle(fontSize: 64)),
          ),
        ),
        const SizedBox(height: 12),
        Text(a['nombre_tarea'] ?? 'Actividad', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF061A40), decoration: completada ? TextDecoration.lineThrough : null)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.access_time, size: 18, color: Color(0xFF4F46E5)),
          const SizedBox(width: 4),
          Text(hora, style: const TextStyle(fontSize: 18, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: completando ? null : () => _completar(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: completada ? const Color(0xFF22C55E) : const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (completando)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                else ...[
                  Icon(completada ? Icons.check_circle : Icons.star, size: 28),
                  const SizedBox(width: 10),
                  Text(completada ? '¡COMPLETADO!' : 'COMPLETAR', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _barraInferior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$_completadas de ${_actividades.length} completadas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF061A40))),
        const SizedBox(width: 8),
        if (_completadas == _actividades.length && _actividades.isNotEmpty) const Text('🎉', style: TextStyle(fontSize: 28)),
      ]),
    );
  }
}
