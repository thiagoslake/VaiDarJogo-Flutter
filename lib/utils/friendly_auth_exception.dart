/// Exceção personalizada para erros de autenticação com mensagem amigável
class FriendlyAuthException implements Exception {
  final String message;

  const FriendlyAuthException(this.message);

  @override
  String toString() => message;
}
