import 'package:flutter/material.dart';

import '../../widgets/navegar.dart';
import '../../widgets/header.dart';
import '../../widgets/bloconav.dart';
import '../../Routes/routes.dart';
import '../../widgets/drawernav.dart';

class HomeMobile extends StatelessWidget {
  const HomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTela = constraints.maxWidth;

        final larguraBloco = (larguraTela * 0.32).clamp(100.0, 150.0);
        final alturaBloco = larguraBloco * 1.2;
        final fontTitulo = (larguraTela * 0.08).clamp(22.0, 32.0);

        return Scaffold(
          drawer: const DrawerNav(),
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                children: [
                  const Header(),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),

                  // LADO ESQUERDO
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(larguraTela * 0.04),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: Text(
                              'Crie, Corrija e Evolua',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontTitulo,
                                fontFamily: 'Oswald',
                                fontWeight: FontWeight.w800,
                                color: const Color.fromARGB(255, 58, 95, 73),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Text(
                              'Menos tempo corrigindo. Mais tempo ensinando, '
                              'uma nova forma de criar, corrigir e acompanhar '
                              'suas avaliações.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: (larguraTela * 0.04).clamp(
                                  14.0,
                                  16.0,
                                ),
                                fontFamily: 'Poppins',
                                color: const Color.fromARGB(255, 66, 94, 83),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // LADO DIREITO
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 15,
                      runSpacing: 15,
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
                              Navigator.pushNamed(context, AppRoutes.correcao);
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

                  const SizedBox(height: 24),
                  Navegar(onVoltar: null, onAvancar: null),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
