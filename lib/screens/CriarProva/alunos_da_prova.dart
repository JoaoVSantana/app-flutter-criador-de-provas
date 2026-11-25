import 'package:flutter/material.dart';

import '../../models/aluno.dart';
import '../../models/provas.dart';
import '../../models/turma.dart';
import '../../service/aluno_service.dart';
import '../../service/prova_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';
import 'prova_do_aluno.dart';

class AlunosDaProvaPage extends StatefulWidget {
  final ProvaSalva prova;
  final Turma turma;

  const AlunosDaProvaPage({
    super.key,
    required this.prova,
    required this.turma,
  });

  @override
  State<AlunosDaProvaPage> createState() => _AlunosDaProvaPageState();
}

class _AlunosDaProvaPageState extends State<AlunosDaProvaPage> {
  final _provaService = ProvaService();
  final _alunoService = AlunoService();
  late final Stream<List<Aluno>> _alunos = _alunoService.getAlunosPorTurma(
    widget.turma.id,
  );
  late final Stream<List<FolhaAluno>> _folhas = _provaService.observarFolhas(
    widget.prova.id,
  );
  bool _salvando = false;

  Future<void> _atrelar(List<Aluno> alunos) async {
    if (alunos.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _salvando = true);
    try {
      final r = await _provaService.atrelar(
        prova: widget.prova,
        turmaId: widget.turma.id,
        turmaNome: widget.turma.nome,
        alunos: alunos,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Prova atrelada a ${r.novos} aluno(s).')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao atrelar: $e')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirFolha(FolhaAluno folha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaDoAlunoPage(prova: widget.prova, folha: folha),
      ),
    );
  }

  void _confirmarRemocao(FolhaAluno folha) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover prova do aluno?'),
        content: Text(
          'A prova de ${folha.alunoNome} (código ${folha.codigo}) será '
          'removida e esse código deixa de valer.',
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
                await _provaService.removerFolha(
                  widget.prova.id,
                  folha.alunoId,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
              }
            },
            child: const Text(
              'Remover',
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
      bottomNavigationBar: Navegar(onVoltar: () => Navigator.pop(context)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuTitle(title: widget.turma.nome, fontSize: 24),
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4, bottom: 12),
                child: Text(
                  widget.prova.titulo,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Aluno>>(
                  stream: _alunos,
                  builder: (context, asnap) {
                    if (asnap.hasError) {
                      return Center(
                        child: Text('Erro ao carregar: ${asnap.error}'),
                      );
                    }
                    if (!asnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final alunos = asnap.data!;
                    if (alunos.isEmpty) {
                      return const Center(
                        child: Text('Esta turma ainda não tem alunos.'),
                      );
                    }

                    return StreamBuilder<List<FolhaAluno>>(
                      stream: _folhas,
                      builder: (context, fsnap) {
                        if (fsnap.hasError) {
                          return Center(
                            child: Text('Erro ao carregar: ${fsnap.error}'),
                          );
                        }
                        final folhas = {
                          for (final f in fsnap.data ?? <FolhaAluno>[])
                            f.alunoId: f,
                        };
                        final semProva = alunos
                            .where((a) => !folhas.containsKey(a.id))
                            .toList();

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: kGreen,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: (semProva.isEmpty || _salvando)
                                    ? null
                                    : () => _atrelar(semProva),
                                icon: const Icon(Icons.group_add_outlined),
                                label: Text(
                                  semProva.isEmpty
                                      ? 'Todos os alunos já têm a prova'
                                      : 'Atrelar aos alunos sem prova (${semProva.length})',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final aluno in alunos)
                              Builder(
                                builder: (context) {
                                  final folha = folhas[aluno.id];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.person_outline,
                                      color: Colors.green[700],
                                      size: 28,
                                    ),
                                    title: Text(aluno.nome),
                                    subtitle: Text(
                                      folha == null
                                          ? 'Sem prova'
                                          : 'Versão ${folha.versao} · ${folha.codigo}',
                                    ),
                                    onTap: folha == null
                                        ? null
                                        : () => _abrirFolha(folha),
                                    trailing: folha == null
                                        ? TextButton(
                                            onPressed: _salvando
                                                ? null
                                                : () => _atrelar([aluno]),
                                            child: const Text('Atrelar'),
                                          )
                                        : PopupMenuButton<String>(
                                            onSelected: (v) {
                                              if (v == 'ver') {
                                                _abrirFolha(folha);
                                              } else {
                                                _confirmarRemocao(folha);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'ver',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.description_outlined,
                                                  ),
                                                  title: Text(
                                                    'Ver prova e QR code',
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'remover',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  title: Text(
                                                    'Remover prova',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            ],
                                          ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
