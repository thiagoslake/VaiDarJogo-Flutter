import 'package:flutter/material.dart';
import 'logger.dart';

/// Utilitário para tratamento centralizado de erros
///
/// Este utilitário fornece métodos para capturar, logar e exibir
/// erros de forma consistente em todo o aplicativo.
class ErrorHandler {
  /// Tratar erro genérico
  static void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? operation,
    bool showToUser = false,
    BuildContext? buildContext,
  }) {
    // Log do erro
    Logger.error(
      'Error in ${operation ?? 'unknown operation'}${context != null ? ' ($context)' : ''}: $error',
      tag: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // Exibir para o usuário se solicitado
    if (showToUser && buildContext != null) {
      _showErrorSnackBar(buildContext, _getUserFriendlyMessage(error));
    }
  }

  /// Tratar erro de rede
  static void handleNetworkError(
    dynamic error, {
    StackTrace? stackTrace,
    String? url,
    String? method,
    BuildContext? buildContext,
  }) {
    Logger.error(
      'Network error: $method $url - $error',
      tag: 'NetworkError',
      error: error,
      stackTrace: stackTrace,
    );

    if (buildContext != null) {
      _showErrorSnackBar(
          buildContext, 'Erro de conexão. Verifique sua internet.');
    }
  }

  /// Tratar erro de autenticação
  static void handleAuthError(
    dynamic error, {
    StackTrace? stackTrace,
    String? operation,
    BuildContext? buildContext,
  }) {
    Logger.error(
      'Auth error in $operation: $error',
      tag: 'AuthError',
      error: error,
      stackTrace: stackTrace,
    );

    if (buildContext != null) {
      _showErrorSnackBar(
          buildContext, 'Erro de autenticação. Tente fazer login novamente.');
    }
  }

  /// Tratar erro de banco de dados
  static void handleDatabaseError(
    dynamic error, {
    StackTrace? stackTrace,
    String? operation,
    String? table,
    BuildContext? buildContext,
  }) {
    Logger.error(
      'Database error in $operation${table != null ? ' on $table' : ''}: $error',
      tag: 'DatabaseError',
      error: error,
      stackTrace: stackTrace,
    );

    if (buildContext != null) {
      _showErrorSnackBar(
          buildContext, 'Erro interno. Tente novamente em alguns instantes.');
    }
  }

  /// Tratar erro de validação
  static void handleValidationError(
    String message, {
    BuildContext? buildContext,
  }) {
    Logger.warning(
      'Validation error: $message',
      tag: 'ValidationError',
    );

    if (buildContext != null) {
      _showErrorSnackBar(buildContext, message);
    }
  }

  /// Tratar erro de permissão
  static void handlePermissionError(
    String permission, {
    BuildContext? buildContext,
  }) {
    Logger.warning(
      'Permission error: $permission',
      tag: 'PermissionError',
    );

    if (buildContext != null) {
      _showErrorSnackBar(buildContext, 'Permissão necessária: $permission');
    }
  }

  /// Exibir snackbar de erro
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Verificar se é erro de telefone duplicado
  static bool isPhoneDuplicateError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('phone') &&
        (errorString.contains('duplicate') || errorString.contains('unique'));
  }

  /// Obter mensagem amigável de erro
  static String getFriendlyErrorMessage(dynamic error) {
    return _getUserFriendlyMessage(error);
  }

  /// Converter erro técnico em mensagem amigável
  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    }

    if (errorString.contains('timeout')) {
      return 'Tempo limite excedido. Tente novamente.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'Acesso negado. Faça login novamente.';
    }

    if (errorString.contains('not found')) {
      return 'Recurso não encontrado.';
    }

    if (errorString.contains('server') || errorString.contains('internal')) {
      return 'Erro interno do servidor. Tente novamente.';
    }

    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'Dados inválidos. Verifique as informações.';
    }

    // Mensagem genérica
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  /// Wrapper para operações assíncronas com tratamento de erro
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    BuildContext? buildContext,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        operation: operationName,
        buildContext: buildContext,
      );
      return fallbackValue;
    }
  }

  /// Wrapper para operações síncronas com tratamento de erro
  static T? safeSync<T>(
    T Function() operation, {
    String? context,
    String? operationName,
    BuildContext? buildContext,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        operation: operationName,
        buildContext: buildContext,
      );
      return fallbackValue;
    }
  }
}
