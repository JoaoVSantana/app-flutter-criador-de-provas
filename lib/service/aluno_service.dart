import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/aluno.dart';

class AlunoService {
  CollectionReference<Map<String, dynamic>> _col(String turmaId) =>
      FirebaseFirestore.instance
          .collection('turmas')
          .doc(turmaId)
          .collection('alunos');

  Stream<List<Aluno>> getAlunosPorTurma(String turmaId) {
    if (FirebaseAuth.instance.currentUser == null) return Stream.value([]);

    return _col(turmaId).snapshots().map((snapshot) {
      final lista = snapshot.docs.map((d) => Aluno.fromFirestore(d)).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return lista;
    });
  }

  Future<void> adicionarAluno({
    required String turmaId,
    required String nome,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    await _col(turmaId)
        .add({'nome': nome.trim(), 'criadoEm': FieldValue.serverTimestamp()});
  }

  Future<void> renomearAluno({
    required String turmaId,
    required String alunoId,
    required String nome,
  }) {
    return _col(turmaId).doc(alunoId).update({'nome': nome.trim()});
  }

  Future<void> excluirAluno({
    required String turmaId,
    required String alunoId,
  }) {
    return _col(turmaId).doc(alunoId).delete();
  }
}
