import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/BancoQuestoes/elem_comuns.dart';

class QuestaoService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('questoes');

  Map<String, dynamic> _toMap(Question q) => {
    'materia': q.materia,
    'assunto': q.assunto,
    'nivel': q.nivel.name,
    'enunciado': q.enunciado,
    'alternativas': q.alternativas,
    'corretas': q.corretas.toList()..sort(),
  };

  Question _fromMap(String id, Map<String, dynamic> m) => Question(
    id: id,
    codigo: m['codigo'] ?? '',
    materia: m['materia'] ?? '',
    assunto: m['assunto'] ?? '',
    nivel: Nivel.values.firstWhere(
      (n) => n.name == m['nivel'],
      orElse: () => Nivel.baixo,
    ),
    enunciado: m['enunciado'] ?? '',
    alternativas: List<String>.from(m['alternativas'] ?? []),
    corretas: List<int>.from(m['corretas'] ?? []).toSet(),
  );

  /// Salva a questão com um código sequencial do professor (Q-0001, Q-0002...)
  /// e devolve esse código.
  Future<String> criar(Question q) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final perfilRef = _db.collection('usuarios').doc(uid);
    final novaRef = _col.doc();
    late final String codigo;

    await _db.runTransaction((tx) async {
      final perfil = await tx.get(perfilRef);
      final atual = ((perfil.data()?['ultimoCodigoQuestao'] ?? 0) as num)
          .toInt();
      final proximo = atual + 1;
      codigo = 'Q-${proximo.toString().padLeft(4, '0')}';

      tx.set(perfilRef, {
        'ultimoCodigoQuestao': proximo,
      }, SetOptions(merge: true));
      tx.set(novaRef, {
        ..._toMap(q),
        'codigo': codigo,
        'codigoNumero': proximo,
        'professorId': uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    });

    return codigo;
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

  Future<void> atualizar(Question q) {
    return _col.doc(q.id).update({
      ..._toMap(q),

      'turmas': FieldValue.delete(),
      'tipo': FieldValue.delete(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluir(String id) => _col.doc(id).delete();
}
