import 'package:cloud_firestore/cloud_firestore.dart';

class Aluno {
  final String id;
  final String nome;
  final String email;
  final String matricula;
  final String turmaID;
  final String criadoPor;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    required this.matricula,
    required this.turmaID,
    required this.criadoPor,
  });

  factory Aluno.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Aluno(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      matricula: data['matricula'] ?? '',
      turmaID: data['turmaID'] ?? '',
      criadoPor: data['criadoPor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'matricula': matricula,
      'turmaID': turmaID,
      'criadoPor': criadoPor,
    };
  }
}
