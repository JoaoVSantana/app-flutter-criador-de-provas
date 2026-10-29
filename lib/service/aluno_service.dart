import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aluno.dart';

class AlunoService {
  final CollectionReference _alunosCollection =
      FirebaseFirestore.instance.collection('alunos');

  // Retorna stream de alunos pertencentes a uma turma específica
  Stream<List<Aluno>> getAlunosPorTurma(String turmaId) {
    return _alunosCollection
        .where('turmaID', isEqualTo: turmaId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Aluno.fromFirestore(doc)).toList();
    });
  }

  Future<void> adicionarAluno(Aluno aluno) async {
    await _alunosCollection.add(aluno.toMap());
  }

  Future<void> excluirAluno(String id) async {
    await _alunosCollection.doc(id).delete();
  }
}