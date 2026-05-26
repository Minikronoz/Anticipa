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

  bool isLoading = false;
  String mensajeSistema = '';
  bool registroExitoso = false;
  String? rolDetectado;

  static const Map<String, String> dominiosRoles = {
    'gmail.com': 'Tutor / Apoderado',
    'outlook.com': 'Tutor / Apoderado',
    'profesor.cl': 'Profesor',
    'estudiante.cl': 'Estudiante',
    'duocuc.cl': 'Estudiante',
  };

  String? _rolDelEmail(String email) {
    final dominio = email.split('@').last.toLowerCase();
    return dominiosRoles[dominio];
  }

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

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          registroExitoso = true;
          rolDetectado = data['rol'];
          mensajeSistema = '¡Cuenta creada exitosamente como ${data['rol']}!';
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
    final dominioActual = emailController.text.contains('@')
        ? emailController.text.split('@').last.toLowerCase()
        : '';

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
                ),
                validator: (v) => v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  helperText: 'Usa @gmail.com, @outlook.com, @profesor.cl, @estudiante.cl o @duocuc.cl',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'El correo es obligatorio';
                  if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo válido';
                  final rol = _rolDelEmail(v);
                  if (rol == null) return 'Dominio no autorizado. Revisa los permitidos.';
                  return null;
                },
              ),

              if (dominioActual.isNotEmpty && _rolDelEmail(emailController.text) != null)
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
                ),
                validator: (v) => v!.length < 6
                    ? 'La contraseña debe tener mínimo 6 caracteres'
                    : null,
              ),
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
