import 'package:flutter/material.dart';

class PanelProfesor extends StatelessWidget {
  const PanelProfesor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Panel Profesor'),
        backgroundColor: Colors.blue[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Bienvenido/a', //al panel de profesor
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Desde aquí podrás gestionar alumnos, actividades visuales y alertas de anticipación.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            _opcionPanel(
              icono: Icons.group,
              titulo: 'Alumnos vinculados',
              descripcion: 'Ver estudiantes asociados al profesor.',
            ),
            _opcionPanel(
              icono: Icons.add_task,
              titulo: 'Crear actividad',
              descripcion: 'Asignar una rutina visual con horario y pictograma.',
            ),
            _opcionPanel(
              icono: Icons.notifications_active,
              titulo: 'Configurar alertas',
              descripcion: 'Definir anticipación, sonido y apoyo visual.',
            ),
            _opcionPanel(
              icono: Icons.bar_chart,
              titulo: 'Historial de cumplimiento',
              descripcion: 'Revisar avances y actividades completadas.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcionPanel({
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ListTile(
        leading: Icon(icono, size: 36, color: Colors.blue),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}

