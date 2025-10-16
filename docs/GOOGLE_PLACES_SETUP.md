# 🗺️ Configuração do Google Places API

## 📋 Visão Geral

O VaiDarJogo App agora inclui autocompletar de endereços usando a API do Google Places. Quando o usuário digita o nome de um local, o sistema busca automaticamente opções de endereços e preenche o campo "Endereço Completo".

## 🔧 Configuração Necessária

### 1. **Obter Chave da API do Google Places**

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Vá para **"APIs & Services"** > **"Library"**
4. Procure por **"Places API (New)"** e clique em **"Enable"**
   - ⚠️ **IMPORTANTE**: Use a "Places API (New)", não a versão legada
5. Vá para **"APIs & Services"** > **"Credentials"**
6. Clique em **"Create Credentials"** > **"API Key"**
7. Copie a chave gerada

### 2. **Configurar a Chave no App**

1. Abra o arquivo: `lib/config/google_places_config.dart`
2. Substitua `'YOUR_GOOGLE_PLACES_API_KEY'` pela sua chave real:

```dart
static const String apiKey = 'SUA_CHAVE_AQUI';
```

### 3. **Configurar Restrições de Segurança (Recomendado)**

No Google Cloud Console:
1. Vá para **"APIs & Services"** > **"Credentials"**
2. Clique na sua chave de API
3. Configure restrições:
   - **Application restrictions**: Selecione "HTTP referrers" e adicione seu domínio
   - **API restrictions**: Selecione "Restrict key" e escolha "Places API"

## 💰 Custos e Limites

### **Preços da API (2024)**
- **Autocomplete (per session)**: $0.017 por sessão
- **Place Details**: $0.017 por requisição
- **Text Search**: $0.032 por requisição

### **⚠️ IMPORTANTE: Nova API**
- Use a **"Places API (New)"** no Google Cloud Console
- A API legada foi descontinuada e retorna erro `REQUEST_DENIED`
- A nova API usa endpoints diferentes e estrutura de dados atualizada

### **Limites Gratuitos**
- $200 em créditos gratuitos por mês
- Aproximadamente 11.000 sessões de autocomplete gratuitas

### **Configurar Limites de Faturamento**
1. No Google Cloud Console, vá para **"Billing"**
2. Configure alertas de faturamento
3. Defina limites diários/mensais

## 🚀 Como Funciona

### **Fluxo de Uso**
1. Usuário digita no campo "Local"
2. Sistema busca sugestões na API do Google Places
3. Usuário seleciona uma opção
4. Campo "Endereço Completo" é preenchido automaticamente
5. Coordenadas (lat/lng) são salvas para futuras funcionalidades

### **Fallback sem API**
Se a chave não estiver configurada:
- Campo funciona normalmente (digitação manual)
- Aviso é exibido sobre autocompletar desabilitado
- Todas as funcionalidades continuam funcionando

## 🔒 Segurança

### **⚠️ IMPORTANTE**
- **NUNCA** commite a chave da API no repositório
- Use variáveis de ambiente em produção
- Configure restrições de domínio/IP
- Monitore o uso regularmente

### **Para Produção**
```dart
// Use variáveis de ambiente
static const String apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
```

## 🧪 Testando a Funcionalidade

### **1. Com API Configurada**
1. Vá para "Configuração do Jogo" > "Configurar Jogo"
2. Digite no campo "Local" (ex: "Shopping Iguatemi")
3. Veja as sugestões aparecerem
4. Selecione uma opção
5. Campo "Endereço Completo" será preenchido

### **2. Sem API Configurada**
1. Campo funciona normalmente
2. Aviso laranja é exibido
3. Usuário pode digitar manualmente

## 🐛 Solução de Problemas

### **"Autocompletar desabilitado"**
- Verifique se a chave da API está configurada
- Confirme se a Places API está habilitada
- Verifique se há restrições de domínio

### **"Erro de API"**
- Verifique se a chave é válida
- Confirme se a Places API está habilitada
- Verifique limites de faturamento

### **"Nenhuma sugestão aparece"**
- Verifique conexão com internet
- Confirme se a API está funcionando
- Teste com termos mais específicos

## 📱 Funcionalidades Futuras

Com as coordenadas salvas, futuras funcionalidades podem incluir:
- Mapa interativo do local
- Cálculo de distância entre jogadores
- Navegação GPS
- Análise de localização dos jogos

## 🎯 Benefícios

- ✅ **UX Melhorada**: Autocompletar intuitivo
- ✅ **Dados Precisos**: Endereços padronizados
- ✅ **Coordenadas**: Preparado para mapas
- ✅ **Fallback**: Funciona sem API
- ✅ **Segurança**: Configuração flexível

---

**🎉 Configuração concluída!** O autocompletar de endereços está pronto para uso!
