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

  int idRolSeleccionado = 3;
  bool isLoading = false;
  String mensajeSistema = '';
  bool registroExitoso = false;

  final Map<int, String> roles = {
    3: 'Tutor / Apoderado',
    2: 'Profesor',
  };

  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      mensajeSistema = '';
    });

    final url = Uri.parse('${AppConstants.baseUrl}/usuarios/');

    final Map<String, dynamic> body = {
      'id_rol': idRolSeleccionado,
      'nombre': nombreController.text.trim(),
      'email': emailController.text.trim(),
      'password_hash': passwordController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        setState(() {
          registroExitoso = true;
          mensajeSistema = '¡Cuenta creada exitosamente! Ya puedes iniciar sesión.';
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
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return 'El correo es obligatorio';
                  if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo válido';
                  return null;
                },
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