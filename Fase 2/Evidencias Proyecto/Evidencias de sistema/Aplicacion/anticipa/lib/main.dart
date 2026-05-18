import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/panel_profesor.dart';

void main() {
  runApp(const AnticipaApp());
}

class AnticipaApp extends StatelessWidget {
  const AnticipaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anticipa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
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
  bool isLoading = false; // Para mostrar un indicador de carga

  Future<void> hacerLogin() async {
    setState(() {
      isLoading = true;
      mensajeSistema = "";
    });

    // IMPORTANTE PARA EL EMULADOR:
    // 10.0.2.2 es la dirección IP especial que usa el emulador de Android 
    // para referirse a la máquina anfitriona (localhost) donde corre FastAPI.
    // en navegador (Web) o Windows, usar '127.0.0.1'.
    final url = Uri.parse('http://127.0.0.1:8000/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rol = data['rol'];
        String nombre = data['nombre'];

        setState(() {
          mensajeSistema = "¡Bienvenido $nombre!\nTu rol es: $rol";
        });

        // AQUÍ AGREGAREMOS LA NAVEGACIÓN DESPUÉS
        // if (rol == 'Estudiante') {
        //   Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarioEstudiante()));
        // } else {
        //   Navigator.push(context, MaterialPageRoute(builder: (context) => PanelAdulto()));
        // }

      } else if (response.statusCode == 401) {
        setState(() {
          mensajeSistema = "Credenciales incorrectas.";
        });
      } else {
         setState(() {
          mensajeSistema = "Error del servidor: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        mensajeSistema = "No se pudo conectar al servidor.\nAsegúrate de que el backend esté corriendo en el puerto 8000.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anticipa - Acceso'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.calendar_today_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isLoading ? null : hacerLogin,
                child: isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
              Text(
                mensajeSistema,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  
                  color: mensajeSistema.contains("Bienvenido") ? Colors.green[700] : Colors.red,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}