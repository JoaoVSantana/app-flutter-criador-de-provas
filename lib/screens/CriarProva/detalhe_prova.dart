import 'package:flutter/material.dart';

import '../../models/provas.dart';
import '../../models/turma.dart';
import '../../service/prova_service.dart';
import '../../service/turma_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';
import 'alunos_da_prova.dart';
import 'previa_papel.dart';

class DetalheProvaPage extends StatefulWidget {
  final String provaId;
  const DetalheProvaPage({super.key, required this.provaId});

  @override
  State<DetalheProvaPage> createState() => _DetalheProvaPageState();
}

class _DetalheProvaPageState extends State<DetalheProvaPage> {
  final _service = ProvaService();
  late final Stream<ProvaSalva?> _prova = _service.observarPorId(
    widget.provaId,
  );
  late final Stream<List<FolhaAluno>> _folhas = _service.observarFolhas(
    widget.provaId,
  );
  late final Stream<List<Turma>> _turmas = TurmaService().getTurmas();
  int _versaoSel = 1;

  void _confirmarExclusao(ProvaSalva prova) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir prova?'),
        content: Text(
          'A prova "${prova.titulo}" e a folha de todos os alunos serão '
          'excluídas. Essa ação não pode ser desfeita.',
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
                await _service.excluir(prova.id);
                if (mounted) Navigator.pop(context);
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

  Widget _cardTurma(ProvaSalva prova, Turma turma, int comProva) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: kListCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlunosDaProvaPage(prova: prova, turma: turma),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.class_outlined, color: kGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turma.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comProva == 0
                            ? 'Nenhum aluno com esta prova'
                            : '$comProva aluno(s) com esta prova',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
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
      bottomNavigationBar: Navegar(onVoltar: () => Navigator.pop(context)),
      body: SafeArea(
        child: StreamBuilder<ProvaSalva?>(
          stream: _prova,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Erro ao carregar: ${snap.error}'));
            }
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final prova = snap.data;
            if (prova == null) {
              return const Center(child: Text('Prova não encontrada.'));
            }

            final versao = prova.versao(_versaoSel);
            final itens = versao.montar(prova.questoes);
            final gabarito = [
              for (var i = 0; i < itens.length; i++)
                '${i + 1}-${String.fromCharCode(65 + itens[i].correta)}',
            ].join('   ');

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuTitle(title: prova.titulo, fontSize: 24),
                  const SizedBox(height: 24),
                  const Text(
                    'Turmas e alunos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha uma turma para atrelar esta prova aos alunos.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<FolhaAluno>>(
                    stream: _folhas,
                    builder: (context, fsnap) {
                      if (fsnap.hasError) {
                        return Text('Erro ao carregar: ${fsnap.error}');
                      }
                      final folhas = fsnap.data ?? [];
                      return StreamBuilder<List<Turma>>(
                        stream: _turmas,
                        builder: (context, tsnap) {
                          if (tsnap.connectionState ==
                                  ConnectionState.waiting &&
                              !tsnap.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final turmas = tsnap.data ?? [];
                          if (turmas.isEmpty) {
                            return Text(
                              'Você ainda não tem turmas. Crie uma em "Turmas".',
                              style: TextStyle(color: Colors.grey.shade700),
                            );
                          }
                          return Column(
                            children: [
                              for (final t in turmas)
                                _cardTurma(
                                  prova,
                                  t,
                                  folhas.where((f) => f.turmaId == t.id).length,
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Versões',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in prova.versoes)
                        ChoiceChip(
                          label: Text('Versão ${v.numero}'),
                          selected: v.numero == versao.numero,
                          selectedColor: kCard,
                          onSelected: (_) =>
                              setState(() => _versaoSel = v.numero),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gabarito: $gabarito',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 12),
                  PreviaPapel(
                    titulo: prova.titulo,
                    subtitulo: 'Versão ${versao.numero}',
                    itens: itens,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _confirmarExclusao(prova),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Excluir prova',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
