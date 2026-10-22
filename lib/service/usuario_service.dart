import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';

//Criação dos atalhos do auth e do firestore
class UsuarioService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> cadastrar({
    required String nome,
    required String sobrenome,
    required String cpf,
    required String email,
    required String senha,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final uid = cred.user!.uid;

    // monta o model e salva o perfil no Firestore
    final usuario = Usuario(
      uid: uid,
      nome: nome,
      sobrenome: sobrenome,
      cpf: cpf,
      email: email,
    );
    await _db.collection('usuarios').doc(uid).set(usuario.toMap());
  }

  Future<Usuario?> buscar(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromMap(doc.id, doc.data()!);
  }

  Future<Usuario?> entrar({
    required String email,
    required String senha,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return buscar(cred.user!.uid);
  }
}
