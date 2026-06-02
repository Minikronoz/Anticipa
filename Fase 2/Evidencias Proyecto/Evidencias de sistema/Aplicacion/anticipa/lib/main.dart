import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/panel_profesor.dart';
import 'screens/panel_estudiante.dart';
import 'screens/panel_apoderado.dart';
import 'screens/registro_screen.dart';
import 'screens/recuperar_password_screen.dart';
import 'constants.dart';

// ── Punto de entrada ──────────────────────────────────────
void main() {
  runApp(const AnticipaApp());
}

// ── App raíz: tema, rutas, home ─────────────────────────

class AnticipaApp extends StatelessWidget {
  const AnticipaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anticipa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String mensajeSistema = "";
  bool isLoading = false;

  // ── Autenticación contra backend + navegación por rol ──────
  Future<void> hacerLogin() async {
    setState(() {
      isLoading = true;
      mensajeSistema = "";
    });

    final url = Uri.parse('${AppConstants.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final int rolId = data['rol_id_rol'] ?? 0;
        final int idUsuario = data['id_usuario'] ?? 0;
        final String nombre = data['nombre'] ?? '';

        // rolId 2 = Profesor
        if (rolId == 2) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PanelProfesor(idUsuarioProfesor: idUsuario),
          ));
          return;
        }

        // rolId 4 = Estudiante
        if (rolId == 4) {
          final int idEstudiante = data['id_estudiante'] ?? 0;
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PanelEstudiante(idEstudiante: idEstudiante, idUsuario: idUsuario, rol: data['rol'] ?? '', nombreEstudiante: nombre),
          ));
          return;
        }

        // rolId 3 = Tutor / Apoderado
        if (rolId == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PanelApoderado(idUsuario: idUsuario, nombre: nombre),
          ));
          return;
        }

        setState(() {
          mensajeSistema = "¡Bienvenido ${data['nombre']}!\nRol: ${data['rol']}";
        });
      } else {
        setState(() => mensajeSistema = "Error: Credenciales incorrectas.");
      }
    } catch (e) {
      setState(() => mensajeSistema = "Error de conexión con el servidor.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anticipa - Acceso')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : hacerLogin,
              child: isLoading ? const CircularProgressIndicator() : const Text('INICIAR SESIÓN'),
            ),
            const SizedBox(height: 20),
            
            // BOTÓN RECUPERAR
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecuperarPasswordScreen()));
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
            
            // BOTÓN REGISTRO
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroScreen()));
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
            
            Text(mensajeSistema, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}