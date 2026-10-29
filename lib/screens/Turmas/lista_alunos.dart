import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- Import necessário para pegar o UID
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'package:flutter_application_1/models/aluno.dart';
import 'package:flutter_application_1/service/aluno_service.dart';
import 'folha_resposta.dart';

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
  final bool usuarioEstaLogado = true;
  final AlunoService _alunoService = AlunoService();

  void _adicionarAlunoModal() {
    final nomeController = TextEditingController();
    final matriculaController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () async {
                if (nomeController.text.isNotEmpty && matriculaController.text.isNotEmpty) {
                  // Pega o UID do utilizador autenticado no momento da criação
                  final String? uid = FirebaseAuth.instance.currentUser?.uid;

                  final novoAluno = Aluno(
                    id: '',
                    nome: nomeController.text,
                    email: emailController.text,
                    turmaID: widget.turmaId,
                    criadoPor: uid ?? '', // <--- Passando o UID obrigatório
                  );
                  await _alunoService.adicionarAluno(novoAluno);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmarRemocaoAluno(Aluno aluno) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir o aluno "${aluno.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await _alunoService.excluirAluno(aluno.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
      floatingActionButton: usuarioEstaLogado
          ? FloatingActionButton(
              onPressed: _adicionarAlunoModal,
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Alunos - ${widget.turmaNome}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Aluno>>(
              stream: _alunoService.getAlunosPorTurma(widget.turmaId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum aluno nesta turma ainda.'));
                }

                final alunos = snapshot.data!;

                return ListView.builder(
                  itemCount: alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = alunos[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(aluno.nome.isNotEmpty ? aluno.nome[0] : 'A', style: const TextStyle(color: Colors.green)),
                      ),
                      title: Text(aluno.nome),
                      subtitle: Text('E-mail: ${aluno.email}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (usuarioEstaLogado)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmarRemocaoAluno(aluno),
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                            icon: const Icon(Icons.qr_code, size: 18, color: Colors.white),
                            label: const Text('Folha', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FolhaRespostaScreen(
                                    nomeAluno: aluno.nome,
                                    matricula: aluno.email,
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