import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/panel_profesor.dart';
import 'screens/panel_estudiante.dart';
import 'screens/panel_apoderado.dart';
import 'screens/registro_screen.dart';
import 'screens/recuperar_password_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'constants.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AnticipaApp());
}

class AnticipaApp extends StatefulWidget {
  const AnticipaApp({super.key});

  @override
  State<AnticipaApp> createState() => _AnticipaAppState();
}

class _AnticipaAppState extends State<AnticipaApp> {
  ThemeConfig _themeConfig = ThemeConfig.defaultTheme();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final config = await ThemeService.loadTheme();
    setState(() {
      _themeConfig = config;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anticipa',
      debugShowCheckedModeBanner: false,
      theme: _themeConfig.toThemeData(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : LoginScreen(
              themeConfig: _themeConfig,
              onThemeChanged: (newConfig) => setState(() => _themeConfig = newConfig),
            ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final ThemeConfig themeConfig;
  final Function(ThemeConfig) onThemeChanged;

  const LoginScreen({super.key, required this.themeConfig, required this.onThemeChanged});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String mensajeSistema = "";
  bool isLoading = false;

  Future<void> _openThemeSettings() async {
    final result = await Navigator.push<ThemeConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => ThemeSettingsScreen(currentConfig: widget.themeConfig),
      ),
    );
    if (result != null) {
      widget.onThemeChanged(result);
    }
  }

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

        if (rolId == 2) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PanelProfesor(idUsuarioProfesor: idUsuario),
          ));
          return;
        }

        if (rolId == 4) {
          final int idEstudiante = data['id_estudiante'] ?? 0;
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => PanelEstudiante(
              idEstudiante: idEstudiante,
              idUsuario: idUsuario,
              rol: data['rol'] ?? '',
              nombreEstudiante: nombre,
              themeConfig: widget.themeConfig,
              onThemeChanged: widget.onThemeChanged,
            ),
          ));
          return;
        }

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
    final colors = widget.themeConfig.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anticipa - Acceso'),
        backgroundColor: colors.appBar,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Personalizar colores',
            onPressed: _openThemeSettings,
          ),
        ],
      ),
      backgroundColor: colors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.calendar_today_rounded, size: 80, color: colors.primary),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Correo',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colors.textSecondary),
                fillColor: colors.card,
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colors.textSecondary),
                fillColor: colors.card,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : hacerLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RecuperarPasswordScreen()));
              },
              child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: colors.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistroScreen()));
              },
              child: Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: colors.primary)),
            ),
            Text(mensajeSistema, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}