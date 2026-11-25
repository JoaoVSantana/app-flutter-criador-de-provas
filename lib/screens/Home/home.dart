import 'package:flutter/material.dart';

import '../../widgets/navegar.dart';
import '../../widgets/header.dart';
import '../../widgets/bloconav.dart';
import '../../Routes/routes.dart';
import '../../widgets/drawernav.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  static const Color _fundo = Color.fromARGB(255, 228, 235, 230);
  static const Color _decoracao = Color.fromARGB(255, 214, 224, 211);
  static const Color _corTitulo = Color.fromARGB(255, 58, 95, 73);
  static const Color _corSubtitulo = Color.fromARGB(255, 66, 94, 83);
  static const Color _corIcone = Color.fromARGB(255, 47, 51, 49);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTela = constraints.maxWidth;
        final isMobile = larguraTela < 600;

        final larguraBloco = isMobile
            ? ((larguraTela - 56) / 2).clamp(120.0, 175.0)
            : (larguraTela * 0.26).clamp(155.0, 210.0);
        final alturaBloco = isMobile ? larguraBloco * 1.15 : larguraBloco * 1.1;
        final fontTitulo = (larguraTela * 0.075).clamp(28.0, 38.0);

        return Scaffold(
          drawer: const DrawerNav(),
          backgroundColor: _fundo,
          body: Column(
            children: [
              // Header fixo, fora da área que rola
              const Header(),

              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: -75,
                      right: -65,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: _decoracao.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -95,
                      left: -70,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: _decoracao.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 18 : 28,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Builder(
                              builder: (context) => IconButton(
                                tooltip: 'Abrir menu',
                                icon: const Icon(
                                  Icons.menu,
                                  color: _corIcone,
                                ),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    'Crie, Corrija e Evolua',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: fontTitulo,
                                      fontFamily: 'Oswald',
                                      fontWeight: FontWeight.w800,
                                      height: 1.12,
                                      color: _corTitulo,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: Text(
                                    'Menos tempo corrigindo. Mais tempo ensinando, '
                                    'uma nova forma de criar, corrigir e acompanhar '
                                    'suas avaliações.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: (larguraTela * 0.04).clamp(
                                        14.5,
                                        16.5,
                                      ),
                                      fontFamily: 'Poppins',
                                      height: 1.4,
                                      color: _corSubtitulo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: larguraBloco,
                                  height: alturaBloco,
                                  child: BlocoNav(
                                    title: 'Banco de questões',
                                    image: 'assets/images/banco_questoes.png',
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.listaQuestoes,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: larguraBloco,
                                  height: alturaBloco,
                                  child: BlocoNav(
                                    title: 'Criar prova',
                                    image: 'assets/images/criar_prova.png',
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.criarProva,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: larguraBloco,
                                  height: alturaBloco,
                                  child: BlocoNav(
                                    title: 'Corrigir prova',
                                    image: 'assets/images/correcao.png',
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.correcao,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: larguraBloco,
                                  height: alturaBloco,
                                  child: BlocoNav(
                                    title: 'Turmas e alunos',
                                    image: 'assets/images/turmas_alunos.png',
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.listaTurmas,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: larguraBloco,
                                  height: alturaBloco,
                                  child: BlocoNav(
                                    title: 'Relatórios',
                                    image: 'assets/images/relatorios.png',
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.relatorios,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Navegar(onVoltar: null, onAvancar: null),
            ],
          ),
        );
      },
    );
  }
}