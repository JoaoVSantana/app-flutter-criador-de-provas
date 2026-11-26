import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';

import 'package:flutter_application_1/models/aluno.dart';
import 'package:flutter_application_1/service/aluno_service.dart';

import 'dialog_nome.dart';

class ListaAlunosScreen extends StatefulWidget {
  final String turmaId;
  final String turmaNome;

  const ListaAlunosScreen({
    super.key,
    required this.turmaId,
    required this.turmaNome,
  });

  @override
  State<ListaAlunosScreen> createState() => _ListaAlunosScreenState();
}

class _ListaAlunosScreenState extends State<ListaAlunosScreen> {
  final AlunoService _alunoService = AlunoService();

  void _novoAluno() {
    mostrarDialogNome(
      context,
      titulo: 'Novo aluno',
      rotulo: 'Nome do aluno',
      onSalvar: (nome) async {
        await _alunoService.adicionarAluno(turmaId: widget.turmaId, nome: nome);
        return null;
      },
    );
  }

  void _renomearAluno(Aluno aluno) {
    mostrarDialogNome(
      context,
      titulo: 'Editar aluno',
      rotulo: 'Nome do aluno',
      inicial: aluno.nome,
      onSalvar: (nome) async {
        await _alunoService.renomearAluno(
          turmaId: widget.turmaId,
          alunoId: aluno.id,
          nome: nome,
        );
        return null;
      },
    );
  }

  void _confirmarRemocaoAluno(Aluno aluno) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir aluno?'),
        content: Text('Tem certeza que deseja excluir "${aluno.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _alunoService.excluirAluno(
                  turmaId: widget.turmaId,
                  alunoId: aluno.id,
                );
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
        onPressed: _novoAluno,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Alunos - ${widget.turmaNome}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Aluno>>(
              stream: _alunoService.getAlunosPorTurma(widget.turmaId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhum aluno nesta turma ainda.'),
                  );
                }

                final alunos = snapshot.data!;

                return ListView.builder(
                  itemCount: alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = alunos[index];
                    return ListTile(
                      leading: Icon(
                        Icons.person_outline,
                        color: Colors.green[700],
                        size: 28,
                      ),
                      title: Text(aluno.nome),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'editar') {
                            _renomearAluno(aluno);
                          } else {
                            _confirmarRemocaoAluno(aluno);
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
