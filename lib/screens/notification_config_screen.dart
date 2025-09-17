import 'package:flutter/material.dart';

class NotificationConfigScreen extends StatelessWidget {
  const NotificationConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5️⃣ Configurar Notificações'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: const Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Configurar Notificações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Funcionalidade em desenvolvimento.\n\nEsta tela permitirá configurar o sistema de notificações automáticas para jogos, incluindo:\n\n• Agendamento de notificações\n• Configuração por tipo de jogador\n• Integração com WhatsApp\n• Configuração de grupo de chat',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








