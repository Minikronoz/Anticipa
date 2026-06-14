// ═══════════════════════════════════════════════════════════
// PANEL DETALLE ESTUDIANTE — Gestión de actividades (profesor / apoderado)
// Calendario día/semana/mes, CRUD, selector de pictogramas con categorías
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_theme.dart';
import 'reporte_estudiante_screen.dart';

class PanelDetalleEstudiante extends StatefulWidget {
  final int idEstudiante;
  final int idUsuario;
  final String rol;
  final String nombreEstudiante;
  final ThemeConfig? themeConfig;

  const PanelDetalleEstudiante({
    super.key,
    required this.idEstudiante,
    required this.idUsuario,
    required this.rol,
    required this.nombreEstudiante,
    this.themeConfig,
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

  ThemeColors get _c => (widget.themeConfig ?? ThemeConfig.defaultTheme()).colors;

  // ── Carga de datos desde API ────────────────────────────
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
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/actividades/estudiante/${widget.idEstudiante}')).timeout(const Duration(seconds: 60));
    return r.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(r.body)) : [];
  }

  Future<List<Map<String, dynamic>>> _fetchPictogramas() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/pictogramas/')).timeout(const Duration(seconds: 60));
    return r.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(r.body)) : [];
  }

  Future<Map<String, dynamic>?> _fetchEstrellas() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/estrellas/estudiante/${widget.idEstudiante}')).timeout(const Duration(seconds: 60));
    if (r.statusCode != 200) return null;
    final data = List<Map<String, dynamic>>.from(jsonDecode(r.body));
    return data.cast<Map<String, dynamic>?>().firstWhere((e) => e?['fecha'] == _hoyUtc, orElse: () => null);
  }

  // ── CRUD: completar, eliminar, editar, crear ────────────
  Future<bool> _patch(String path) async {
    try {
      final r = await http.patch(Uri.parse('${AppConstants.baseUrl}$path')).timeout(const Duration(seconds: 60));
      if (r.statusCode == 200) { await _cargarTodo(); return true; }
    } catch (_) { setState(() => error = 'Error de conexión'); }
    return false;
  }

  Future<void> completarActividad(int id) => _patch('/actividades/$id/completar');

  Future<void> eliminarActividad(int id) async {
    try {
      final r = await http.delete(Uri.parse('${AppConstants.baseUrl}/actividades/$id')).timeout(const Duration(seconds: 60));
      if (r.statusCode == 200) await _cargarTodo();
    } catch (_) { setState(() => error = 'Error al eliminar'); }
  }

  Map<String, dynamic>? _pictoSeleccionado(int? id) {
    if (id == null) return null;
    for (final p in pictogramas) {
      if (p['id_pictograma'] == id) return p;
    }
    return null;
  }

  // ── Selector de pictogramas con categorías ───────────────
  Future<Map<String, dynamic>?> _mostrarSelectorPictograma(String? actual) async {
    final cats = <String>{'Todos'};
    for (final p in pictogramas) {
      cats.add(p['categoria']?.toString() ?? 'General');
    }
    final categorias = cats.toList()..sort((a, b) {
      if (a == 'Todos') return -1;
      if (b == 'Todos') return 1;
      return a.compareTo(b);
    });

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        String categoriaSel = 'Todos';
        String? seleccionado = actual;

        return StatefulBuilder(
        builder: (ctx, setDlg) {

          List<Map<String, dynamic>> filtrar() => categoriaSel == 'Todos'
              ? pictogramas
              : pictogramas.where((p) => (p['categoria']?.toString() ?? 'General') == categoriaSel).toList();

          Widget chip(String label) {
            final sel = categoriaSel == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : _c.primary)),
                selected: sel,
                selectedColor: _c.primary,
                backgroundColor: _c.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
                onSelected: (_) => setDlg(() => categoriaSel = label),
              ),
            );
          }

          Widget tarjeta(Map<String, dynamic> p) {
            final id = p['id_pictograma'].toString();
            final sel = seleccionado == id;
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, p),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sel ? _c.primary.withValues(alpha: 0.1) : _c.background,
                  borderRadius: BorderRadius.circular(16),
                  border: sel ? Border.all(color: _c.primary, width: 2.5) : null,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: p['url'] != null
                        ? Image.network(p['url'], width: 64, height: 64, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.image, size: 64, color: Colors.grey))
                        : const Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(p['nombre_imagen'] ?? '', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _c.textPrimary)),
                ]),
              ),
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SizedBox(
              height: 520,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(children: [
                  Row(children: [
                    Text('Elegir pictograma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _c.textPrimary)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Elige un pictograma representativo para la actividad.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: categorias.map((c) => chip(c)).toList()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtrar().isEmpty
                        ? const Center(child: Text('Sin pictogramas', style: TextStyle(color: Colors.grey)))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, childAspectRatio: 0.60, crossAxisSpacing: 10, mainAxisSpacing: 10),
                            itemCount: filtrar().length,
                            itemBuilder: (_, i) => tarjeta(filtrar()[i]),
                          ),
                  ),
                ]),
              ),
            ),
          );
        },
      );
      },
    );
  }

  // ── Modal: Nueva actividad ──────────────────────────────
  Future<void> _nuevaActividad() async {
    final nombreCtl = TextEditingController();
    final horaIni = _horaActualRedondeada();
    final horaCtl = TextEditingController(text: horaIni);
    final horaFinCtl = TextEditingController(text: _sumar5Min(horaIni));
    Map<String, dynamic>? pictoElegido;
    DateTime fechaAct = selectedDate;
    String alertaMin = '5';
    bool horaInicioCustom = false;
    String customHoraIni = horaIni.substring(0, 2);
    String customMinIni = horaIni.substring(3, 5);
    bool horaFinCustom = false;
    String customHoraFin = _sumar5Min(horaIni).substring(0, 2);
    String customMinFin = _sumar5Min(horaIni).substring(3, 5);
    bool customAlerta = false;
    final customAlertaCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Nueva Actividad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _c.textPrimary)),
              const SizedBox(height: 4),
              Text('para ${widget.nombreEstudiante}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 24),

              _campoTexto('Nombre de la actividad', 'Ej: Lavarse los dientes', nombreCtl),
              const SizedBox(height: 16),

              Text('Elegir pictograma', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final p = await _mostrarSelectorPictograma(pictoElegido?['id_pictograma']?.toString());
                  if (p != null) setDlg(() => pictoElegido = p);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
                  child: pictoElegido != null
                      ? Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(pictoElegido!['url'], width: 44, height: 44, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.image, size: 44))),
                          const SizedBox(width: 12),
                          Text(pictoElegido!['nombre_imagen'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ])
                      : const Text('Toca para elegir un pictograma', style: TextStyle(fontSize: 15, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 16),

              _campoFecha(fechaAct, (d) => setDlg(() {
                  fechaAct = d;
                  if (_esHoy(d)) {
                    final horaActual = _horaActualRedondeada();
                    final horaActualInt = int.parse(horaActual.substring(0, 2));
                    final horaIniInt = int.parse(horaCtl.text.substring(0, 2));
                    if (horaIniInt < horaActualInt || (horaIniInt == horaActualInt && horaCtl.text.substring(3, 5).compareTo(horaActual.substring(3, 5)) < 0)) {
                      horaCtl.text = horaActual;
                      horaFinCtl.text = _sumar5Min(horaActual);
                    }
                  }
                })),
              const SizedBox(height: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hora inicio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
                const SizedBox(height: 6),
                if (!horaInicioCustom)
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasDisponibles(fechaAct).contains(horaCtl.text.substring(0, 2)) ? horaCtl.text.substring(0, 2) : _horasDisponibles(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasDisponibles(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                final minsDisp = _minutosDisponibles(fechaAct, v);
                                final currentMin = horaCtl.text.substring(3, 5);
                                final newMin = minsDisp.contains(currentMin) ? currentMin : minsDisp.first;
                                horaCtl.text = '$v:$newMin';
                                horaFinCtl.text = _sumar5Min(horaCtl.text);
                                horaFinCustom = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _minutosDisponibles(fechaAct, horaCtl.text.substring(0, 2)).contains(horaCtl.text.substring(3, 5)) ? horaCtl.text.substring(3, 5) : _minutosDisponibles(fechaAct, horaCtl.text.substring(0, 2)).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _minutosDisponibles(fechaAct, horaCtl.text.substring(0, 2)).map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                horaCtl.text = '${horaCtl.text.substring(0, 2)}:$v';
                                horaFinCtl.text = _sumar5Min(horaCtl.text);
                                horaFinCustom = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaInicioCustom = true; customHoraIni = horaCtl.text.substring(0, 2); customMinIni = horaCtl.text.substring(3, 5); }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ])
                else
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasOtro(fechaAct).contains(customHoraIni) ? customHoraIni : _horasOtro(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasOtro(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customHoraIni = v; horaCtl.text = '$v:$customMinIni'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _todosMinutos().contains(customMinIni) ? customMinIni : _todosMinutos().first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _todosMinutos().map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customMinIni = v; horaCtl.text = '$customHoraIni:$v'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaInicioCustom = false; horaCtl.text = '$customHoraIni:$customMinIni'; }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ]),
              ]),
              const SizedBox(height: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hora fin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
                const SizedBox(height: 6),
                if (!horaFinCustom)
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasDisponibles(fechaAct).contains(horaFinCtl.text.substring(0, 2)) ? horaFinCtl.text.substring(0, 2) : _horasDisponibles(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasDisponibles(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                final minsDisp = _minutosDisponibles(fechaAct, v);
                                final currentMin = horaFinCtl.text.substring(3, 5);
                                final newMin = minsDisp.contains(currentMin) ? currentMin : minsDisp.first;
                                horaFinCtl.text = '$v:$newMin';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _minutosDisponibles(fechaAct, horaFinCtl.text.substring(0, 2)).contains(horaFinCtl.text.substring(3, 5)) ? horaFinCtl.text.substring(3, 5) : _minutosDisponibles(fechaAct, horaFinCtl.text.substring(0, 2)).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _minutosDisponibles(fechaAct, horaFinCtl.text.substring(0, 2)).map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                horaFinCtl.text = '${horaFinCtl.text.substring(0, 2)}:$v';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaFinCustom = true; customHoraFin = horaFinCtl.text.substring(0, 2); customMinFin = horaFinCtl.text.substring(3, 5); }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ])
                else
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasOtro(fechaAct).contains(customHoraFin) ? customHoraFin : _horasOtro(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasOtro(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customHoraFin = v; horaFinCtl.text = '$v:$customMinFin'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _todosMinutos().contains(customMinFin) ? customMinFin : _todosMinutos().first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _todosMinutos().map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customMinFin = v; horaFinCtl.text = '$customHoraFin:$v'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaFinCustom = false; horaFinCtl.text = '$customHoraFin:$customMinFin'; }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ]),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Icon(Icons.notifications, size: 16, color: _c.primary),
                const SizedBox(width: 6),
                Text('Anticipación de alerta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
              ]),
              const SizedBox(height: 6),
              if (!customAlerta)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: alertaMin,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: '0', child: Text('Sin alerta')),
                        DropdownMenuItem(value: '2', child: Text('2 minutos')),
                        DropdownMenuItem(value: '5', child: Text('5 minutos')),
                        DropdownMenuItem(value: '10', child: Text('10 minutos')),
                        DropdownMenuItem(value: '15', child: Text('15 minutos')),
                        DropdownMenuItem(value: '_custom', child: Text('Otro (personalizado)')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setDlg(() {
                          if (v == '_custom') { customAlerta = true; customAlertaCtl.text = ''; }
                          else { alertaMin = v; }
                        });
                      },
                    ),
                  ),
                )
              else
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: customAlertaCtl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Ej: 3',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixText: 'minutos',
                        suffixStyle: TextStyle(color: _c.textSecondary, fontSize: 14),
                      ),
                      onChanged: (v) => setDlg(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setDlg(() { customAlerta = false; }),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), child: Text('Cancelar', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                  ),
                ]),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancelar', style: TextStyle(fontSize: 15)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: _c.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Guardar actividad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
              ]),
            ]),
          ),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final nombre = nombreCtl.text.trim();
    if (nombre.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre de la actividad no puede estar vacío'), backgroundColor: Colors.red)); return; }
    if (nombre.length > 100) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede exceder 100 caracteres'), backgroundColor: Colors.red)); return; }
    if (!_esHoraValida(horaCtl.text)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hora de inicio inválida (use formato HH:MM)'), backgroundColor: Colors.red)); return; }
    if (!_esHoraValida(horaFinCtl.text)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hora de fin inválida (use formato HH:MM)'), backgroundColor: Colors.red)); return; }
    if (!_esHoraFinMayor(horaFinCtl.text, horaCtl.text)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de fin debe ser mayor que la hora de inicio'), backgroundColor: Colors.red)); return; }
    if (_esHoy(fechaAct)) {
      final ahora = DateTime.now();
      final ahoraMin = ahora.hour * 60 + ahora.minute;
      final iniMin = int.parse(horaCtl.text.substring(0, 2)) * 60 + int.parse(horaCtl.text.substring(3, 5));
      final finMin = int.parse(horaFinCtl.text.substring(0, 2)) * 60 + int.parse(horaFinCtl.text.substring(3, 5));
      if (iniMin < ahoraMin) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de inicio no puede ser pasada'), backgroundColor: Colors.red)); return; }
      if (finMin < ahoraMin) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de fin no puede ser pasada'), backgroundColor: Colors.red)); return; }
    }

    final body = <String, dynamic>{
      'estudiante_id_estudiante': widget.idEstudiante,
      'usuario_id_usuario': widget.idUsuario,
      'nombre_tarea': nombreCtl.text.trim(),
      'hora_inicio': '${horaCtl.text.trim().padRight(5, '0')}:00',
      'hora_fin': '${horaFinCtl.text.trim().padRight(5, '0')}:00',
      'fecha_actividad': _fmt(fechaAct),
    };
    if (pictoElegido != null) body['pictograma_id_pictograma'] = pictoElegido!['id_pictograma'];
    if (customAlerta) {
      final customVal = customAlertaCtl.text.trim();
      if (customVal.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa los minutos de anticipación'), backgroundColor: Colors.red)); return; }
      final customInt = int.tryParse(customVal) ?? 0;
      if (customInt > 480) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La alerta no puede exceder 480 minutos (8 horas)'), backgroundColor: Colors.red)); return; }
      body['alerta_minutos'] = customVal;
    } else if (alertaMin != '0') {
      body['alerta_minutos'] = alertaMin;
    }

    try {
      final r = await http.post(Uri.parse('${AppConstants.baseUrl}/actividades/'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 60));
      if (r.statusCode == 201) await _cargarTodo();
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${r.statusCode}: No se pudo crear la actividad'), backgroundColor: Colors.red));
    } catch (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear actividad'), backgroundColor: Colors.red)); }
  }

  // ── Modal: Editar actividad ─────────────────────────────
  Future<void> editarActividad(Map<String, dynamic> a) async {
    final nombreCtl = TextEditingController(text: a['nombre_tarea'] ?? '');
    final horaIniRaw = _safeTime(a['hora_inicio'], '00:00');
    final horaFinRaw = _safeTime(a['hora_fin'], '00:05');
    final horaCtl = TextEditingController(text: horaIniRaw);
    final horaFinCtl = TextEditingController(text: horaFinRaw);
    Map<String, dynamic>? pictoElegido = _pictoSeleccionado(a['pictograma_id_pictograma']);
    bool horaInicioCustom = false;
    String customHoraIni = horaIniRaw.substring(0, 2);
    String customMinIni = horaIniRaw.substring(3, 5);
    bool horaFinCustom = false;
    String customHoraFin = horaFinRaw.substring(0, 2);
    String customMinFin = horaFinRaw.substring(3, 5);

    DateTime fechaAct;
    try {
      final fechaStr = a['fecha_actividad']?.toString() ?? '';
      fechaAct = DateTime.parse(fechaStr.split('T')[0]);
    } catch (_) {
      fechaAct = DateTime.now();
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Editar Actividad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _c.textPrimary)),
              const SizedBox(height: 24),

              _campoTexto('Nombre de la actividad', '', nombreCtl),
              const SizedBox(height: 16),

              Text('Elegir pictograma', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final p = await _mostrarSelectorPictograma(pictoElegido?['id_pictograma']?.toString());
                  if (p != null) setDlg(() => pictoElegido = p);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
                  child: pictoElegido != null
                      ? Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(pictoElegido!['url'], width: 44, height: 44, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.image, size: 44))),
                          const SizedBox(width: 12),
                          Text(pictoElegido!['nombre_imagen'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ])
                      : const Text('Toca para elegir un pictograma', style: TextStyle(fontSize: 15, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hora inicio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
                const SizedBox(height: 6),
                if (!horaInicioCustom)
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasDisponibles(fechaAct).contains(horaCtl.text.substring(0, 2)) ? horaCtl.text.substring(0, 2) : _horasDisponibles(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasDisponibles(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                final minsDisp = _minutosDisponibles(fechaAct, v);
                                final currentMin = horaCtl.text.substring(3, 5);
                                final newMin = minsDisp.contains(currentMin) ? currentMin : minsDisp.first;
                                horaCtl.text = '$v:$newMin';
                                horaFinCtl.text = _sumar5Min(horaCtl.text);
                                horaFinCustom = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _minutosDisponibles(fechaAct, horaCtl.text.substring(0, 2)).contains(horaCtl.text.substring(3, 5)) ? horaCtl.text.substring(3, 5) : _minutosDisponibles(fechaAct, horaCtl.text.substring(0, 2)).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _minutosDisponibles(fechaAct, horaCtl.text.substring(0, 2)).map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                horaCtl.text = '${horaCtl.text.substring(0, 2)}:$v';
                                horaFinCtl.text = _sumar5Min(horaCtl.text);
                                horaFinCustom = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaInicioCustom = true; customHoraIni = horaCtl.text.substring(0, 2); customMinIni = horaCtl.text.substring(3, 5); }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ])
                else
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasOtro(fechaAct).contains(customHoraIni) ? customHoraIni : _horasOtro(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasOtro(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customHoraIni = v; horaCtl.text = '$v:$customMinIni'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _todosMinutos().contains(customMinIni) ? customMinIni : _todosMinutos().first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _todosMinutos().map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customMinIni = v; horaCtl.text = '$customHoraIni:$v'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaInicioCustom = false; horaCtl.text = '$customHoraIni:$customMinIni'; }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ]),
              ]),
              const SizedBox(height: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hora fin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
                const SizedBox(height: 6),
                if (!horaFinCustom)
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasDisponibles(fechaAct).contains(horaFinCtl.text.substring(0, 2)) ? horaFinCtl.text.substring(0, 2) : _horasDisponibles(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasDisponibles(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                final minsDisp = _minutosDisponibles(fechaAct, v);
                                final currentMin = horaFinCtl.text.substring(3, 5);
                                final newMin = minsDisp.contains(currentMin) ? currentMin : minsDisp.first;
                                horaFinCtl.text = '$v:$newMin';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _minutosDisponibles(fechaAct, horaFinCtl.text.substring(0, 2)).contains(horaFinCtl.text.substring(3, 5)) ? horaFinCtl.text.substring(3, 5) : _minutosDisponibles(fechaAct, horaFinCtl.text.substring(0, 2)).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _minutosDisponibles(fechaAct, horaFinCtl.text.substring(0, 2)).map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() {
                                horaFinCtl.text = '${horaFinCtl.text.substring(0, 2)}:$v';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaFinCustom = true; customHoraFin = horaFinCtl.text.substring(0, 2); customMinFin = horaFinCtl.text.substring(3, 5); }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ])
                else
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _horasOtro(fechaAct).contains(customHoraFin) ? customHoraFin : _horasOtro(fechaAct).first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _horasOtro(fechaAct).map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customHoraFin = v; horaFinCtl.text = '$v:$customMinFin'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _todosMinutos().contains(customMinFin) ? customMinFin : _todosMinutos().first,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: _todosMinutos().map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 15)))).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDlg(() { customMinFin = v; horaFinCtl.text = '$customHoraFin:$v'; });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setDlg(() { horaFinCustom = false; horaFinCtl.text = '$customHoraFin:$customMinFin'; }),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('Otro', style: TextStyle(color: _c.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ]),
              ]),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancelar', style: TextStyle(fontSize: 15)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: _c.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Guardar cambios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final nombre = nombreCtl.text.trim();
    if (nombre.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre de la actividad no puede estar vacío'), backgroundColor: Colors.red)); return; }
    if (nombre.length > 100) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede exceder 100 caracteres'), backgroundColor: Colors.red)); return; }
    if (!_esHoraValida(horaCtl.text)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hora de inicio inválida (use formato HH:MM)'), backgroundColor: Colors.red)); return; }
    if (!_esHoraValida(horaFinCtl.text)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hora de fin inválida (use formato HH:MM)'), backgroundColor: Colors.red)); return; }
    if (!_esHoraFinMayor(horaFinCtl.text, horaCtl.text)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de fin debe ser mayor que la hora de inicio'), backgroundColor: Colors.red)); return; }
    if (_esHoy(fechaAct)) {
      final ahora = DateTime.now();
      final horaActualMin = ahora.hour * 60 + ahora.minute;
      final horaInicioMin = int.parse(horaCtl.text.substring(0, 2)) * 60 + int.parse(horaCtl.text.substring(3, 5));
      final horaFinMin = int.parse(horaFinCtl.text.substring(0, 2)) * 60 + int.parse(horaFinCtl.text.substring(3, 5));
      if (horaInicioMin < horaActualMin) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de inicio no puede ser pasada'), backgroundColor: Colors.red)); return; }
      if (horaFinMin < horaActualMin) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de fin no puede ser pasada'), backgroundColor: Colors.red)); return; }
    }

    final body = <String, dynamic>{
      'nombre_tarea': nombre,
      'hora_inicio': '${horaCtl.text.trim().padRight(5, '0')}:00',
      'hora_fin': '${horaFinCtl.text.trim().padRight(5, '0')}:00',
    };
    if (pictoElegido != null) body['pictograma_id_pictograma'] = pictoElegido!['id_pictograma'];
    try {
      final r = await http.patch(Uri.parse('${AppConstants.baseUrl}/actividades/${a['id_actividad']}'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 60));
      if (r.statusCode == 200) { await _cargarTodo(); }
      else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error ${r.statusCode}: No se pudo editar la actividad'), backgroundColor: Colors.red)); }
    } catch (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al editar actividad'), backgroundColor: Colors.red)); }
  }

  // ── Widgets helpers para modales ────────────────────────
  static const _horas = ['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23'];
  static const _minutos = ['00','05','10','15','20','25','30','35','40','45','50','55'];

  String _sumar5Min(String hora) {
    final parts = hora.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final total = m + 5;
    final finH = (h + total ~/ 60) % 24;
    final finM = total % 60;
    return '${finH.toString().padLeft(2, '0')}:${finM.toString().padLeft(2, '0')}';
  }

  String _horaActualRedondeada() {
    final now = DateTime.now();
    final minutes = now.minute;
    final rounded = ((minutes ~/ 5) + 1) * 5;
    final h = (now.hour + (rounded >= 60 ? 1 : 0)) % 24;
    final m = rounded >= 60 ? 0 : rounded;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  bool _esHoy(DateTime fecha) {
    final now = DateTime.now();
    return fecha.year == now.year && fecha.month == now.month && fecha.day == now.day;
  }

  bool _esPasado(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(fecha.year, fecha.month, fecha.day);
    return target.isBefore(today);
  }

  bool _esActividadPasada(Map<String, dynamic> a) {
    final fechaStr = a['fecha_actividad']?.toString();
    if (fechaStr == null) return false;
    try {
      final fecha = DateTime.parse(fechaStr.split('T')[0]);
      return _esPasado(fecha);
    } catch (_) {
      return false;
    }
  }

  List<String> _horasDisponibles(DateTime fecha) {
    if (!_esHoy(fecha)) return _horas;
    final now = DateTime.now();
    return _horas.where((h) => int.parse(h) >= now.hour).toList();
  }

  List<String> _minutosDisponibles(DateTime fecha, String hora) {
    if (!_esHoy(fecha)) return _minutos;
    final now = DateTime.now();
    final horaInt = int.tryParse(hora) ?? 0;
    if (horaInt > now.hour) return _minutos;
    return _minutos.where((m) => int.parse(m) >= (horaInt == now.hour ? (now.minute ~/ 5) * 5 : 0)).toList();
  }

  List<String> _horasOtro(DateTime fecha) {
    if (!_esHoy(fecha)) return _horas;
    final now = DateTime.now();
    return _horas.where((h) => int.parse(h) >= now.hour).toList();
  }

  List<String> _todosMinutos() {
    return ['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42','43','44','45','46','47','48','49','50','51','52','53','54','55','56','57','58','59'];
  }

  String _safeTime(String? value, String fallback) {
    final v = (value ?? '').toString().trim();
    if (v.length < 5) return fallback;
    return '${v.substring(0, 2)}:${v.substring(3, 5)}';
  }

  bool _esHoraValida(String h) {
    final regex = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
    if (!regex.hasMatch(h)) return false;
    final parts = h.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  bool _esHoraFinMayor(String fin, String inicio) {
    final partsFin = fin.split(':');
    final partsInicio = inicio.split(':');
    final finMin = int.parse(partsFin[0]) * 60 + int.parse(partsFin[1]);
    final inicioMin = int.parse(partsInicio[0]) * 60 + int.parse(partsInicio[1]);
    return finMin > inicioMin;
  }

  Widget _campoTexto(String label, String placeholder, TextEditingController ctl, {String? hint, ValueChanged<String>? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: placeholder.isNotEmpty ? placeholder : (hint ?? ''),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _campoFecha(DateTime valor, ValueChanged<DateTime> onChange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Fecha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _c.textPrimary)),
      const SizedBox(height: 6),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: valor, firstDate: DateTime.now(), lastDate: DateTime(2030), helpText: 'Selecciona la fecha', locale: const Locale('es', 'CL'));
          if (picked != null) onChange(picked);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
          child: Row(children: [
            Icon(Icons.calendar_today, size: 18, color: _c.primary),
            const SizedBox(width: 10),
            Text('${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}', style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ),
    ]);
  }

  // ── Lógica de calendario (día/semana/mes) ───────────────
  static String _fmt(DateTime d) => d.toIso8601String().split('T')[0];
  static String get _hoyUtc => DateTime.now().toUtc().toIso8601String().split('T')[0];

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

  // ── Construcción de UI ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: _c.background,
      appBar: AppBar(
        title: const Text('Panel Estudiante'), centerTitle: true,
        backgroundColor: _c.appBar, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 90), children: [
          _header(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.emoji_events, size: 18), label: const Text('Recompensas'))),
            const SizedBox(width: 12),
            // aca hice un cambio para hacer funcionar boton reportes 
            Expanded(
    child: OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReporteEstudianteScreen(
              idEstudiante: widget.idEstudiante,
              nombreEstudiante: widget.nombreEstudiante,
            ),
          ),
        );
      },
      // hasta aca
            icon: const Icon(Icons.assessment, size: 18), label: const Text('Reportes'))),
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
      floatingActionButton: (!canEdit || _esPasado(selectedDate))
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: _nuevaActividad,
              backgroundColor: _c.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva actividad'),
            ),
    );
  }

  Widget _header() => Card(
    elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: _c.primary, borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.person, size: 40, color: Colors.white)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.nombreEstudiante, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _c.textPrimary)),
        Text('Calendario de rutinas', style: TextStyle(color: Colors.grey[600])),
      ])),
      Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text('$_estrellas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _c.textPrimary)),
        ]),
        Text('estrellas hoy', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('$_completadas/${_hoyActividades.length} completadas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _c.primary)),
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
        child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? _c.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(l, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey[700])),
        ),
      ));
    }).toList()),
  );

  Widget _navegacion() => Card(
    elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _avanzar(-1)),
      Expanded(child: Text(_tituloCalendario(), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _c.textPrimary))),
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
              color: sel ? _c.primary : (isToday && !sel ? _c.primary.withValues(alpha: 0.15) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: isToday && !sel ? Border.all(color: _c.primary, width: 1.5) : null,
            ),
            child: Column(children: [
              Text('${d.day}', style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: !inM ? Colors.grey[300] : sel ? Colors.white : _c.textPrimary)),
              if (c > 0) Text('$c', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? Colors.white : _c.primary)),
            ]),
          ),
        );
      }).toList()),
    ])));
  }

  Widget _dayCell(int day, String label, int count, bool selected, bool today) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10), margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: selected ? _c.primary : today ? _c.primary.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      border: today && !selected ? Border.all(color: _c.primary, width: 2) : null,
    ),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Colors.grey)),
      Text('$day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selected ? Colors.white : _c.textPrimary)),
      if (count > 0) Container(margin: const EdgeInsets.only(top: 2), width: 20, height: 20, decoration: BoxDecoration(color: selected ? Colors.white24 : _c.primary, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.white)))),
    ]),
  );

  Widget _listaActividades() {
    final lista = _hoyActividades;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Actividades para ${selectedDate.day} de ${_mesesCorto[selectedDate.month - 1]}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _c.textPrimary))),
      if (lista.isEmpty)
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No hay actividades para este día', style: TextStyle(fontSize: 16, color: Colors.grey)))))
      else
        ...lista.map((a) {
          final picto = _pictograma(a['pictograma_id_pictograma']);
          final ok = a['es_completada'] == true;
          final esPasado = _esActividadPasada(a);
          final hora = _safeTime(a['hora_inicio'], '--:--');
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: ok ? const BorderSide(color: Color(0xFF22C55E), width: 2) : BorderSide.none),
            color: ok ? const Color(0xFFF0FDF4) : Colors.white,
            child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SizedBox(width: 50, child: Text(hora, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _c.primary))),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: _c.primary.withValues(alpha: 0.1)),
                    child: picto?['url'] != null
                        ? Image.network(picto!['url'], width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('📌', style: TextStyle(fontSize: 26)))
                        : const Center(child: Text('📌', style: TextStyle(fontSize: 26))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Row(children: [
                  Expanded(child: Text(a['nombre_tarea'] ?? 'Sin nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _c.textPrimary, decoration: ok ? TextDecoration.lineThrough : null))),
                  if (esPasado) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock, size: 16, color: Colors.grey)),
                ])),
              ]),
              if (picto != null) Padding(padding: const EdgeInsets.only(left: 50, top: 2), child: Text(picto['nombre_imagen'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (canEdit && !esPasado) ...[
                  IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey), tooltip: 'Editar', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), onPressed: () => editarActividad(a)),
                  IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), tooltip: 'Eliminar', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), onPressed: () => _confirmarEliminar(a)),
                ],
                ElevatedButton.icon(
                  onPressed: esPasado ? null : () => completarActividad(a['id_actividad']),
                  icon: Icon(ok ? Icons.close : Icons.check, size: 16),
                  label: Text(ok ? 'Desmarcar' : 'Completar', style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: esPasado ? Colors.grey : (ok ? const Color(0xFF22C55E) : _c.primary), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ]),
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
