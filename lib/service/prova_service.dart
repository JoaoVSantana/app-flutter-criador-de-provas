import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/prova.dart';

class ProvaService {
  final CollectionReference _provasCollection = FirebaseFirestore.instance
      .collection('provas');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Prova>> getProvas() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _provasCollection
        .where('professorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();
          docs.sort((a, b) {
            final ma = a.data() as Map<String, dynamic>?;
            final mb = b.data() as Map<String, dynamic>?;
            final ta = ma?['criadoEm'] as Timestamp?;
            final tb = mb?['criadoEm'] as Timestamp?;
            if (ta == null && tb == null) return 0;
            if (ta == null) return -1;
            if (tb == null) return 1;
            return tb.compareTo(ta);
          });
          return docs.map((doc) => Prova.fromFirestore(doc)).toList();
        });
  }

  Future<void> criarProva(Prova prova) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    await _provasCollection.add({
      ...prova.copyWith(professorId: uid).toMap(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarTurmasDaProva({
    required String provaId,
    required List<String> turmasIds,
    required List<String> turmasNomes,
  }) async {
    await _provasCollection.doc(provaId).update({
      'turmasIds': turmasIds,
      'turmasNomes': turmasNomes,
    });
  }

  Future<void> excluirProva(String id) async {
    await _provasCollection.doc(id).delete();
  }
}
