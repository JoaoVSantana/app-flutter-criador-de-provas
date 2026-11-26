import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Routes/routes.dart';
import '../models/usuario.dart';
import '../service/usuario_service.dart';

class DrawerNav extends StatelessWidget {
  const DrawerNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 228, 235, 230),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 47, 51, 49),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _itemMenu(
              context,
              icone: Icons.home_outlined,
              texto: 'Home',
              rota: AppRoutes.home,
            ),
            _itemMenu(
              context,
              icone: Icons.menu_book_outlined,
              texto: 'Banco de questões',
              rota: AppRoutes.listaQuestoes,
            ),
            _itemMenu(
              context,
              icone: Icons.edit_note_outlined,
              texto: 'Criar prova',
              rota: AppRoutes.criarProva,
            ),
            _itemMenu(
              context,
              icone: Icons.fact_check_outlined,
              texto: 'Corrigir prova',
              rota: AppRoutes.correcao,
            ),
            _itemMenu(
              context,
              icone: Icons.groups_outlined,
              texto: 'Turmas e alunos',
              rota: AppRoutes.listaTurmas,
            ),
            _itemMenu(
              context,
              icone: Icons.bar_chart_outlined,
              texto: 'Relatórios',
              rota: AppRoutes.relatorios,
            ),
            // Empurra o usuário para a parte de baixo do menu
            const Spacer(),
            _itemUsuario(context),
          ],
        ),
      ),
    );
  }

  Widget _itemUsuario(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    const cor = Color.fromARGB(255, 47, 51, 49);

    return StreamBuilder<Usuario?>(
      stream: UsuarioService().observar(user.uid),
      builder: (context, snap) {
        final nome = snap.data?.nome ?? '';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person, color: cor),
              title: Text(
                nome.isEmpty ? 'Meu perfil' : nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: cor),
              ),
              trailing: const Icon(Icons.chevron_right, color: cor),
              onTap: () {
                final atual = ModalRoute.of(context)?.settings.name;
                Navigator.pop(context); // fecha o menu
                if (atual != AppRoutes.perfil) {
                  Navigator.pushNamed(context, AppRoutes.perfil);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _itemMenu(
    BuildContext context, {
    required IconData icone,
    required String texto,
    required String rota,
  }) {
    return ListTile(
      leading: Icon(icone, color: const Color.fromARGB(255, 47, 51, 49)),
      title: Text(
        texto,
        style: const TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 47, 51, 49),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, rota);
      },
    );
  }
}
