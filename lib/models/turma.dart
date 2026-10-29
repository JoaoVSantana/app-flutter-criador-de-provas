import 'package:cloud_firestore/cloud_firestore.dart';

class Turma {
  final String id;
  final String nome;
  final String criadoPor;

  Turma({
    required this.id,
    required this.nome,
    required this.criadoPor,
  });

  factory Turma.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Turma(
      id: doc.id,
      nome: data['nome'] ?? '',
      criadoPor: data['criadoPor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'criadoPor': criadoPor,
    };
  }
}