import 'dart:developer' as developer;

/// Utilitário de logging para o aplicativo VaiDarJogo
///
/// Este utilitário fornece métodos centralizados para logging
/// com diferentes níveis de severidade e formatação consistente.
class Logger {
  static const String _appName = 'VaiDarJogo';

  /// Log de debug - apenas para desenvolvimento
  static void debug(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_isDebugMode()) {
      developer.log(
        message,
        name: '$_appName${tag != null ? ':$tag' : ''}',
        level: 500, // DEBUG level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log de informação - eventos importantes
  static void info(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: 800, // INFO level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de warning - situações que merecem atenção
  static void warning(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: 900, // WARNING level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de erro - erros que precisam ser investigados
  static void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de erro crítico - erros que impedem o funcionamento
  static void critical(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: 1200, // CRITICAL level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Verificar se está em modo debug
  static bool _isDebugMode() {
    // Em produção, isso pode ser controlado por uma variável de ambiente
    // Por enquanto, sempre retorna true para desenvolvimento
    return true;
  }

  /// Log de performance - para medir tempo de execução
  static void performance(String operation, Duration duration, {String? tag}) {
    debug(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag: tag ?? 'Performance',
    );
  }

  /// Log de rede - para requisições HTTP
  static void network(String method, String url,
      {int? statusCode, String? tag}) {
    final status = statusCode != null ? ' ($statusCode)' : '';
    info(
      'Network: $method $url$status',
      tag: tag ?? 'Network',
    );
  }

  /// Log de banco de dados - para operações SQL
  static void database(String operation, {String? table, String? tag}) {
    final tableInfo = table != null ? ' on $table' : '';
    debug(
      'Database: $operation$tableInfo',
      tag: tag ?? 'Database',
    );
  }

  /// Log de autenticação - para operações de login/logout
  static void auth(String operation, {String? userId, String? tag}) {
    final userInfo = userId != null ? ' for user $userId' : '';
    info(
      'Auth: $operation$userInfo',
      tag: tag ?? 'Auth',
    );
  }

  /// Log de UI - para eventos de interface
  static void ui(String event, {String? screen, String? tag}) {
    final screenInfo = screen != null ? ' on $screen' : '';
    debug(
      'UI: $event$screenInfo',
      tag: tag ?? 'UI',
    );
  }
}
