import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/bloconav.dart';
import '../../Routes/routes.dart';

class HomeDesktop extends StatelessWidget {
  const HomeDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 228, 235, 230),
          body: Column(
            children: [
              const Header(),

              Expanded(
                child: Row(
                  children: [
                    // LADO ESQUERDO
                    Container(
                      width: 500,
                      color: Color.fromARGB(255, 212, 214, 213),

                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                left: 35,
                                top: 20,
                                right: 20,
                                bottom: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF4C6B5E),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Crie, Corrija e Evolua',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: 'Oswald',
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4C6B5E),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: const Text(
                                'Menos tempo corrigindo. Mais tempo ensinando. '
                                'Uma nova forma de criar, corrigir e acompanhar '
                                'suas avaliações.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 26, 29, 28),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: const Text(
                                ' Automatize a correção das provas '
                                'e tenha resultados organizados em poucos cliques. '
                                'Visualize estatísticas, identifique padrões e '
                                'acompanhe o desempenho dos seus alunos. Tudo de '
                                'forma rápida, prática e inteligente.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 26, 29, 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // LADO DIREITO
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            BlocoNav(
                              title: 'Banco de questões',
                              icon: Icons.library_books,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.listaQuestoes,
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            BlocoNav(
                              title: 'Criar prova',
                              icon: Icons.description,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.criarProva,
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            BlocoNav(
                              title: 'Corrigir prova',
                              icon: Icons.check_circle,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.correcao,
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            BlocoNav(
                              title: 'Turmas e alunos',
                              icon: Icons.groups,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.listaTurmas,
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            BlocoNav(
                              title: 'Relatórios',
                              icon: Icons.analytics,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.relatorios,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
