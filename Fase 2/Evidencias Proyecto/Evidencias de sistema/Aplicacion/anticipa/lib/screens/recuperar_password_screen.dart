import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  int pasoActual = 1;
  bool isLoading = false;
  String mensaje = '';
  bool esExitoso = false;

  Future<void> solicitarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      mensaje = '';
    });

    final url = Uri.parse('${AppConstants.baseUrl}/auth/solicitar-codigo');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          pasoActual = 2;
          mensaje = data['mensaje'] ?? 'Código enviado a tu correo.';
        });
      } else {
        setState(() => mensaje = data['detail'] ?? 'Ocurrió un error.');
      }
    } catch (e) {
      setState(() => mensaje = 'Error de conexión con el servidor.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      mensaje = '';
    });

    final url = Uri.parse('${AppConstants.baseUrl}/auth/cambiar-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'codigo': codigoController.text.trim(),
          'nueva_password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          esExitoso = true;
          mensaje = '¡Contraseña actualizada correctamente!';
        });
      } else {
        setState(() => mensaje = data['detail'] ?? 'Ocurrió un error.');
      }
    } catch (e) {
      setState(() => mensaje = 'Error de conexión con el servidor.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 64, color: Colors.blue),
              const SizedBox(height: 20),

              if (esExitoso) ...[
                const Text(
                  'Tu contraseña ha sido actualizada correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ir a Iniciar Sesión'),
                ),
              ] else ...[
                if (pasoActual == 1) ...[
                  const Text(
                    'Ingresa tu correo electrónico y te enviaremos un código de verificación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'El correo es obligatorio';
                      if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : solicitarCodigo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('ENVIAR CÓDIGO', style: TextStyle(fontSize: 16)),
                  ),
                ] else ...[
                  Text(
                    'Ingresa el código de 6 dígitos que enviamos a ${emailController.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: codigoController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código de verificación',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'El código es obligatorio';
                      if (v.length != 6) return 'El código debe tener 6 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña',
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : cambiarPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('CAMBIAR CONTRASEÑA', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => pasoActual = 1),
                    child: const Text('Volver a ingresar email'),
                  ),
                ],

                if (mensaje.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: esExitoso ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}