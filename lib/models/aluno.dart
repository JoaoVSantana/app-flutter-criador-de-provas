import 'package:cloud_firestore/cloud_firestore.dart';

class Aluno {
  final String id;
  final String nome;
  final String turmaID; // vem do caminho: turmas/{turmaID}/alunos/{id}

  const Aluno({required this.id, required this.nome, required this.turmaID});

  factory Aluno.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Aluno(
      id: doc.id,
      nome: data['nome'] ?? '',
      turmaID: doc.reference.parent.parent?.id ?? '',
    );
  }
}
