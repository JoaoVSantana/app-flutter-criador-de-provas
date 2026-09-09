import 'package:flutter/material.dart';

import '../Routes/routes.dart';

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
            const Divider(),
            _itemMenu(
              context,
              icone: Icons.login_outlined,
              texto: 'Entrar / Cadastrar',
              rota: AppRoutes.entrar,
            ),
          ],
        ),
      ),
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
