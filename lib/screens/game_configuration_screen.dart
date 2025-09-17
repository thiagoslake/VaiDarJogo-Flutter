import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'view_game_screen.dart';
import 'upcoming_sessions_screen.dart';
import 'edit_game_screen.dart';
import 'notification_config_screen.dart';
import 'notification_status_screen.dart';
import '../providers/selected_game_provider.dart';
import '../providers/auth_provider.dart';

class GameConfigurationScreen extends ConsumerWidget {
  const GameConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚽ Configuração do Jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.settings,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Configuração do Jogo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie todas as configurações dos seus jogos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (currentUser != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '👤 ${currentUser.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                    if (selectedGame != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '⚽ ${selectedGame.organizationName} - ${selectedGame.location}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botões das funcionalidades
            _buildMenuButton(
              context,
              title: '1️⃣ Visualizar Jogo',
              subtitle: 'Ver características do jogo cadastrado',
              icon: Icons.visibility,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ViewGameScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildMenuButton(
              context,
              title: '2️⃣ Próximas Sessões',
              subtitle: 'Ver próximos jogos agendados',
              icon: Icons.schedule,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UpcomingSessionsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildMenuButton(
              context,
              title: '3️⃣ Alterar Jogo',
              subtitle: 'Modificar configurações existentes do jogo',
              icon: Icons.edit,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditGameScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildMenuButton(
              context,
              title: '4️⃣ Configurar Notificações',
              subtitle: 'Configurar sistema de notificações para jogos',
              icon: Icons.notifications,
              color: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationConfigScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildMenuButton(
              context,
              title: '5️⃣ Status de Notificações',
              subtitle: 'Ver status das confirmações e lista de espera',
              icon: Icons.info,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationStatusScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
