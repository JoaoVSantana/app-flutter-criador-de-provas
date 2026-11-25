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

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _adicionarAlunoModal() {
    final nomeController = TextEditingController();
    final matriculaController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar Aluno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Aluno'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(labelText: 'Matrícula'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              onPressed: () async {
                final nome = nomeController.text.trim();
                final email = emailController.text.trim();
                final matricula = matriculaController.text.trim();

                if (nome.isEmpty || matricula.isEmpty) {
                  _mostrarMensagem('Preencha o nome e a matrícula do aluno.');
                  return;
                }

                // Pega o UID do utilizador autenticado no momento da criação
                final String? uid = FirebaseAuth.instance.currentUser?.uid;

                final novoAluno = Aluno(
                  id: '',
                  nome: nome,
                  email: email,
                  matricula: matricula,
                  turmaID: widget.turmaId,
                  criadoPor: uid ?? '', // <--- Passando o UID obrigatório
                );

                try {
                  await _alunoService.adicionarAluno(novoAluno);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  final msg = e.toString().replaceFirst('Exception: ', '');
                  _mostrarMensagem(msg);
                }
              },
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
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
                      subtitle: Text(
                        aluno.matricula.isNotEmpty
                            ? 'Matrícula: ${aluno.matricula} • E-mail: ${aluno.email}'
                            : 'E-mail: ${aluno.email}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (usuarioEstaLogado)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmarRemocaoAluno(aluno),
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                            ),
                            icon: const Icon(
                              Icons.qr_code,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Folha',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FolhaRespostaScreen(
                                    nomeAluno: aluno.nome,
                                    matricula: aluno.matricula.isNotEmpty
                                        ? aluno.matricula
                                        : aluno.email,
                                    turma: widget.turmaNome,
                                  ),
                                ),
                              );
                            },
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
