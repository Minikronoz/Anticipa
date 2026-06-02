import 'package:flutter/material.dart';
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
  bool _cargando = true;
  String? _error;

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
      setState(() {
        _hijos = res[0];
        _cursosMap = cursos;
        _cargando = false;
      });
    } catch (_) {
      setState(() { _error = 'Error al cargar datos'; _cargando = false; });
    }
  }

  Future<List<Map<String, dynamic>>> _get(String url) async {
    final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    return r.statusCode == 200 ? List<Map<String, dynamic>>.from(jsonDecode(r.body)) : [];
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
      final data = jsonDecode(r.body);
      throw data['detail'] ?? 'Error al vincular';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is String ? e : 'Código inválido o ya vinculado'), backgroundColor: Colors.red),
        );
      }
    }
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
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PanelDetalleEstudiante(
        idEstudiante: hijo['id_estudiante'],
        idUsuario: widget.idUsuario,
        rol: 'Tutor / Apoderado',
        nombreEstudiante: hijo['nombre'] ?? '',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Mis Hijos'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4F46E5),
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
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Vincular hijo'),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _cargarTodo, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
    ]));
  }

  Widget _buildVacio() {
    final codigoCtl = TextEditingController();
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.family_restroom, size: 80, color: Color(0xFF4F46E5)),
        const SizedBox(height: 20),
        Text('Bienvenido, ${widget.nombre}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF061A40))),
        const SizedBox(height: 8),
        const Text('Aún no tienes hijos vinculados.\nIngresa el código de vinculación del estudiante.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 24),
        SizedBox(width: 280, child: TextField(
          controller: codigoCtl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de vinculación',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
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
            backgroundColor: const Color(0xFF4F46E5),
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
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirDetalle(hijo),
        child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.face, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hijo['nombre'] ?? 'Sin nombre', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF061A40))),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.school, size: 16, color: Color(0xFF4F46E5)),
              const SizedBox(width: 4),
              Text(cursoNombre, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ]),
          ])),
          Column(children: [
            Row(children: [
              const Icon(Icons.star, size: 22, color: Colors.amber),
              const SizedBox(width: 4),
              Text('$puntos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF061A40))),
            ]),
            const Text('puntos', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ])),
      ),
    );
  }
}
