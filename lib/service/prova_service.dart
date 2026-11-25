import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/aluno.dart';
import '../models/provas.dart';

class ProvaService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _provas =>
      _db.collection('criarProvas');

  // A folha de cada aluno fica dentro da prova
  CollectionReference<Map<String, dynamic>> _folhas(String provaId) =>
      _provas.doc(provaId).collection('alunos');

  String _uid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    return uid;
  }

  Future<String> _nomeProfessor(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    final nome = (doc.data()?['nome'] ?? '') as String;
    if (nome.isNotEmpty) return nome;
    return FirebaseAuth.instance.currentUser?.email ?? '';
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

  /// Todas as folhas (alunos) de uma prova.
  Stream<List<FolhaAluno>> observarFolhas(String provaId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _folhas(provaId)
        .where('criadoPor', isEqualTo: user.uid)
        .snapshots()
        .map((s) {
          final lista =
              s.docs.map((d) => FolhaAluno.fromMap(d.id, d.data())).toList()
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

  /// Salva a prova com as versões já geradas.
  Future<({String id, int versoes})> criar({
    required String titulo,
    required List<ProvaQuestao> questoes,
    required int quantidadeVersoes,
  }) async {
    final uid = _uid();
    final nomeProf = await _nomeProfessor(uid);
    final versoes = gerarVersoes(questoes, quantidadeVersoes);

    final ref = await _provas.add({
      'titulo': titulo.trim(),
      'criadoPor': uid,
      'criadoPorNome': nomeProf,
      'criadoEm': FieldValue.serverTimestamp(),
      'questoes': questoes.map((q) => q.toMap()).toList(),
      'versoes': versoes.map((v) => v.toMap(questoes)).toList(),
    });
    return (id: ref.id, versoes: versoes.length);
  }

  /// Exclui a prova e as folhas dos alunos.
  Future<void> excluir(String provaId) async {
    final uid = _uid();

    final folhas = await _folhas(provaId)
        .where('criadoPor', isEqualTo: uid)
        .get();

    final docs = folhas.docs;
    for (var i = 0; i < docs.length; i += 450) {
      final batch = _db.batch();
      for (final d in docs.skip(i).take(450)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    await _provas.doc(provaId).delete();
  }

  static const _alfabeto =
      'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // sem I, L, O, 0, 1

  /// Código curto e fácil de digitar, no formato ABCD-EFGH.
  String _novoCodigo(Set<String> usados) {
    final rnd = Random.secure();
    String codigo;
    do {
      final bruto = List.generate(
        8,
        (_) => _alfabeto[rnd.nextInt(_alfabeto.length)],
      ).join();
      codigo = '${bruto.substring(0, 4)}-${bruto.substring(4)}';
    } while (!usados.add(codigo));
    return codigo;
  }

  /// Cria a folha de cada aluno: versão em rodízio, código único e gabarito.
  /// Quem já tem folha dessa prova não é atrelado de novo.
  Future<({int novos, int jaTinham})> atrelar({
    required ProvaSalva prova,
    required String turmaId,
    required String turmaNome,
    required List<Aluno> alunos,
  }) async {
    final uid = _uid();
    final nomeProf = await _nomeProfessor(uid);

    final existentes = await _folhas(prova.id)
        .where('criadoPor', isEqualTo: uid)
        .get();
    final jaTem = existentes.docs.map((d) => d.id).toSet();
    final codigosUsados = existentes.docs
        .map((d) => (d.data()['codigo'] ?? '') as String)
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
        final versao = prova.versoes[(inicio + j) % n];
        batch.set(_folhas(prova.id).doc(a.id), {
          'alunoNome': a.nome,
          'turmaId': turmaId,
          'turmaNome': turmaNome,
          'versao': versao.numero,
          'codigo': _novoCodigo(codigosUsados),
          'gabarito': versao.gabarito(prova.questoes),
          'criadoPor': uid,
          'criadoPorNome': nomeProf,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    return (novos: novos.length, jaTinham: jaTinham);
  }

  Future<void> removerFolha(String provaId, String alunoId) {
    return _folhas(provaId).doc(alunoId).delete();
  }
}
