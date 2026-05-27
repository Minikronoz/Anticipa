import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class PanelDetalleEstudiante extends StatefulWidget {
  final int idEstudiante;
  final int idUsuario;
  final String rol;
  final String nombreEstudiante;

  const PanelDetalleEstudiante({
    super.key,
    required this.idEstudiante,
    required this.idUsuario,
    required this.rol,
    required this.nombreEstudiante,
  });

  @override
  State<PanelDetalleEstudiante> createState() => _PanelDetalleEstudianteState();
}

class _PanelDetalleEstudianteState extends State<PanelDetalleEstudiante> {
  List<Map<String, dynamic>> actividades = [];
  List<Map<String, dynamic>> pictogramas = [];
  Map<String, dynamic>? estrellasHoy;
  bool isLoading = true;
  String error = '';

  DateTime selectedDate = DateTime.now();
  String calendarView = 'day';

  static const _diasSemana = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
  static const _diasSemanaLargo = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _mesesLargo = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  static const _mesesCorto = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

  bool get canEdit => widget.rol == 'Profesor' || widget.rol == 'Tutor / Apoderado';

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() { isLoading = true; error = ''; });
    try {
      final res = await Future.wait([_fetchActividades(), _fetchPictogramas(), _fetchEstrellas()]);
      setState(() {
        actividades = res[0] as List<Map<String, dynamic>>;
        pictogramas = res[1] as List<Map<String, dynamic>>;
        estrellasHoy = res[2] as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() { error = 'Error al cargar datos'; isLoading = false; });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActividades() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/actividades/estudiante/${widget.idEstudiante}'));
    return r.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(r.body)) : [];
  }

  Future<List<Map<String, dynamic>>> _fetchPictogramas() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/pictogramas/'));
    return r.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(r.body)) : [];
  }

  Future<Map<String, dynamic>?> _fetchEstrellas() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}'));
    if (r.statusCode != 200) return null;
    final data = List<Map<String, dynamic>>.from(jsonDecode(r.body));
    final hoy = _fmt(DateTime.now());
    return data.cast<Map<String, dynamic>?>().firstWhere((e) => e?['fecha'] == hoy, orElse: () => null);
  }

  Future<bool> _patch(String path) async {
    try {
      final r = await http.patch(Uri.parse('${AppConstants.baseUrl}$path'));
      if (r.statusCode == 200) { await _cargarTodo(); return true; }
    } catch (_) { setState(() => error = 'Error de conexión'); }
    return false;
  }

  Future<void> completarActividad(int id) => _patch('/actividades/$id/completar');

  Future<void> eliminarActividad(int id) async {
    try {
      final r = await http.delete(Uri.parse('${AppConstants.baseUrl}/actividades/$id'));
      if (r.statusCode == 200) await _cargarTodo();
    } catch (_) { setState(() => error = 'Error al eliminar'); }
  }

  Future<void> editarActividad(Map<String, dynamic> a) async {
    final nombreCtl = TextEditingController(text: a['nombre_tarea'] ?? '');
    final horaCtl = TextEditingController(text: (a['hora_inicio'] ?? '').toString().substring(0, 5));
    String? pictoId = a['pictograma_id_pictograma']?.toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Editar Actividad'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nombreCtl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: horaCtl, decoration: const InputDecoration(labelText: 'Hora (HH:MM)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: pictoId,
                decoration: const InputDecoration(labelText: 'Pictograma', border: OutlineInputBorder()),
                items: [const DropdownMenuItem(value: null, child: Text('Sin pictograma')),
                  ...pictogramas.map((p) => DropdownMenuItem(value: p['id_pictograma'].toString(), child: Text(p['nombre_imagen'] ?? ''))),
                ],
                onChanged: (v) => setDlg(() => pictoId = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final body = <String, dynamic>{'nombre_tarea': nombreCtl.text.trim(), 'hora_inicio': '${horaCtl.text.trim()}:00'};
    if (pictoId != null) body['pictograma_id_pictograma'] = int.parse(pictoId!);
    try {
      final r = await http.patch(Uri.parse('${AppConstants.baseUrl}/actividades/${a['id_actividad']}'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (r.statusCode == 200) await _cargarTodo();
    } catch (_) { setState(() => error = 'Error al editar'); }
  }

  static String _fmt(DateTime d) => d.toIso8601String().split('T')[0];

  List<Map<String, dynamic>> get _hoyActividades {
    final f = _fmt(selectedDate);
    return actividades.where((a) => (a['fecha_actividad']?.toString() ?? '').startsWith(f)).toList();
  }

  Map<String, dynamic>? _pictograma(int? id) => id == null ? null : pictogramas.cast<Map<String, dynamic>?>().firstWhere((p) => p?['id_pictograma'] == id, orElse: () => null);

  int get _estrellas => estrellasHoy?['estrellas_ganadas'] ?? 0;
  int get _completadas => _hoyActividades.where((a) => a['es_completada'] == true).length;

  List<DateTime> get _semana {
    final lunes = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return List.generate(7, (i) => lunes.add(Duration(days: i)));
  }

  List<DateTime> get _mesDias {
    final first = DateTime(selectedDate.year, selectedDate.month, 1);
    final last = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final pad = first.weekday - 1;
    return [
      for (int i = pad; i > 0; i--) first.subtract(Duration(days: i)),
      for (int i = 0; i < last.day; i++) first.add(Duration(days: i)),
      for (int i = 1; i <= 42 - (pad + last.day); i++) last.add(Duration(days: i)),
    ];
  }

  int _cuenta(DateTime d) {
    final f = _fmt(d);
    return actividades.where((a) => (a['fecha_actividad']?.toString() ?? '').startsWith(f)).length;
  }

  void _avanzar(int pasos) => setState(() {
    if (calendarView == 'week') {
      selectedDate = selectedDate.add(Duration(days: pasos * 7));
    } else if (calendarView == 'month') {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + pasos, selectedDate.day.clamp(1, 28));
    } else {
      selectedDate = selectedDate.add(Duration(days: pasos));
    }
  });

  String _tituloCalendario() {
    if (calendarView == 'month') return '${_mesesLargo[selectedDate.month - 1]} ${selectedDate.year}';
    if (calendarView == 'week') { final s = _semana; return 'Sem. ${s.first.day}/${s.first.month} - ${s.last.day}/${s.last.month}/${s.last.year}'; }
    return '${_diasSemanaLargo[selectedDate.weekday - 1]}, ${selectedDate.day} de ${_mesesCorto[selectedDate.month - 1]} de ${selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Panel Estudiante'), centerTitle: true,
        backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          _header(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.emoji_events, size: 18), label: const Text('Recompensas'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.assessment, size: 18), label: const Text('Reportes'))),
          ]),
          const SizedBox(height: 16),
          _selectorVista(),
          const SizedBox(height: 12),
          _navegacion(),
          const SizedBox(height: 8),
          if (calendarView == 'week') _vistaSemana(),
          if (calendarView == 'month') _vistaMes(),
          const SizedBox(height: 16),
          _listaActividades(),
          if (error.isNotEmpty) ...[const SizedBox(height: 12), Center(child: Text(error, style: const TextStyle(color: Colors.red)))],
        ]),
      ),
    );
  }

  Widget _header() => Card(
    elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.person, size: 40, color: Colors.white)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.nombreEstudiante, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF061A40))),
        Text('Calendario de rutinas', style: TextStyle(color: Colors.grey[600])),
      ])),
      Column(children: [
        Row(children: List.generate(_estrellas.clamp(0, 5), (_) => const Text('⭐', style: TextStyle(fontSize: 22)))),
        Text('$_estrellas estrellas hoy', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text('$_completadas/${_hoyActividades.length} completadas', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4F46E5))),
      ]),
    ])),
  );

  Widget _selectorVista() => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(4),
    child: Row(children: ['Día', 'Semana', 'Mes'].map((l) {
      final v = l == 'Día' ? 'day' : l == 'Semana' ? 'week' : 'month';
      final sel = calendarView == v;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => calendarView = v),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? const Color(0xFF4F46E5) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(l, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[700])),
        ),
      ));
    }).toList()),
  );

  Widget _navegacion() => Card(
    elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _avanzar(-1)),
      Expanded(child: Text(_tituloCalendario(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF061A40)))),
      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _avanzar(1)),
    ])),
  );

  Widget _vistaSemana() {
    final hoy = _fmt(DateTime.now());
    return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(8), child: Row(
      children: _semana.map((d) {
        final df = _fmt(d); final sel = df == _fmt(selectedDate); final isToday = df == hoy; final c = _cuenta(d);
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => selectedDate = d),
          child: _dayCell(d.day, _diasSemana[d.weekday - 1], c, sel, isToday),
        ));
      }).toList(),
    )));
  }

  Widget _vistaMes() {
    final hoy = _fmt(DateTime.now());
    return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
      Row(children: _diasSemana.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))))).toList()),
      const SizedBox(height: 4),
      Wrap(children: _mesDias.map((d) {
        final df = _fmt(d); final sel = df == _fmt(selectedDate); final isToday = df == hoy;
        final inM = d.month == selectedDate.month; final c = _cuenta(d);
        return GestureDetector(
          onTap: () { if (inM) setState(() => selectedDate = d); },
          child: Container(
            width: (MediaQuery.of(context).size.width - 72) / 7, padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF4F46E5) : (isToday && !sel ? const Color(0xFFE0E7FF) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: isToday && !sel ? Border.all(color: const Color(0xFF4F46E5), width: 1.5) : null,
            ),
            child: Column(children: [
              Text('${d.day}', style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: !inM ? Colors.grey[300] : sel ? Colors.white : const Color(0xFF061A40))),
              if (c > 0) Text('$c', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? Colors.white : const Color(0xFF4F46E5))),
            ]),
          ),
        );
      }).toList()),
    ])));
  }

  Widget _dayCell(int day, String label, int count, bool selected, bool today) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10), margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF4F46E5) : today ? const Color(0xFFE0E7FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      border: today && !selected ? Border.all(color: const Color(0xFF4F46E5), width: 2) : null,
    ),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Colors.grey)),
      Text('$day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF061A40))),
      if (count > 0) Container(margin: const EdgeInsets.only(top: 2), width: 20, height: 20, decoration: BoxDecoration(color: selected ? Colors.white24 : const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.white)))),
    ]),
  );

  Widget _listaActividades() {
    final lista = _hoyActividades;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Actividades para ${selectedDate.day} de ${_mesesCorto[selectedDate.month - 1]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF061A40)))),
      if (lista.isEmpty)
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No hay actividades para este día', style: TextStyle(fontSize: 16, color: Colors.grey)))))
      else
        ...lista.map((a) {
          final picto = _pictograma(a['pictograma_id_pictograma']);
          final ok = a['es_completada'] == true;
          final hora = (a['hora_inicio'] ?? '').toString().substring(0, 5);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: ok ? const BorderSide(color: Color(0xFF22C55E), width: 2) : BorderSide.none),
            color: ok ? const Color(0xFFF0FDF4) : Colors.white,
            child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              SizedBox(width: 60, child: Text(hora, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))),
              ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF)),
                child: picto?['url'] != null
                    ? Image.network(picto!['url'], width: 44, height: 44, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('📌', style: TextStyle(fontSize: 30)))
                    : const Center(child: Text('📌', style: TextStyle(fontSize: 30))),
              ),
            ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['nombre_tarea'] ?? 'Sin nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF061A40), decoration: ok ? TextDecoration.lineThrough : null)),
                if (picto != null) Text(picto['nombre_imagen'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ])),
              if (canEdit) ...[
                IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey), tooltip: 'Editar', onPressed: () => editarActividad(a)),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), tooltip: 'Eliminar', onPressed: () => _confirmarEliminar(a)),
              ],
              ElevatedButton.icon(
                onPressed: () => completarActividad(a['id_actividad']),
                icon: Icon(ok ? Icons.close : Icons.check, size: 18),
                label: Text(ok ? 'Desmarcar' : 'Completar'),
                style: ElevatedButton.styleFrom(backgroundColor: ok ? const Color(0xFF22C55E) : const Color(0xFF4F46E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ])),
          );
        }),
    ]);
  }

  void _confirmarEliminar(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text('¿Eliminar "${a['nombre_tarea']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); eliminarActividad(a['id_actividad']); }, child: const Text('Eliminar')),
        ],
      ),
    );
  }
}
