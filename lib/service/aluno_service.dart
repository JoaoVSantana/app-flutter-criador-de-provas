import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/aluno.dart';

class AlunoService {
  final CollectionReference _alunosCollection =
      FirebaseFirestore.instance.collection('alunos');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Aluno>> getAlunosPorTurma(String turmaId) {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _alunosCollection
        .where('turmaID', isEqualTo: turmaId)
        .where('criadoPor', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Aluno.fromFirestore(doc)).toList();
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
      final matriculaExistente =
          (data['matricula'] ?? '').toString().trim().toLowerCase();
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

  Future<void> excluirAluno(String id) async {
    await _alunosCollection.doc(id).delete();
  }
}