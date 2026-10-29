import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turma.dart';

class TurmaService {
  final CollectionReference _turmasCollection =
      FirebaseFirestore.instance.collection('turmas');

  Stream<List<Turma>> getTurmas() {
    return _turmasCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Turma.fromFirestore(doc)).toList();
    });
  }

  Future<void> adicionarTurma(Turma turma) async {
    await _turmasCollection.add(turma.toMap());
  }

  Future<void> excluirTurma(String id) async {
    await _turmasCollection.doc(id).delete();
  }
}