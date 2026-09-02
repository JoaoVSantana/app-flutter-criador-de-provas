import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/bloconav.dart';
import '../../Routes/routes.dart';

class HomeMobile extends StatelessWidget {
  const HomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Column(
            children: [
              const Header(),

              Expanded(
                child: Column(
                  children: [
                    // LADO ESQUERDO
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: const Text(
                                'Crie, Corrija e Evolua',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontFamily: 'Oswald',
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4C6B5E),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Oswald',
                                  color: Color(0xFF1B2A24),
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
                        padding: const EdgeInsets.all(5),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 15,
                          runSpacing: 15,
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
