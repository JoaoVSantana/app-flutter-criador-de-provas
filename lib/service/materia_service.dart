import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MateriaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference? _materiasRef(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    return _db.collection('usuarios').doc(uid).collection('materias');
  }

  Stream<List<String>> getMaterias({List<String> padrao = const []}) {
    final String? uid = _auth.currentUser?.uid;
    final ref = _materiasRef(uid);

    Stream<List<String>> customStream;
    if (ref == null) {
      customStream = Stream.value([]);
    } else {
      customStream = ref.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data is Map) {
                return (data['nome'] ?? '').toString().trim();
              }
              return '';
            })
            .where((nome) => nome.isNotEmpty)
            .toList();
      });
    }

    return customStream.map((criadas) {
      final unicas = <String>{
        ...padrao.map((m) => m.trim()).where((m) => m.isNotEmpty),
        ...criadas,
      };
      final lista = unicas.toList()..sort((a, b) => a.compareTo(b));
      return lista;
    });
  }

  Future<String> adicionarMateria(String nome) async {
    final String? uid = _auth.currentUser?.uid;
    final ref = _materiasRef(uid);
    if (ref == null) throw Exception('Usuário não autenticado');

    final limpa = nome.trim();
    if (limpa.isEmpty) {
      throw Exception('Informe o nome da matéria.');
    }

    final existentes = await ref.get();

    final jaExiste = existentes.docs.any((doc) {
      final data = doc.data();
      final nomeExistente =
          data is Map ? (data['nome'] ?? '').toString().trim().toLowerCase() : '';
      return nomeExistente == limpa.toLowerCase();
    });

    if (!jaExiste) {
      await ref.add({
        'nome': limpa,
        'criadoPor': uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }

    return limpa;
  }
}