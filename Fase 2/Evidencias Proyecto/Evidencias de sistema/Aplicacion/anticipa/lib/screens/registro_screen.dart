// =========================================================
// registro_screen.dart
// Pantalla de registro alineada con UsuarioCreate (schemas.py)
// Campos requeridos por la BD:
//   id_rol, nombre, email, password_hash,
//   fecha_nacimiento, curso (opcional),
//   codigo_vinculacion (opcional, solo Estudiantes)
// =========================================================
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

  final TextEditingController nombreController    = TextEditingController();
  final TextEditingController emailController     = TextEditingController();
  final TextEditingController passwordController  = TextEditingController();

  DateTime? fechaNacimiento;
  int idRolSeleccionado = 4;
  bool isLoading = false;
  String mensajeSistema = '';
  bool registroExitoso = false;
  String? codigoVinculacionGenerado;

  final Map<int, String> roles = {
    4: 'Estudiante',
    3: 'Tutor / Apoderado',
    2: 'Profesor',
  };

  final List<String> cursos = [
    '1° Básico A', '1° Básico B', '1° Básico C',
    '2° Básico A', '2° Básico B', '2° Básico C',
    '3° Básico A', '3° Básico B', '3° Básico C',
    '4° Básico A', '4° Básico B', '4° Básico C',
    '5° Básico A', '5° Básico B', '5° Básico C',
    '6° Básico A', '6° Básico B', '6° Básico C',
    '7° Básico A', '7° Básico B', '7° Básico C',
    '8° Básico A', '8° Básico B', '8° Básico C',
  ];
  String? cursoSeleccionado;

  // ── Selector de fecha de nacimiento ─────────────────────
  Future<void> seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
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
    // 1. Validar campos del formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. Validar que se haya seleccionado fecha de nacimiento
    if (fechaNacimiento == null) {
      setState(() => mensajeSistema = 'Por favor selecciona tu fecha de nacimiento.');
      return;
    }

    setState(() {
      isLoading = true;
      mensajeSistema = '';
    });

    final url = Uri.parse('${AppConstants.baseUrl}/usuarios/');

    // 3. Armar el body alineado con UsuarioCreate en schemas.py
    final Map<String, dynamic> body = {
      'id_rol': idRolSeleccionado,
      'nombre': nombreController.text.trim(),
      'email': emailController.text.trim(),
      'password_hash': passwordController.text,
      'fecha_nacimiento': fechaNacimiento!.toIso8601String().split('T')[0],
      'curso': cursoSeleccionado,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          registroExitoso = true;
          codigoVinculacionGenerado = data['codigo_vinculacion'];
          if (idRolSeleccionado == 4 && codigoVinculacionGenerado != null) {
            mensajeSistema = '¡Cuenta creada exitosamente!\nTu código de vinculación: ${codigoVinculacionGenerado}\nGuárdalo para vincularte con tu profesor.';
          } else {
            mensajeSistema = '¡Cuenta creada exitosamente! Ya puedes iniciar sesión.';
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

              // ── Selector de Rol ──────────────────────────
              const Text('Tipo de cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: idRolSeleccionado,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: roles.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => idRolSeleccionado = value!);
                },
              ),
              const SizedBox(height: 16),

              // ── Nombre ───────────────────────────────────
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // ── Email ────────────────────────────────────
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'El correo es obligatorio';
                  if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Contraseña ───────────────────────────────
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.length < 6
                    ? 'La contraseña debe tener mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Fecha de Nacimiento ──────────────────────
              // Requerida por la BD para la lógica de autonomía > 12 años
              GestureDetector(
                onTap: seleccionarFecha,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Fecha de Nacimiento *',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      hintText: fechaNacimiento == null
                          ? 'Selecciona una fecha'
                          : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                    ),
                    controller: TextEditingController(
                      text: fechaNacimiento == null
                          ? ''
                          : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (idRolSeleccionado == 4) ...[
                DropdownButtonFormField<String>(
                  value: cursoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Curso (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Selecciona un curso'),
                    ),
                    ...cursos.map((curso) => DropdownMenuItem<String>(
                      value: curso,
                      child: Text(curso),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => cursoSeleccionado = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Botón Registrar ──────────────────────────
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

              // ── Mensaje de resultado ─────────────────────
              if (mensajeSistema.isNotEmpty)
                Text(
                  mensajeSistema,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: registroExitoso ? Colors.green : Colors.red,
                  ),
                ),

              // ── Si el registro fue exitoso, botón para volver al login ──
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