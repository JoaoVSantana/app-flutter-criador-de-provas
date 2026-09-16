import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'lista_alunos.dart';

class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  final bool usuarioEstaLogado = true; 

  List<Map<String, dynamic>> turmasMock = [
    {
      'nome': '1º Ano A',
      'alunos': [
        {'matricula': '2023001', 'nome': 'Ana Silva Costa'},
        {'matricula': '2023002', 'nome': 'Bruno Gomes Souza'},
      ]
    },
    {
      'nome': '2º Ano B',
      'alunos': <Map<String, String>>[] 
    }
  ];

  void _removerTurma(int index) {
    setState(() {
      turmasMock.removeAt(index);
    });
  }

  void _confirmarRemocaoTurma(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir a turma "${turmasMock[index]['nome']}" e todos os seus alunos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _removerTurma(index); 
                Navigator.pop(context); 
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _abrirModalNovaTurma() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NovaTurmaModal(
        onSalvar: (novaTurma) {
          setState(() {
            turmasMock.add(novaTurma);
          });
        },
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
      floatingActionButton: usuarioEstaLogado 
          ? FloatingActionButton(
              onPressed: _abrirModalNovaTurma,
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ADICIONADO: Linha com o botão do Menu e o Título
          Row(
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () {
                      // Este comando força o Scaffold a abrir a Navbar
                      Scaffold.of(context).openDrawer(); 
                    },
                  );
                }
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text(
                  'Minhas Turmas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: turmasMock.length,
              itemBuilder: (context, index) {
                final turma = turmasMock[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.class_, color: Colors.green),
                    title: Text(turma['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${turma['alunos'].length} aluno(s)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (usuarioEstaLogado)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmarRemocaoTurma(index),
                          ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListaAlunosScreen(
                            turmaNome: turma['nome'],
                            alunosDaTurma: turma['alunos'], 
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
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

// Modal de Criação de Turma (Mantido igual)
class NovaTurmaModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSalvar;

  const NovaTurmaModal({super.key, required this.onSalvar});

  @override
  State<NovaTurmaModal> createState() => _NovaTurmaModalState();
}

class _NovaTurmaModalState extends State<NovaTurmaModal> {
  final TextEditingController _nomeTurmaController = TextEditingController();
  final TextEditingController _nomeAlunoController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();

  List<Map<String, String>> alunosAdicionados = [];

  void _adicionarAlunoLista() {
    if (_nomeAlunoController.text.isNotEmpty && _matriculaController.text.isNotEmpty) {
      setState(() {
        alunosAdicionados.add({
          'nome': _nomeAlunoController.text,
          'matricula': _matriculaController.text,
        });
        _nomeAlunoController.clear();
        _matriculaController.clear();
      });
    }
  }

  void _salvarTurma() {
    if (_nomeTurmaController.text.isNotEmpty) {
      widget.onSalvar({
        'nome': _nomeTurmaController.text,
        'alunos': alunosAdicionados,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: bottomPadding + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Criar Nova Turma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeTurmaController,
            decoration: const InputDecoration(
              labelText: 'Nome da Turma (Ex: 1º Ano A)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Adicionar Alunos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nomeAlunoController,
                  decoration: const InputDecoration(labelText: 'Nome', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _matriculaController,
                  decoration: const InputDecoration(labelText: 'Matrícula', isDense: true),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                onPressed: _adicionarAlunoLista,
              )
            ],
          ),
          const SizedBox(height: 16),
          if (alunosAdicionados.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: alunosAdicionados.length,
                itemBuilder: (context, index) {
                  final al = alunosAdicionados[index];
                  return ListTile(
                    dense: true,
                    title: Text(al['nome']!),
                    subtitle: Text(al['matricula']!),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => alunosAdicionados.removeAt(index)), 
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            onPressed: _salvarTurma,
            child: const Text('Salvar Turma', style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }
}