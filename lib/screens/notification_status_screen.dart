import 'package:flutter/material.dart';

class NotificationStatusScreen extends StatelessWidget {
  const NotificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('6️⃣ Status de Notificações'),
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
                  Icons.info,
                  size: 64,
                  color: Colors.teal,
                ),
                SizedBox(height: 16),
                Text(
                  'Status de Notificações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Funcionalidade em desenvolvimento.\n\nEsta tela permitirá visualizar o status das notificações e confirmações, incluindo:\n\n• Status das confirmações por sessão\n• Lista de jogadores confirmados\n• Lista de espera\n• Estatísticas de participação\n• Status das notificações enviadas',
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








