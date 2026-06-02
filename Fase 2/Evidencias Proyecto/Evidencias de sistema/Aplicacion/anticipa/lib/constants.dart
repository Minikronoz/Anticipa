// =========================================================
// constants.dart
// Cambia solo esta IP cuando cambies de red o de computador
// que corre el backend. Así no tienes que buscarla en
// cada archivo de la app.
// =========================================================

class AppConstants {
  // ── Cambia esta IP por la del computador que corre uvicorn ──
  // En navegador/emulador: usa 127.0.0.1
  // En celular físico:     usa la IP local 
  static const String baseUrl = 'https://anticipa.onrender.com';
}