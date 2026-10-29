import 'package:cloud_firestore/cloud_firestore.dart';

class Aluno {
  final String id;
  final String nome;
  final String email;
  final String turmaID;
  final String criadoPor;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    required this.turmaID,
    required this.criadoPor,
  });

  factory Aluno.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Aluno(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      turmaID: data['turmaID'] ?? '',
      criadoPor: data['criadoPor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'turmaID': turmaID,
      'criadoPor': criadoPor,
    };
  }
}