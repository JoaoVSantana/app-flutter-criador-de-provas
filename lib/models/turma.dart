import 'package:cloud_firestore/cloud_firestore.dart';

class Turma {
  final String id;
  final String nome;

  Turma({
    required this.id,
    required this.nome,
  });

  factory Turma.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Turma(
      id: doc.id,
      nome: data['nome'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
    };
  }
}