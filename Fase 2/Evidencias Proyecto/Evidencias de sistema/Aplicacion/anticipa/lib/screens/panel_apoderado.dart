import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'panel_detalle_estudiante.dart';

// ═══════════════════════════════════════════════════════════
// PANEL APODERADO — Vincular hijos, ver perfiles, gestionar rutinas
// ═══════════════════════════════════════════════════════════
class PanelApoderado extends StatefulWidget {
  final int idUsuario;
  final String nombre;

  const PanelApoderado({super.key, required this.idUsuario, required this.nombre});

  @override
  State<PanelApoderado> createState() => _PanelApoderadoState();
}

class _PanelApoderadoState extends State<PanelApoderado> {
  List<Map<String, dynamic>> _hijos = [];
  Map<int, String> _cursosMap = {};
  Map<int, bool> _surveyStatus = {};
  bool _cargando = true;
  String? _error;

  // Default colors (no theme customization for this role)
  static const _bg   = Color(0xFFF5F7FF);
  static const _appB = Color(0xFF061A40);
  static const _card = Color(0xFFFFFFFF);
  static const _prim = Color(0xFF4F46E5);
  static const _txtP = Color(0xFF061A40);
  static const _txtS = Color(0xFF6B7280);
  static const _horaMinEncuesta = 20;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  // ── Carga de hijos vinculados + cursos ──────────────────
  Future<void> _cargarTodo() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await Future.wait([
        _get('${AppConstants.baseUrl}/estudiantes/usuario/${widget.idUsuario}'),
        _get('${AppConstants.baseUrl}/cursos/'),
      ]);
      final Map<int, String> cursos = {};
      for (final c in res[1]) {
        final id = c['id_curso'] as int;
        final nivel = c['nivel_academico'] ?? '';
        final letra = c['letra_academica'] ?? '';
        cursos[id] = letra.isNotEmpty ? '$nivel $letra' : '$nivel';
      }

      final Map<int, bool> status = {};
      for (final h in res[0]) {
        final idEst = h['id_estudiante'] as int;
        status[idEst] = await _verificarEncuestaHoy(idEst);
      }

      setState(() {
        _hijos = res[0];
        _cursosMap = cursos;
        _surveyStatus = status;
        _cargando = false;
      });
    } catch (_) {
      setState(() { _error = 'Error al cargar datos'; _cargando = false; });
    }
  }

  Future<bool> _verificarEncuestaHoy(int idEstudiante) async {
    try {
      final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/encuestas/verificar/$idEstudiante'),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['respondida'] == true;
      }
    } catch (_) { }
    return false;
  }

  bool get _esHoraDeEncuesta {
    final ahora = DateTime.now();
    return ahora.hour >= _horaMinEncuesta;
  }

  Future<List<Map<String, dynamic>>> _get(String url) async {
    try {
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (r.statusCode != 200) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    } catch (_) {
      return [];
    }
  }

  // ── Vincular hijo por código ────────────────────────────
  Future<void> _vincular(String codigo) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}/vinculaciones/codigo/${codigo.trim().toUpperCase()}'
      '?id_usuario=${widget.idUsuario}&rol_id_rol=3',
    );
    try {
      final r = await http.post(url).timeout(const Duration(seconds: 60));
      if (r.statusCode == 201) {
        await _cargarTodo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Vinculación exitosa!'), backgroundColor: Color(0xFF22C55E)),
          );
        }
        return;
      }
      String msg = 'Error al vincular';
      try {
        final data = jsonDecode(r.body);
        if (data is Map) msg = data['detail']?.toString() ?? msg;
      } catch (_) { }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is String ? e : 'Código inválido o ya vinculado'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Submit encuesta ─────────────────────────────────────
  Future<void> _enviarEncuesta(Map<String, dynamic> hijo, bool tuvoDesregulacion, {int? cantidad, String? motivo, String? observacion}) async {
    final idEst = hijo['id_estudiante'] as int;
    final body = {
      'estudiante_id_estudiante': idEst,
      'usuario_id_usuario': widget.idUsuario,
      'tuvo_desregulacion': tuvoDesregulacion,
      if (tuvoDesregulacion && cantidad != null) 'cantidad': cantidad,
      if (tuvoDesregulacion && motivo != null) 'motivo': motivo,
      if (tuvoDesregulacion && observacion != null) 'observacion': observacion,
    };
    try {
      final r = await http.post(
        Uri.parse('${AppConstants.baseUrl}/encuestas/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 201) {
        setState(() => _surveyStatus[idEst] = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tuvoDesregulacion
                  ? 'Registro guardado. ¡Cuídalo mucho!'
                  : '¡Registro guardado! Que sigan así.'),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
        }
        return;
      }
    } catch (_) { }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar encuesta'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarEncuesta(Map<String, dynamic> hijo) {
    bool? tuvo;
    int? cantidad;
    String? motivo;
    final obsCtrl = TextEditingController();

    bool puedeGuardar(bool? t, int? c) =>
        t != null && (t == false || (c != null && c != 999));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('¿Cómo estuvo ${hijo['nombre']} hoy?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF061A40))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _btnEncuesta('😊 Bien', const Color(0xFF22C55E), () => setModal(() { tuvo = false; }))),
              const SizedBox(width: 12),
              Expanded(child: _btnEncuesta('😔 Tuvo desregulación', const Color(0xFFEF4444), () => setModal(() { tuvo = true; }))),
            ]),
            if (tuvo == true) ...[
              const SizedBox(height: 20),
              const Text('¿Cuántas desregulaciones?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ...[1, 2, 3, 4, 5].map((n) => ChoiceChip(
                  label: Text('$n'),
                  selected: cantidad == n,
                  onSelected: (_) => setModal(() => cantidad = n),
                  selectedColor: const Color(0xFFEF4444),
                  labelStyle: TextStyle(color: cantidad == n ? Colors.white : const Color(0xFF061A40)),
                )),
                ChoiceChip(
                  label: const Text('Otro'),
                  selected: cantidad == 999,
                  onSelected: (_) => setModal(() { cantidad = 999; }),
                  selectedColor: const Color(0xFFEF4444),
                  labelStyle: TextStyle(color: cantidad == 999 ? Colors.white : const Color(0xFF061A40)),
                ),
              ]),
              if (cantidad == 999)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      labelText: '¿Cuántas? (1-15)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1 && n <= 15) {
                        setModal(() => cantidad = n);
                      }
                    },
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Motivo principal', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Ruido', child: Text('Ruido')),
                  DropdownMenuItem(value: 'Cambio de rutina', child: Text('Cambio de rutina')),
                  DropdownMenuItem(value: 'Comidas', child: Text('Comidas')),
                  DropdownMenuItem(value: 'Evaluaciones', child: Text('Evaluaciones')),
                  DropdownMenuItem(value: 'Conflictos familiares', child: Text('Conflictos familiares')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) => setModal(() => motivo = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: obsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Observación (opcional)', border: OutlineInputBorder())),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: puedeGuardar(tuvo, cantidad) ? () {
                Navigator.pop(ctx);
                _enviarEncuesta(
                  hijo,
                  tuvo!,
                  cantidad: cantidad,
                  motivo: motivo,
                  observacion: obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
                );
              } : null,
              child: const Text('Guardar', style: TextStyle(fontSize: 16)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _btnEncuesta(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
      ),
    );
  }

  void _mostrarDialogoVinculacion() {
    final codigoCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular hijo'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Ingresa el código de vinculación del estudiante:'),
          const SizedBox(height: 16),
          TextField(
            controller: codigoCtl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código (ej: ABC1234)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final c = codigoCtl.text.trim();
              if (c.isNotEmpty) { Navigator.pop(ctx); _vincular(c); }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  // ── Navegar al panel de detalle del hijo ────────────────
  void _abrirDetalle(Map<String, dynamic> hijo) {
    final idEstRaw = hijo['id_estudiante'];
    if (idEstRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: estudiante sin ID'), backgroundColor: Colors.red),
      );
      return;
    }
    final idEst = idEstRaw is int ? idEstRaw : int.tryParse(idEstRaw.toString()) ?? 0;
    if (idEst == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de estudiante inválido'), backgroundColor: Colors.red),
      );
      return;
    }

    final bool necesitaEncuesta = _esHoraDeEncuesta && (_surveyStatus[idEst] != true);

    if (necesitaEncuesta) {
      _mostrarEncuesta(hijo);
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PanelDetalleEstudiante(
          idEstudiante: idEst,
          idUsuario: widget.idUsuario,
          rol: 'Tutor / Apoderado',
          nombreEstudiante: hijo['nombre'] ?? '',
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Mis Hijos'),
        centerTitle: true,
        backgroundColor: _appB,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _hijos.isEmpty
                  ? _buildVacio()
                  : _buildLista(),
      floatingActionButton: _hijos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoVinculacion,
              backgroundColor: _prim,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Vincular hijo'),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off, size: 64, color: _txtS),
      const SizedBox(height: 16),
      Text(_error!, style: TextStyle(fontSize: 16, color: _txtS)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _cargarTodo, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
    ]));
  }

  Widget _buildVacio() {
    final codigoCtl = TextEditingController();
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.family_restroom, size: 80, color: _prim),
        const SizedBox(height: 20),
        Text('Bienvenido, ${widget.nombre}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _txtP)),
        const SizedBox(height: 8),
        Text('Aún no tienes hijos vinculados.\nIngresa el código de vinculación del estudiante.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _txtS)),
        const SizedBox(height: 24),
        SizedBox(width: 280, child: TextField(
          controller: codigoCtl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Código de vinculación',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.link, color: _prim),
          ),
        )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            final c = codigoCtl.text.trim();
            if (c.isNotEmpty) _vincular(c).then((_) => codigoCtl.clear());
          },
          icon: const Icon(Icons.person_add),
          label: const Text('VINCULAR HIJO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _prim,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
      ]),
    ));
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: Column(children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _hijos.length,
            itemBuilder: (_, i) => _tarjetaHijo(_hijos[i]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: _appB,
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('¡Hola ${widget.nombre}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('${_hijos.length} ${_hijos.length == 1 ? 'hijo vinculado' : 'hijos vinculados'}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ])),
        ]),
      ]),
    );
  }

  Widget _tarjetaHijo(Map<String, dynamic> hijo) {
    final cursoNombre = _cursosMap[hijo['curso_id_curso']] ?? 'Sin curso';
    final puntos = hijo['puntos_totales'] ?? 0;
    final idEst = hijo['id_estudiante'] as int;
    final bool necesitaEncuesta = _esHoraDeEncuesta && (_surveyStatus[idEst] != true);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirDetalle(hijo),
        onLongPress: () => _mostrarEncuesta(hijo),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_prim, _prim.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.face, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hijo['nombre'] ?? 'Sin nombre', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _txtP)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.school, size: 16, color: _prim),
                const SizedBox(width: 4),
                Text(cursoNombre, style: TextStyle(fontSize: 14, color: _txtS)),
              ]),
            ])),
            Column(children: [
              Row(children: [
                const Icon(Icons.star, size: 22, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$puntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _txtP)),
              ]),
              Text('puntos', style: TextStyle(fontSize: 12, color: _txtS)),
            ]),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: _txtS),
          ]),
          if (_esHoraDeEncuesta) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _mostrarEncuesta(hijo),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: necesitaEncuesta ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: necesitaEncuesta ? const Color(0xFFF59E0B) : const Color(0xFF22C55E)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_note, size: 16, color: necesitaEncuesta ? const Color(0xFFB45309) : const Color(0xFF15803D)),
                  const SizedBox(width: 4),
                  Text(
                    necesitaEncuesta ? 'Responder encuesta' : 'Encuesta respondida',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: necesitaEncuesta ? const Color(0xFFB45309) : const Color(0xFF15803D)),
                  ),
                ]),
              ),
            ),
          ],
        ])),
      ),
    );
  }
}
