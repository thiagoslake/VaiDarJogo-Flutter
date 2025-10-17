# 📋 Sistema de Confirmação de Presença - VaiDarJogo

## 🎯 **Visão Geral**

O sistema de confirmação de presença permite que administradores de jogos configurem e gerenciem confirmações de presença dos jogadores de forma automatizada e manual.

## 🏗️ **Arquitetura do Sistema**

### **Estrutura de Banco de Dados**

```sql
-- 1. Configurações de confirmação por jogo
game_confirmation_configs
├── id (uuid, PK)
├── game_id (uuid, FK → games.id)
├── is_active (boolean)
├── created_at (timestamp)
└── updated_at (timestamp)

-- 2. Configurações de envio por tipo de jogador
confirmation_send_configs
├── id (uuid, PK)
├── game_confirmation_config_id (uuid, FK)
├── player_type (text: 'monthly' | 'casual')
├── confirmation_order (integer: 1, 2, 3...)
├── hours_before_game (integer: 24, 12, 6...)
├── is_active (boolean)
├── created_at (timestamp)
└── updated_at (timestamp)

-- 3. Confirmações realizadas pelos jogadores
player_confirmations
├── id (uuid, PK)
├── game_id (uuid, FK → games.id)
├── player_id (uuid, FK → players.id)
├── confirmation_type (text: 'confirmed' | 'declined' | 'pending')
├── confirmed_at (timestamp)
├── confirmation_method (text: 'whatsapp' | 'manual' | 'app')
├── notes (text)
├── created_at (timestamp)
└── updated_at (timestamp)

-- 4. Logs de envio de confirmações
confirmation_send_logs
├── id (uuid, PK)
├── game_id (uuid, FK → games.id)
├── player_id (uuid, FK → players.id)
├── send_config_id (uuid, FK)
├── scheduled_for (timestamp)
├── sent_at (timestamp)
├── status (text: 'pending' | 'sent' | 'failed' | 'cancelled')
├── error_message (text)
├── channel (text: 'whatsapp' | 'email' | 'push')
├── message_content (text)
├── created_at (timestamp)
└── updated_at (timestamp)
```

### **Modelos Dart**

- `GameConfirmationConfig` - Configuração principal do jogo
- `ConfirmationSendConfig` - Configuração de envio por tipo de jogador
- `PlayerConfirmation` - Confirmação individual do jogador
- `ConfirmationSendLog` - Log de envio de confirmação
- `ConfirmationConfigComplete` - Configuração completa com validações

### **Serviços**

- `GameConfirmationConfigService` - Gerencia configurações de confirmação
- `PlayerConfirmationService` - Gerencia confirmações dos jogadores
- `ConfirmationSendLogService` - Gerencia logs de envio

## 🚀 **Funcionalidades Implementadas**

### **1. Configuração de Confirmação de Presença**

**Localização:** `GameDetailsScreen` → "Configurar Confirmação de Presença"

**Funcionalidades:**
- ✅ Configurar múltiplas confirmações por tipo de jogador
- ✅ Definir horários diferentes para mensalistas e avulsos
- ✅ Validação: mensalistas devem ter horários anteriores aos avulsos
- ✅ Interface intuitiva com adição/remoção de configurações
- ✅ Salvamento automático com feedback visual

**Exemplo de Configuração:**
```
Mensalistas:
├── 1ª confirmação: 48h antes do jogo
└── 2ª confirmação: 24h antes do jogo

Avulsos:
├── 1ª confirmação: 24h antes do jogo
└── 2ª confirmação: 12h antes do jogo
```

### **2. Confirmação Manual de Jogadores**

**Localização:** `GameDetailsScreen` → "Confirmação Manual de Jogadores"

**Funcionalidades:**
- ✅ Lista todos os jogadores do jogo com status de confirmação
- ✅ Confirmar/declinar presença individualmente
- ✅ Adicionar observações para cada confirmação
- ✅ Resetar confirmações para "pendente"
- ✅ Visualização clara do status (confirmado/declinado/pendente)
- ✅ Separação por tipo de jogador (mensal/avulso)

### **3. Integração com Tela de Detalhes do Jogo**

**Localização:** `GameDetailsScreen`

**Funcionalidades:**
- ✅ Acesso rápido às configurações de confirmação
- ✅ Acesso rápido à confirmação manual
- ✅ Disponível apenas para administradores do jogo
- ✅ Integração com sistema de notificações existente

## 📱 **Como Usar**

### **Passo 1: Configurar Confirmação de Presença**

1. Acesse o jogo desejado
2. Vá em "Configurar Confirmação de Presença"
3. Configure os horários para mensalistas e avulsos
4. Salve as configurações

### **Passo 2: Confirmar Presença dos Jogadores**

1. Acesse "Confirmação Manual de Jogadores"
2. Visualize a lista de jogadores
3. Confirme ou decline a presença de cada jogador
4. Adicione observações se necessário

### **Passo 3: Monitorar Confirmações**

1. Use a tela de confirmação manual para ver o status
2. Verifique logs de envio (quando implementado)
3. Ajuste configurações conforme necessário

## 🔧 **Validações Implementadas**

### **Validações de Configuração**

```dart
bool _validateConfigurations() {
  // 1. Verificar se há pelo menos uma configuração para cada tipo
  if (_monthlyConfigs.isEmpty || _casualConfigs.isEmpty) {
    return false;
  }

  // 2. Verificar se as horas dos mensalistas são maiores que as dos avulsos
  final monthlyMaxHours = _monthlyConfigs
      .map((config) => config.hoursBeforeGame)
      .reduce((a, b) => a > b ? a : b);
  
  final casualMinHours = _casualConfigs
      .map((config) => config.hoursBeforeGame)
      .reduce((a, b) => a < b ? a : b);

  return monthlyMaxHours > casualMinHours;
}
```

### **Validações de Banco de Dados**

```sql
-- Constraints de integridade
ALTER TABLE confirmation_send_configs 
ADD CONSTRAINT check_player_type 
CHECK (player_type IN ('monthly', 'casual'));

ALTER TABLE confirmation_send_configs 
ADD CONSTRAINT check_hours_positive 
CHECK (hours_before_game > 0);

ALTER TABLE player_confirmations 
ADD CONSTRAINT check_confirmation_type 
CHECK (confirmation_type IN ('confirmed', 'declined', 'pending'));

-- Índices para performance
CREATE INDEX idx_player_confirmations_game_player 
ON player_confirmations(game_id, player_id);

CREATE INDEX idx_confirmation_send_logs_scheduled 
ON confirmation_send_logs(scheduled_for);
```

### **Validações de Segurança (RLS)**

```sql
-- Políticas de segurança
CREATE POLICY "Users can view their own confirmations" ON player_confirmations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM players p 
            WHERE p.id = player_confirmations.player_id 
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage game confirmation configs" ON game_confirmation_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = game_confirmation_configs.game_id 
            AND p.user_id = auth.uid()
            AND gp.is_admin = true
        )
    );
```

## 🧪 **Testes Recomendados**

### **Testes de Configuração**

```dart
// Teste 1: Configuração válida
test('should create valid confirmation config', () async {
  final monthlyConfigs = [
    ConfirmationSendConfig(/* 48h */),
    ConfirmationSendConfig(/* 24h */),
  ];
  final casualConfigs = [
    ConfirmationSendConfig(/* 24h */),
    ConfirmationSendConfig(/* 12h */),
  ];
  
  final result = await GameConfirmationConfigService.createGameConfirmationConfig(
    gameId: 'test-game-id',
    monthlyConfigs: monthlyConfigs,
    casualConfigs: casualConfigs,
  );
  
  expect(result, isNotNull);
  expect(result!.isValid(), isTrue);
});

// Teste 2: Configuração inválida
test('should reject invalid confirmation config', () async {
  final monthlyConfigs = [
    ConfirmationSendConfig(/* 12h */), // Menor que avulsos
  ];
  final casualConfigs = [
    ConfirmationSendConfig(/* 24h */),
  ];
  
  final result = await GameConfirmationConfigService.createGameConfirmationConfig(
    gameId: 'test-game-id',
    monthlyConfigs: monthlyConfigs,
    casualConfigs: casualConfigs,
  );
  
  expect(result, isNull);
});
```

### **Testes de Confirmação**

```dart
// Teste 3: Confirmar presença
test('should confirm player presence', () async {
  final confirmation = await PlayerConfirmationService.confirmPlayerPresence(
    gameId: 'test-game-id',
    playerId: 'test-player-id',
    notes: 'Confirmado via teste',
  );
  
  expect(confirmation, isNotNull);
  expect(confirmation!.confirmationType, equals('confirmed'));
  expect(confirmation.confirmationMethod, equals('manual'));
});

// Teste 4: Obter estatísticas
test('should get confirmation stats', () async {
  final stats = await PlayerConfirmationService.getGameConfirmationStats('test-game-id');
  
  expect(stats['total'], greaterThan(0));
  expect(stats['confirmation_rate'], inInclusiveRange(0, 100));
});
```

## 🔄 **Próximos Passos (Futuras Implementações)**

### **1. Sistema de Envio Automático**

```dart
// Implementar serviço de envio automático
class ConfirmationSchedulerService {
  static Future<void> scheduleConfirmations(String gameId) async {
    // 1. Buscar configurações do jogo
    // 2. Calcular horários de envio
    // 3. Criar logs de envio
    // 4. Integrar com sistema de notificações
  }
}
```

### **2. Integração com WhatsApp**

```dart
// Integrar com WhatsApp Business API
class WhatsAppConfirmationService {
  static Future<bool> sendConfirmationMessage({
    required String phoneNumber,
    required String playerName,
    required String gameName,
    required DateTime gameDate,
  }) async {
    // Implementar envio via WhatsApp
  }
}
```

### **3. Dashboard de Confirmações**

```dart
// Tela de dashboard para administradores
class ConfirmationDashboardScreen extends StatelessWidget {
  // Mostrar estatísticas em tempo real
  // Gráficos de confirmação
  // Histórico de envios
}
```

## 📊 **Métricas e Monitoramento**

### **Métricas Disponíveis**

- **Taxa de Confirmação:** `(confirmados / total) * 100`
- **Tempo Médio de Resposta:** Tempo entre envio e confirmação
- **Canal de Confirmação:** WhatsApp, manual, app
- **Status de Envio:** Pendente, enviado, falhou, cancelado

### **Logs de Auditoria**

```sql
-- Consulta para auditoria
SELECT 
    pc.game_id,
    p.name as player_name,
    pc.confirmation_type,
    pc.confirmed_at,
    pc.confirmation_method,
    pc.notes
FROM player_confirmations pc
JOIN players p ON pc.player_id = p.id
WHERE pc.game_id = 'game-id'
ORDER BY pc.confirmed_at DESC;
```

## 🚨 **Tratamento de Erros**

### **Erros Comuns e Soluções**

1. **Configuração Inválida**
   - **Erro:** "Mensalistas devem ter horários anteriores aos avulsos"
   - **Solução:** Ajustar horários na configuração

2. **Jogador Não Encontrado**
   - **Erro:** "Jogador não encontrado"
   - **Solução:** Verificar se o jogador está cadastrado no jogo

3. **Permissão Negada**
   - **Erro:** "Acesso negado"
   - **Solução:** Verificar se o usuário é administrador do jogo

### **Logs de Erro**

```dart
// Exemplo de tratamento de erro
try {
  final result = await PlayerConfirmationService.confirmPlayerPresence(
    gameId: gameId,
    playerId: playerId,
  );
} catch (e) {
  print('❌ Erro ao confirmar presença: $e');
  // Log para sistema de monitoramento
  await ErrorLogService.logError(
    error: e.toString(),
    context: 'PlayerConfirmationService.confirmPlayerPresence',
    userId: currentUser.id,
  );
}
```

## 📚 **Documentação de API**

### **Endpoints Principais**

```dart
// Configurações
GET    /game-confirmation-configs/{gameId}
POST   /game-confirmation-configs
PUT    /game-confirmation-configs/{gameId}
DELETE /game-confirmation-configs/{gameId}

// Confirmações
GET    /player-confirmations/{gameId}
POST   /player-confirmations
PUT    /player-confirmations/{id}
DELETE /player-confirmations/{id}

// Logs
GET    /confirmation-send-logs/{gameId}
POST   /confirmation-send-logs
PUT    /confirmation-send-logs/{id}
```

## 🎉 **Conclusão**

O sistema de confirmação de presença está implementado e pronto para uso! 

**Funcionalidades Ativas:**
- ✅ Configuração de confirmação por tipo de jogador
- ✅ Confirmação manual de jogadores
- ✅ Validações de segurança e integridade
- ✅ Interface intuitiva e responsiva
- ✅ Integração com sistema existente

**Próximas Implementações:**
- 🔄 Sistema de envio automático
- 🔄 Integração com WhatsApp
- 🔄 Dashboard de métricas
- 🔄 Notificações push

Para dúvidas ou sugestões, consulte a documentação técnica ou entre em contato com a equipe de desenvolvimento.
