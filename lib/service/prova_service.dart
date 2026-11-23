import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/aluno.dart';
import '../models/provas.dart';

class ProvaService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _provas =>
      _db.collection('provasCriadas');
  CollectionReference<Map<String, dynamic>> get _vinculos =>
      _db.collection('provaAlunos');

  String _uid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    return uid;
  }

  Stream<List<ProvaSalva>> observarMinhas() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _provas.where('criadoPor', isEqualTo: user.uid).snapshots().map((s) {
      final lista = s.docs.map((d) => ProvaSalva.fromFirestore(d)).toList();
      final agora = DateTime.now();
      lista.sort(
        (a, b) => (b.criadoEm ?? agora).compareTo(a.criadoEm ?? agora),
      );
      return lista;
    });
  }

  Stream<ProvaSalva?> observarPorId(String id) {
    return _provas
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? ProvaSalva.fromFirestore(d) : null);
  }

  Stream<List<VinculoProva>> observarVinculos(String provaId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _vinculos
        .where('provaId', isEqualTo: provaId)
        .where('criadoPor', isEqualTo: user.uid)
        .snapshots()
        .map((s) {
          final lista =
              s.docs.map((d) => VinculoProva.fromMap(d.id, d.data())).toList()
                ..sort((a, b) {
                  final t = a.turmaNome.toLowerCase().compareTo(
                    b.turmaNome.toLowerCase(),
                  );
                  return t != 0
                      ? t
                      : a.alunoNome.toLowerCase().compareTo(
                          b.alunoNome.toLowerCase(),
                        );
                });
          return lista;
        });
  }

  Future<({String id, int versoes})> criar({
    required String titulo,
    required List<ProvaQuestao> questoes,
    required int quantidadeVersoes,
  }) async {
    final uid = _uid();
    final versoes = gerarVersoes(questoes, quantidadeVersoes);

    final ref = await _provas.add({
      'titulo': titulo.trim(),
      'criadoPor': uid,
      'criadoEm': FieldValue.serverTimestamp(),
      'questoes': questoes.map((q) => q.toMap()).toList(),
      'versoes': versoes.map((v) => v.toMap(questoes)).toList(),
    });
    return (id: ref.id, versoes: versoes.length);
  }

  Future<void> excluir(String provaId) async {
    final uid = _uid();

    final vinc = await _vinculos
        .where('provaId', isEqualTo: provaId)
        .where('criadoPor', isEqualTo: uid)
        .get();

    final docs = vinc.docs;
    for (var i = 0; i < docs.length; i += 450) {
      final batch = _db.batch();
      for (final d in docs.skip(i).take(450)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    await _provas.doc(provaId).delete();
  }

  Future<({int novos, int jaTinham})> atrelar({
    required ProvaSalva prova,
    required String turmaId,
    required String turmaNome,
    required List<Aluno> alunos,
  }) async {
    final uid = _uid();

    final existentes = await _vinculos
        .where('provaId', isEqualTo: prova.id)
        .where('criadoPor', isEqualTo: uid)
        .get();
    final jaTem = existentes.docs
        .map((d) => (d.data()['alunoId'] ?? '') as String)
        .toSet();

    final novos = alunos.where((a) => !jaTem.contains(a.id)).toList()
      ..shuffle();
    final jaTinham = alunos.length - novos.length;
    if (novos.isEmpty) return (novos: 0, jaTinham: jaTinham);

    final n = prova.versoes.length;
    final inicio = jaTem.length; // continua o rodízio de onde parou

    for (var i = 0; i < novos.length; i += 450) {
      final batch = _db.batch();
      for (var j = i; j < min(i + 450, novos.length); j++) {
        final a = novos[j];
        batch.set(_vinculos.doc('${prova.id}_${a.id}'), {
          'provaId': prova.id,
          'alunoId': a.id,
          'alunoNome': a.nome,
          'turmaId': turmaId,
          'turmaNome': turmaNome,
          'versao': prova.versoes[(inicio + j) % n].numero,
          'criadoPor': uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    return (novos: novos.length, jaTinham: jaTinham);
  }
}
