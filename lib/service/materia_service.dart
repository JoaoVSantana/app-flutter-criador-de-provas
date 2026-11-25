import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/materia.dart';

class MateriaService {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('materias');

  Stream<List<Materia>> observar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _col(user.uid).snapshots().map((s) {
      final lista = s.docs.map((d) => Materia.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return lista;
    });
  }

  Future<Materia> criarMateria(String nome) async {
    final col = _col(FirebaseAuth.instance.currentUser!.uid);
    final limpo = nome.trim();

    final existente = await col
        .where('nomeLower', isEqualTo: limpo.toLowerCase())
        .limit(1)
        .get();
    if (existente.docs.isNotEmpty) {
      final d = existente.docs.first;
      return Materia.fromMap(d.id, d.data());
    }

    final ref = await col.add({
      'nome': limpo,
      'nomeLower': limpo.toLowerCase(),
      'assuntos': <String>[],
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return Materia(id: ref.id, nome: limpo);
  }

  Future<void> adicionarAssunto(String materiaId, String assunto) {
    final col = _col(FirebaseAuth.instance.currentUser!.uid);
    return col.doc(materiaId).update({
      'assuntos': FieldValue.arrayUnion([assunto.trim()]),
    });
  }
}
