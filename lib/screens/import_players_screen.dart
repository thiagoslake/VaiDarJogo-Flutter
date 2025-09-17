import 'package:flutter/material.dart';

class ImportPlayersScreen extends StatelessWidget {
  const ImportPlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3️⃣ Importar Jogadores'),
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
                  Icons.upload_file,
                  size: 64,
                  color: Colors.purple,
                ),
                SizedBox(height: 16),
                Text(
                  'Importar Jogadores',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Funcionalidade em desenvolvimento.\n\nEsta tela permitirá importar jogadores de arquivos Excel, incluindo:\n\n• Importação de arquivos Excel\n• Processamento de dados em lote\n• Validação de dados importados\n• Detecção de duplicatas\n• Relatório de importação\n• Associação automática com jogos',
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








