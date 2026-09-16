import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'folha_resposta.dart';

class ListaAlunosScreen extends StatefulWidget {
  final String turmaNome;
  final List<dynamic> alunosDaTurma;

  const ListaAlunosScreen({super.key, required this.turmaNome, required this.alunosDaTurma});

  @override
  State<ListaAlunosScreen> createState() => _ListaAlunosScreenState();
}

class _ListaAlunosScreenState extends State<ListaAlunosScreen> {
  final bool usuarioEstaLogado = true;

  void _adicionarAlunoRapido() {
    setState(() {
      widget.alunosDaTurma.add({
        'matricula': '202600${widget.alunosDaTurma.length + 1}',
        'nome': 'Novo Aluno Teste',
      });
    });
  }

  void _removerAluno(int index) {
    setState(() {
      widget.alunosDaTurma.removeAt(index);
    });
  }

  void _confirmarRemocaoAluno(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir o aluno "${widget.alunosDaTurma[index]['nome']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _removerAluno(index); 
                Navigator.pop(context); 
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
              onPressed: _adicionarAlunoRapido,
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
            child: widget.alunosDaTurma.isEmpty 
              ? const Center(child: Text('Nenhum aluno nesta turma ainda.'))
              : ListView.builder(
                  itemCount: widget.alunosDaTurma.length,
                  itemBuilder: (context, index) {
                    final aluno = widget.alunosDaTurma[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(aluno['nome']![0], style: const TextStyle(color: Colors.green)),
                      ),
                      title: Text(aluno['nome']!),
                      subtitle: Text('Matrícula: ${aluno['matricula']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (usuarioEstaLogado)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmarRemocaoAluno(index),
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
                                    nomeAluno: aluno['nome']!,
                                    matricula: aluno['matricula']!,
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
            ),
          ),
        ],
      ),
    );
  }
}