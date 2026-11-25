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

  Future<void> adicionarAluno(Aluno aluno) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    final matriculaLimpa = aluno.matricula.trim();
    if (matriculaLimpa.isEmpty) {
      throw Exception('Informe o número de matrícula.');
    }

    final existentes = await _alunosCollection
        .where('criadoPor', isEqualTo: uid)
        .get();

    final duplicada = existentes.docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final matriculaExistente = (data['matricula'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return matriculaExistente == matriculaLimpa.toLowerCase();
    });

    if (duplicada) {
      throw Exception(
        'Já existe um aluno cadastrado com a matrícula "$matriculaLimpa".',
      );
    }

    await _alunosCollection.add({
      'nome': aluno.nome.trim(),
      'email': aluno.email.trim(),
      'matricula': matriculaLimpa,
      'turmaID': aluno.turmaID,
      'criadoPor': uid,
    });
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
