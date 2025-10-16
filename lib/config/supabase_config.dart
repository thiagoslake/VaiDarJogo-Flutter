import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Configurações do Supabase
  static const String supabaseUrl = 'https://ddlxamlaoumhbbrnmasj.supabase.co';

  // Chave anônima (pública) - corrigida para 208 caracteres
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkbHhhbWxhb3VtaGJicm5tYXNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NDAwMzcsImV4cCI6MjA3MjUxNjAzN30.VrTmCTDl0zkzP1GQ8YHAqFLbtCUlaYIp7v_4rUHbSMo';

  // Cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;

  // Inicializar Supabase
  static Future<void> initialize() async {
    try {
      print('🔧 Inicializando Supabase...');
      print('URL: $supabaseUrl');
      print(
          'Chave (primeiros 50 chars): ${supabaseAnonKey.substring(0, 50)}...');
      print('Tamanho da chave: ${supabaseAnonKey.length}');

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      print('✅ Supabase inicializado com sucesso');

      // Testar conexão com uma tabela que existe
      try {
        final testClient = Supabase.instance.client;
        final response =
            await testClient.from('users').select('count').limit(1);
        print('✅ Teste de conexão bem-sucedido: $response');
      } catch (testError) {
        print(
            '⚠️ Teste de conexão falhou, mas Supabase foi inicializado: $testError');
        // Não rethrow aqui, pois o Supabase pode estar funcionando mesmo com erro no teste
      }
    } catch (e) {
      print('❌ Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }

  // Verificar se está inicializado
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      print('⚠️ Supabase não está inicializado: $e');
      return false;
    }
  }

  // Obter usuário atual
  static User? get currentUser => client.auth.currentUser;

  // Verificar se está autenticado
  static bool get isAuthenticated => currentUser != null;

  // Fazer logout
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
