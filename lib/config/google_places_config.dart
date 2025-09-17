class GooglePlacesConfig {
  // ⚠️ IMPORTANTE: Substitua pela sua chave da API do Google Places
  // Para obter uma chave:
  // 1. Acesse https://console.cloud.google.com/
  // 2. Crie um projeto ou selecione um existente
  // 3. Habilite a "Places API"
  // 4. Crie uma chave de API
  // 5. Substitua o valor abaixo

  static const String apiKey = 'AIzaSyBxkkItvWPUE5NZ2Vjq6XHckZ3q8fQvn8U';

  /// Verifica se a chave da API está configurada
  static bool get isConfigured {
    return apiKey != 'YOUR_GOOGLE_PLACES_API_KEY' && apiKey.isNotEmpty;
  }

  /// Retorna instruções para configurar a chave da API
  static String get setupInstructions {
    return '''
🔧 CONFIGURAÇÃO DA API DO GOOGLE PLACES

Para ativar o autocompletar de endereços:

1. Acesse: https://console.cloud.google.com/
2. Crie um novo projeto ou selecione um existente
3. Vá para "APIs & Services" > "Library"
4. Procure por "Places API" e habilite
5. Vá para "APIs & Services" > "Credentials"
6. Clique em "Create Credentials" > "API Key"
7. Copie a chave gerada
8. Substitua 'YOUR_GOOGLE_PLACES_API_KEY' no arquivo:
   lib/config/google_places_config.dart

⚠️ SEGURANÇA:
- Nunca commite a chave da API no repositório
- Configure restrições na chave (IP, referrer, etc.)
- Use variáveis de ambiente em produção

💰 CUSTOS:
- A API do Google Places tem custos por uso
- Configure limites de faturamento
- Monitore o uso regularmente
''';
  }
}
