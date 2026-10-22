class Usuario {
  final String uid;
  final String nome;
  final String sobrenome;
  final String cpf;
  final String email;

  const Usuario({
    required this.uid,
    required this.nome,
    required this.sobrenome,
    required this.cpf,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {'nome': nome, 'sobrenome': sobrenome, 'cpf': cpf, 'email': email};
  }

  // Map -> Objeto (para ler do Firestore)
  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      uid: uid,
      nome: map['nome'] ?? '',
      sobrenome: map['sobrenome'] ?? '',
      cpf: map['cpf'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
