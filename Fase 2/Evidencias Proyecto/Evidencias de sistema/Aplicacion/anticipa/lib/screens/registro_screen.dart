// ═══════════════════════════════════════════════════════════
// REGISTRO — Detección de rol por dominio de email
// Campos fecha y curso visibles solo para estudiantes
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController   = TextEditingController();
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  DateTime? fechaNacimiento;
  int? cursoIdSeleccionado;
  bool isLoading = false;
  String mensajeSistema = '';
  bool registroExitoso = false;
  String? rolDetectado;
  String? codigoVinculacion;

  // ── Mapeo dominio → rol ─────────────────────────────────
  static const Map<String, String> dominiosRoles = {
    'gmail.com': 'Tutor / Apoderado',
    'outlook.com': 'Tutor / Apoderado',
    'profesor.cl': 'Profesor',
    'estudiante.cl': 'Estudiante',
    'duocuc.cl': 'Estudiante',
  };

  static const List<Map<String, dynamic>> cursos = [
    {'id': 1, 'nombre': '1° Básico A'},
    {'id': 2, 'nombre': '1° Básico B'},
    {'id': 3, 'nombre': '2° Básico A'},
    {'id': 4, 'nombre': '2° Básico B'},
    {'id': 5, 'nombre': '3° Básico A'},
    {'id': 6, 'nombre': '3° Básico B'},
    {'id': 7, 'nombre': '4° Básico A'},
    {'id': 8, 'nombre': '4° Básico B'},
    {'id': 9, 'nombre': '5° Básico A'},
    {'id': 10, 'nombre': '5° Básico B'},
    {'id': 11, 'nombre': '6° Básico A'},
    {'id': 12, 'nombre': '6° Básico B'},
    {'id': 13, 'nombre': '7° Básico A'},
    {'id': 14, 'nombre': '7° Básico B'},
    {'id': 15, 'nombre': '8° Básico A'},
    {'id': 16, 'nombre': '8° Básico B'},
  ];

  String? _rolDelEmail(String email) {
    final dominio = email.split('@').last.toLowerCase();
    return dominiosRoles[dominio];
  }

  bool get _esEstudiante => _rolDelEmail(emailController.text) == 'Estudiante';

  // ── Selector de fecha ───────────────────────────────────
  Future<void> seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaNacimiento ?? DateTime(2010),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Selecciona fecha de nacimiento',
    );
    if (picked != null) {
      setState(() => fechaNacimiento = picked);
    }
  }

  // ── Envío del formulario al backend ─────────────────────
  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      mensajeSistema = '';
    });

    final url = Uri.parse('${AppConstants.baseUrl}/usuarios/registro');

    final Map<String, dynamic> body = {
      'nombre': nombreController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
    };

    if (fechaNacimiento != null) {
      body['fecha_nacimiento'] = fechaNacimiento!.toIso8601String().split('T')[0];
    }
    if (cursoIdSeleccionado != null) {
      body['curso_id_curso'] = cursoIdSeleccionado;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          registroExitoso = true;
          mensajeSistema = data['mensaje'] ?? '¡Registro exitoso!';
          if (data['codigo_vinculacion'] != null) {
            codigoVinculacion = data['codigo_vinculacion'];
          }
        });
      } else if (response.statusCode == 409) {
        setState(() => mensajeSistema = 'Ya existe una cuenta con ese correo electrónico.');
      } else {
        final data = jsonDecode(response.body);
        setState(() => mensajeSistema = 'Error: ${data['detail'] ?? 'No se pudo crear la cuenta.'}');
      }
    } catch (e) {
      setState(() => mensajeSistema = 'Error de conexión con el servidor.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: emailController.text.contains('@')
                      ? Icon(
                          _rolDelEmail(emailController.text) != null
                              ? Icons.check_circle
                              : Icons.error,
                          color: _rolDelEmail(emailController.text) != null
                              ? Colors.green
                              : Colors.red,
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'El correo es obligatorio';
                  if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo válido';
                  final rol = _rolDelEmail(v);
                  if (rol == null) return 'Correo no autorizado para registro.';
                  return null;
                },
              ),
              if (emailController.text.contains('@') && _rolDelEmail(emailController.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Se registrará como: ${_rolDelEmail(emailController.text)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) {
                  if (v!.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v != passwordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_esEstudiante) ...[
              // ── Fecha de Nacimiento ──────────────────────
              GestureDetector(
                onTap: seleccionarFecha,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _esEstudiante
                          ? 'Fecha de Nacimiento *'
                          : 'Fecha de Nacimiento',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: fechaNacimiento == null
                          ? 'dd/mm/aaaa'
                          : '${fechaNacimiento!.day.toString().padLeft(2, '0')}/${fechaNacimiento!.month.toString().padLeft(2, '0')}/${fechaNacimiento!.year}',
                    ),
                    controller: TextEditingController(
                      text: fechaNacimiento == null
                          ? ''
                          : '${fechaNacimiento!.day.toString().padLeft(2, '0')}/${fechaNacimiento!.month.toString().padLeft(2, '0')}/${fechaNacimiento!.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Curso ──────────────────────────────────────
              DropdownButtonFormField<int>(
                value: cursoIdSeleccionado,
                decoration: InputDecoration(
                  labelText: _esEstudiante ? 'Curso *' : 'Curso',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.school),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Selecciona un curso'),
                  ),
                  ...cursos.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['nombre'] as String),
                  )),
                ],
                onChanged: (value) {
                  setState(() => cursoIdSeleccionado = value);
                },
              ),
              ],
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading || registroExitoso ? null : registrarUsuario,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('CREAR CUENTA', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),

              if (mensajeSistema.isNotEmpty)
                Text(
                  mensajeSistema,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: registroExitoso ? Colors.green : Colors.red,
                  ),
                ),

              if (codigoVinculacion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Tu código de vinculación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        codigoVinculacion!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Comparte este código con tu apoderado o profesor para que se vinculen a tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],

              if (registroExitoso) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ir a Iniciar Sesión'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
