/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';
import '../service/usuario_service.dart';

class SaudacaoUsuario extends StatelessWidget {
  final TextStyle? style;
  const SaudacaoUsuario({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) return const SizedBox.shrink();

        return StreamBuilder<Usuario?>(
          stream: UsuarioService().observar(user.uid),
          builder: (context, snap) {
            final nome = snap.data?.nome ?? '';
            if (nome.isEmpty) return const SizedBox.shrink();
            return Text('Olá, $nome', style: style);
          },
        );
      },
    );
  }
}
*/
