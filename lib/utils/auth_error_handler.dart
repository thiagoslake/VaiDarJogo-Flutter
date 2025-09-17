import 'package:supabase_flutter/supabase_flutter.dart';
import 'friendly_auth_exception.dart';

class AuthErrorHandler {
  /// Converte erros de autenticação em mensagens amigáveis
  static String getFriendlyErrorMessage(dynamic error) {
    // Debug temporário para diagnosticar o problema
    print('🔍 DEBUG - Tipo de erro: ${error.runtimeType}');
    print('🔍 DEBUG - Erro toString: ${error.toString()}');

    // Se já é uma exceção amigável, retornar a mensagem diretamente
    if (error is FriendlyAuthException) {
      print(
          '🔍 DEBUG - É FriendlyAuthException, retornando mensagem diretamente');
      return error.message;
    }

    if (error is AuthException) {
      print('🔍 DEBUG - É AuthException, message: ${error.message}');
      switch (error.message) {
        case 'Invalid login credentials':
        case 'invalid_credentials':
        case 'Invalid credentials':
          print('🔍 DEBUG - AuthException com credenciais inválidas');
          return 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.';
        case 'Email not confirmed':
          return 'Seu email ainda não foi confirmado. Verifique sua caixa de entrada e clique no link de confirmação.';
        case 'Too many requests':
          return 'Muitas tentativas de login. Aguarde alguns minutos antes de tentar novamente.';
        case 'User not found':
          return 'Usuário não encontrado. Verifique se o email está correto ou crie uma nova conta.';
        case 'Invalid email':
          return 'Email inválido. Verifique se o formato está correto.';
        case 'Password should be at least 6 characters':
          return 'A senha deve ter pelo menos 6 caracteres.';
        case 'Unable to validate email address: invalid format':
          return 'Formato de email inválido. Verifique se o email está correto.';
        case 'Signup is disabled':
          return 'O cadastro está temporariamente desabilitado. Tente novamente mais tarde.';
        case 'Email address is already registered':
          return 'Este email já está cadastrado. Tente fazer login ou use outro email.';
        case 'Email address "joao@gmail.com" is invalid':
        case 'Email address is invalid':
          return 'Email inválido. Verifique se o formato está correto e tente novamente.';
        default:
          return 'Erro de autenticação: ${error.message}';
      }
    }

    if (error is Exception) {
      final errorString = error.toString();
      print('🔍 DEBUG - É Exception, errorString: $errorString');

      if (errorString.contains('Invalid login credentials') ||
          errorString.contains('invalid_credentials') ||
          errorString.contains('Invalid credentials')) {
        print('🔍 DEBUG - Contém credenciais inválidas');
        return 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.';
      }

      if (errorString.contains('email_not_confirmed')) {
        return 'Seu email ainda não foi confirmado. Verifique sua caixa de entrada e clique no link de confirmação.';
      }

      if (errorString.contains('Too many requests')) {
        return 'Muitas tentativas de login. Aguarde alguns minutos antes de tentar novamente.';
      }

      if (errorString.contains('User not found')) {
        return 'Usuário não encontrado. Verifique se o email está correto ou crie uma nova conta.';
      }

      if (errorString.contains('Invalid email')) {
        return 'Email inválido. Verifique se o formato está correto.';
      }

      if (errorString.contains('Password should be at least 6 characters')) {
        return 'A senha deve ter pelo menos 6 caracteres.';
      }

      if (errorString.contains('Unable to validate email address')) {
        return 'Formato de email inválido. Verifique se o email está correto.';
      }

      if (errorString.contains('Signup is disabled')) {
        return 'O cadastro está temporariamente desabilitado. Tente novamente mais tarde.';
      }

      if (errorString.contains('Email address is already registered')) {
        return 'Este email já está cadastrado. Tente fazer login ou use outro email.';
      }

      if (errorString.contains('Email address') &&
          errorString.contains('is invalid')) {
        return 'Email inválido. Verifique se o formato está correto e tente novamente.';
      }

      if (errorString.contains('Network error') ||
          errorString.contains('Connection')) {
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
      }

      if (errorString.contains('Timeout')) {
        return 'Tempo limite excedido. Verifique sua conexão e tente novamente.';
      }

      // Verificar se é um AuthApiException específico
      if (errorString.contains('AuthApiException')) {
        if (errorString.contains('invalid_credentials')) {
          return 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.';
        }
      }
    }

    // Se não conseguir identificar o erro, retorna uma mensagem genérica
    print('🔍 DEBUG - Chegou na mensagem genérica');
    return 'Ocorreu um erro inesperado. Tente novamente em alguns instantes.';
  }

  /// Verifica se o erro é relacionado a credenciais inválidas
  static bool isInvalidCredentialsError(dynamic error) {
    if (error is AuthException) {
      return error.message == 'Invalid login credentials';
    }

    if (error is Exception) {
      return error.toString().contains('Invalid login credentials');
    }

    return false;
  }

  /// Verifica se o erro é relacionado a email não confirmado
  static bool isEmailNotConfirmedError(dynamic error) {
    if (error is AuthException) {
      return error.message == 'Email not confirmed';
    }

    if (error is Exception) {
      return error.toString().contains('email_not_confirmed');
    }

    return false;
  }

  /// Verifica se o erro é relacionado a muitas tentativas
  static bool isTooManyRequestsError(dynamic error) {
    if (error is AuthException) {
      return error.message == 'Too many requests';
    }

    if (error is Exception) {
      return error.toString().contains('Too many requests');
    }

    return false;
  }

  /// Verifica se o erro é relacionado a problemas de rede
  static bool isNetworkError(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();
      return errorString.contains('Network error') ||
          errorString.contains('Connection') ||
          errorString.contains('Timeout');
    }

    return false;
  }
}
