import 'package:flutter/material.dart';

class GroupMappingScreen extends StatelessWidget {
  const GroupMappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2️⃣ Mapear Grupo'),
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
                  Icons.group,
                  size: 64,
                  color: Colors.blue,
                ),
                SizedBox(height: 16),
                Text(
                  'Mapear Grupo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Funcionalidade em desenvolvimento.\n\nEsta tela permitirá mapear e importar jogadores de um grupo do WhatsApp, incluindo:\n\n• Mapeamento de grupos do WhatsApp\n• Integração com API do WhatsApp\n• Identificação automática de membros\n• Relatório de mapeamento\n• Confirmação antes da importação',
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








