import 'package:flutter/material.dart';

import '../Routes/routes.dart';

class Navegar extends StatelessWidget {
  /// Se não for informado, volta para a tela anterior (quando existir uma).
  final VoidCallback? onVoltar;

  /// Se não for informado, vai para a próxima tela na ordem do menu.
  final VoidCallback? onAvancar;

  /// Desativa a seta de avançar (use em telas que avançam por conta própria,
  /// como a correção por etapas).
  final bool semAvancar;

  const Navegar({
    super.key,
    this.onVoltar,
    this.onAvancar,
    this.semAvancar = false,
  });

  // Mesma ordem do menu lateral
  static const List<String> _ordem = [
    AppRoutes.home,
    AppRoutes.listaQuestoes,
    AppRoutes.criarProva,
    AppRoutes.correcao,
    AppRoutes.listaTurmas,
    AppRoutes.relatorios,
  ];

  /// Próxima tela do menu, ou null se esta já é a última ou não é uma tela
  /// do menu (como a lista de alunos ou o detalhe da prova).
  String? _proximaRota(BuildContext context) {
    final atual = ModalRoute.of(context)?.settings.name;
    final i = _ordem.indexOf(atual ?? '');
    if (i == -1 || i == _ordem.length - 1) return null;
    return _ordem[i + 1];
  }

  @override
  Widget build(BuildContext context) {
    final proxima = semAvancar ? null : _proximaRota(context);

    final VoidCallback? voltar =
        onVoltar ??
        (Navigator.canPop(context) ? () => Navigator.pop(context) : null);

    final VoidCallback? avancar =
        onAvancar ??
        (proxima == null ? null : () => Navigator.pushNamed(context, proxima));

    return Container(
      color: const Color.fromARGB(255, 150, 194, 176),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: voltar,
            icon: const Icon(Icons.arrow_back_ios),
            color: voltar == null ? Colors.grey : Colors.black,
          ),
          IconButton(
            onPressed: avancar,
            icon: const Icon(Icons.arrow_forward_ios),
            color: avancar == null ? Colors.grey : Colors.black,
          ),
        ],
      ),
    );
  }
}
