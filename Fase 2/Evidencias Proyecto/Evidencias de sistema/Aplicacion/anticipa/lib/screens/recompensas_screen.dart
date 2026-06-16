import 'package:flutter/material.dart';

class RecompensasScreen extends StatelessWidget {
  final int idEstudiante;
  final String nombreEstudiante;

  const RecompensasScreen({
    super.key,
    required this.idEstudiante,
    required this.nombreEstudiante,
  });

  @override
  Widget build(BuildContext context) {
    const int puntos = 80;

    final recompensas = [
      {
        "nombre": "Elegir actividad favorita",
        "costo": 50,
        "icono": Icons.palette,
      },
      {
        "nombre": "5 minutos de juego educativo",
        "costo": 80,
        "icono": Icons.sports_esports,
      },
      {
        "nombre": "Medalla virtual",
        "costo": 100,
        "icono": Icons.emoji_events,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recompensas"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(nombreEstudiante),
                subtitle: Text("Puntos disponibles: $puntos ⭐"),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: recompensas.length,
                itemBuilder: (context, index) {
                  final recompensa = recompensas[index];
                  final int costo = recompensa["costo"] as int;
                  final bool disponible = puntos >= costo;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        recompensa["icono"] as IconData,
                        size: 32,
                      ),
                      title: Text(
                        recompensa["nombre"].toString(),
                      ),
                      subtitle: Text(
                        "Costo: $costo ⭐",
                      ),
                      trailing: disponible
                          ? ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Recompensa asignada: ${recompensa["nombre"]}",
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Canjear"),
                            )
                          : const Chip(
                              label: Text("Bloqueada"),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}