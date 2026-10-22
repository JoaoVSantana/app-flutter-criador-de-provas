//opcoes de mensagem de erro que podem ser retornadas pelo FirebaseAuthException
String traduzirErro(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'Já existe um usuário com esse e-mail.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'weak-password':
      return 'Senha fraca. Use pelo menos 6 caracteres.';
    case 'operation-not-allowed':
      return 'Login por e-mail/senha não está ativado no Firebase.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    default:
      return 'Erro ao cadastrar ($code).';
  }
}
