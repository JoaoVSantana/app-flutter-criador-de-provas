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

    await _alunosCollection.add({
      'nome': aluno.nome,
      'email': aluno.email,
      'turmaID': aluno.turmaID,
      'criadoPor': uid,
    });
  }

  Future<void> excluirAluno(String id) async {
    await _alunosCollection.doc(id).delete();
  }
}