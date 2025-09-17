import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'screens/user_dashboard_screen.dart';
import 'widgets/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar tratamento de erros para suprimir logs automáticos em modo release
  if (kReleaseMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Em modo release, não logar erros automaticamente
      // Apenas logar erros críticos
      if (details.exception.toString().contains('AuthApiException') ||
          details.exception.toString().contains('AuthException')) {
        // Suprimir erros de autenticação para evitar poluir o console
        return;
      }
      // Logar outros erros normalmente
      FlutterError.presentError(details);
    };
  }

  print('🚀 Iniciando VaiDarJogo App...');

  try {
    // Inicializar Supabase
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado com sucesso!');
  } catch (e) {
    print('❌ Erro ao inicializar Supabase: $e');
    // Continuar mesmo com erro para debug
  }

  runApp(const ProviderScope(child: VaiDarJogoApp()));
}

class VaiDarJogoApp extends StatelessWidget {
  const VaiDarJogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaiDarJogo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const AuthGuard(
        child: UserDashboardScreen(),
      ),
    );
  }
}
