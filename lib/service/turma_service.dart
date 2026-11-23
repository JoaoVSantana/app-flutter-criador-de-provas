import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/turma.dart';

class TurmaDuplicadaException implements Exception {
  final String nome;
  TurmaDuplicadaException(this.nome);

  @override
  String toString() => 'Já existe uma turma chamada "$nome".';
}

class TurmaService {
  final CollectionReference _turmas = FirebaseFirestore.instance.collection(
    'turmas',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _limpar(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  String _uid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    return uid;
  }

  // Retorna apenas as turmas do usuário logado, em ordem alfabética
  Stream<List<Turma>> getTurmas() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _turmas.where('criadoPor', isEqualTo: uid).snapshots().map((s) {
      final lista = s.docs.map((d) => Turma.fromFirestore(d)).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return lista;
    });
  }

  // Não deixa o professor ter duas turmas com o mesmo nome
  Future<void> _garantirNomeUnico(
    String uid,
    String nome, {
    String? ignorarId,
  }) async {
    final snap = await _turmas.where('criadoPor', isEqualTo: uid).get();
    final existe = snap.docs.any((d) {
      if (d.id == ignorarId) return false;
      final dados = d.data() as Map<String, dynamic>;
      return _limpar(dados['nome'] ?? '').toLowerCase() == nome.toLowerCase();
    });
    if (existe) throw TurmaDuplicadaException(nome);
  }

  Future<void> adicionarTurma(String nome) async {
    final uid = _uid();
    final limpo = _limpar(nome);
    await _garantirNomeUnico(uid, limpo);
    await _turmas.add({'nome': limpo, 'criadoPor': uid});
  }

  Future<void> renomearTurma(String id, String nome) async {
    final uid = _uid();
    final limpo = _limpar(nome);
    await _garantirNomeUnico(uid, limpo, ignorarId: id);
    await _turmas.doc(id).update({'nome': limpo});
  }

  Future<void> excluirTurma(String turmaId) async {
    _uid();
    final db = FirebaseFirestore.instance;

    final alunos = await _turmas.doc(turmaId).collection('alunos').get();

    final docs = alunos.docs;
    for (var i = 0; i < docs.length; i += 450) {
      final batch = db.batch();
      for (final d in docs.skip(i).take(450)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    await _turmas.doc(turmaId).delete();
  }
}
