import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';

import 'package:flutter_application_1/models/turma.dart';
import 'package:flutter_application_1/service/turma_service.dart';

import 'dialog_nome.dart';
import 'lista_alunos.dart';

class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  final TurmaService _turmaService = TurmaService();

  void _novaTurma() {
    mostrarDialogNome(
      context,
      titulo: 'Nova turma',
      rotulo: 'Nome da turma (Ex: 1º Ano A)',
      maximo: 40,
      onSalvar: (nome) async {
        try {
          await _turmaService.adicionarTurma(nome);
          return null;
        } on TurmaDuplicadaException {
          return 'Você já tem uma turma com esse nome';
        }
      },
    );
  }

  void _renomearTurma(Turma turma) {
    mostrarDialogNome(
      context,
      titulo: 'Editar turma',
      rotulo: 'Nome da turma',
      inicial: turma.nome,
      maximo: 40,
      onSalvar: (nome) async {
        try {
          await _turmaService.renomearTurma(turma.id, nome);
          return null;
        } on TurmaDuplicadaException {
          return 'Você já tem uma turma com esse nome';
        }
      },
    );
  }

  void _confirmarRemocaoTurma(Turma turma) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir turma?'),
        content: Text(
          'A turma "${turma.nome}" e todos os alunos dela serão excluídos. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _turmaService.excluirTurma(turma.id);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerNav(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(),
      ),
      bottomNavigationBar: Navegar(
        onVoltar: () => Navigator.pop(context),
        onAvancar: () {},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _novaTurma,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text(
                  'Minhas Turmas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Turma>>(
              stream: _turmaService.getTurmas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhuma turma cadastrada.'));
                }

                final turmas = snapshot.data!;

                return ListView.builder(
                  itemCount: turmas.length,
                  itemBuilder: (context, index) {
                    final turma = turmas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.class_, color: Colors.green),
                        title: Text(
                          turma.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'editar') {
                                  _renomearTurma(turma);
                                } else {
                                  _confirmarRemocaoTurma(turma);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'editar',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Editar nome'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'excluir',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListaAlunosScreen(
                                turmaId: turma.id,
                                turmaNome: turma.nome,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
