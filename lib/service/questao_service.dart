import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/BancoQuestoes/elem_comuns.dart';

class QuestaoService {
  final _col = FirebaseFirestore.instance.collection('questoes');

  Map<String, dynamic> _toMap(Question q) => {
    'materia': q.materia,
    'assunto': q.assunto,
    'nivel': q.nivel.name,
    'tipo': q.tipo.name,
    'turmas': q.turmas,
    'enunciado': q.enunciado,
    'alternativas': q.alternativas,
    'corretas': q.corretas.toList()..sort(),
  };

  Question _fromMap(String id, Map<String, dynamic> m) => Question(
    id: id,
    materia: m['materia'] ?? '',
    assunto: m['assunto'] ?? '',
    nivel: Nivel.values.firstWhere(
      (n) => n.name == m['nivel'],
      orElse: () => Nivel.baixo,
    ),
    tipo: Tipo.values.firstWhere(
      (t) => t.name == m['tipo'],
      orElse: () => Tipo.multipla,
    ),
    turmas: List<String>.from(m['turmas'] ?? []),
    enunciado: m['enunciado'] ?? '',
    alternativas: List<String>.from(m['alternativas'] ?? []),
    corretas: List<int>.from(m['corretas'] ?? []).toSet(),
  );

  Future<void> criar(Question q) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col.add({
      ..._toMap(q),
      'professorId': uid,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Question>> observarMinhas() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _col.where('professorId', isEqualTo: user.uid).snapshots().map((s) {
      final docs = s.docs.toList();
      docs.sort((a, b) {
        final ta = a.data()['criadoEm'] as Timestamp?;
        final tb = b.data()['criadoEm'] as Timestamp?;
        if (ta == null && tb == null) return 0;
        if (ta == null) return -1;
        if (tb == null) return 1;
        return tb.compareTo(ta);
      });
      return docs.map((d) => _fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> excluir(String id) => _col.doc(id).delete();
}
