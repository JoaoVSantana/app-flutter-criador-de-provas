import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/turma.dart';

class TurmaService {
  final CollectionReference _turmasCollection =
      FirebaseFirestore.instance.collection('turmas');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Retorna apenas as turmas criadas pelo usuário logado
  Stream<List<Turma>> getTurmas() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _turmasCollection
        .where('criadoPor', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Turma.fromFirestore(doc)).toList();
    });
  }

  Future<void> adicionarTurma(Turma turma) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    await _turmasCollection.add({
      'nome': turma.nome,
      'criadoPor': uid,
    });
  }

  Future<void> excluirTurma(String id) async {
    await _turmasCollection.doc(id).delete();
  }
}