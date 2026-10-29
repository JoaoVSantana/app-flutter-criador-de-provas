import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- Import necessário para pegar o UID
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'package:flutter_application_1/models/turma.dart';
import 'package:flutter_application_1/service/turma_service.dart';
import 'lista_alunos.dart';

class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  final bool usuarioEstaLogado = true;
  final TurmaService _turmaService = TurmaService();

  void _confirmarRemocaoTurma(Turma turma) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text('Tem certeza que deseja excluir a turma "${turma.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await _turmaService.excluirTurma(turma.id);
                if (context.mounted) Navigator.pop(context);
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
      builder: (context) => const NovaTurmaModal(),
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
          Row(
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.class_, color: Colors.green),
                        title: Text(turma.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (usuarioEstaLogado)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmarRemocaoTurma(turma),
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

class NovaTurmaModal extends StatefulWidget {
  const NovaTurmaModal({super.key});

  @override
  State<NovaTurmaModal> createState() => _NovaTurmaModalState();
}

class _NovaTurmaModalState extends State<NovaTurmaModal> {
  final TextEditingController _nomeTurmaController = TextEditingController();
  final TurmaService _turmaService = TurmaService();

  void _salvarTurma() async {
    if (_nomeTurmaController.text.isNotEmpty) {
      // Pega o UID do usuário autenticado no momento da criação
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      final novaTurma = Turma(
        id: '',
        nome: _nomeTurmaController.text,
        criadoPor: uid ?? '', // <--- Passando o UID obrigatório
      );
      await _turmaService.adicionarTurma(novaTurma);
      if (context.mounted) Navigator.pop(context);
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _salvarTurma,
            child: const Text('Salvar Turma', style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }
}