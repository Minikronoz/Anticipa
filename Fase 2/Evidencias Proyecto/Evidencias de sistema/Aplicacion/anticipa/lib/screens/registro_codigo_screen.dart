import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../theme/app_theme.dart';

class RegistroCodigoScreen extends StatefulWidget {
  final ThemeConfig themeConfig;

  const RegistroCodigoScreen({super.key, required this.themeConfig});

  @override
  State<RegistroCodigoScreen> createState() => _RegistroCodigoScreenState();
}

class _RegistroCodigoScreenState extends State<RegistroCodigoScreen> {
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String mensaje = '';

  ThemeColors get colors => widget.themeConfig.colors;

  Future<void> _registrar() async {
    setState(() {
      mensaje = '';
      isLoading = true;
    });

    if (_passwordController.text.length < 6) {
      setState(() { mensaje = 'La contraseña debe tener al menos 6 caracteres'; isLoading = false; });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() { mensaje = 'Las contraseñas no coinciden'; isLoading = false; });
      return;
    }

    try {
      final r = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/registro-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo': _codigoController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 60));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        setState(() { mensaje = '¡Registro exitoso! Ahora inicia sesión con tu email.'; });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        final body = jsonDecode(r.body);
        setState(() { mensaje = body['detail'] ?? 'Error al registrar'; });
      }
    } catch (e) {
      setState(() { mensaje = 'Error de conexión con el servidor'; });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro con código'),
        backgroundColor: colors.appBar,
      ),
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.vpn_key_outlined, size: 80, color: colors.primary),
            const SizedBox(height: 24),
            Text(
              'Ingresa el código que te entregó el director',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codigoController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código de vinculación',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colors.textSecondary),
                fillColor: colors.card,
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Crear contraseña',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colors.textSecondary),
                fillColor: colors.card,
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colors.textSecondary),
                fillColor: colors.card,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _registrar,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REGISTRARME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: mensaje.contains('exitoso') ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }
}
