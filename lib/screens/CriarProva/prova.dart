import 'package:flutter/material.dart';

import '../../models/prova.dart' as model;
import '../../models/turma.dart';
import '../../service/prova_service.dart';
import '../../service/questao_service.dart';
import '../../service/turma_service.dart';
import '../BancoQuestoes/elem_comuns.dart';

class Prova extends StatefulWidget {
  const Prova({super.key});

  @override
  State<Prova> createState() => _ProvaState();
}

class _ProvaState extends State<Prova> {
  final _tituloController = TextEditingController();
  final _disciplinaController = TextEditingController();

  final _turmaService = TurmaService();
  final _questaoService = QuestaoService();
  final _provaService = ProvaService();

  late final Stream<List<Turma>> _turmasStream = _turmaService.getTurmas();
  late final Stream<List<Question>> _questoesStream =
      _questaoService.observarMinhas();
  late final Stream<List<model.Prova>> _provasStream =
      _provaService.getProvas();

  final Set<String> _turmasSelecionadasIds = {};
  final Set<String> _questoesSelecionadasIds = {};
  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _disciplinaController.dispose();
    super.dispose();
  }

  Future<void> _salvarProva(List<Turma> todasTurmas) async {
    final titulo = _tituloController.text.trim();
    final disciplina = _disciplinaController.text.trim();

    if (titulo.isEmpty) {
      _mostrarMsg('Informe o título da prova.');
      return;
    }
    if (_questoesSelecionadasIds.isEmpty) {
      _mostrarMsg('Selecione pelo menos uma questão para a prova.');
      return;
    }

    final turmasIds = _turmasSelecionadasIds.toList();
    final turmasNomes = todasTurmas
        .where((t) => _turmasSelecionadasIds.contains(t.id))
        .map((t) => t.nome)
        .toList();

    setState(() => _salvando = true);
    try {
      final novaProva = model.Prova(
        id: '',
        titulo: titulo,
        disciplina: disciplina,
        turmasIds: turmasIds,
        turmasNomes: turmasNomes,
        questoesIds: _questoesSelecionadasIds.toList(),
      );
      await _provaService.criarProva(novaProva);

      if (!mounted) return;
      _tituloController.clear();
      _disciplinaController.clear();
      setState(() {
        _turmasSelecionadasIds.clear();
        _questoesSelecionadasIds.clear();
      });
      _mostrarMsg('Prova salva com sucesso!');
    } catch (e) {
      if (!mounted) return;
      _mostrarMsg('Erro ao salvar prova: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _editarTurmasProva(
    model.Prova prova,
    List<Turma> todasTurmas,
  ) async {
    final selecionadas = Set<String>.from(prova.turmasIds);

    final salvou = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Turmas — ${prova.titulo}'),
              content: SingleChildScrollView(
                child: todasTurmas.isEmpty
                    ? const Text('Nenhuma turma cadastrada.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: todasTurmas.map((turma) {
                          final marcada = selecionadas.contains(turma.id);
                          return CheckboxListTile(
                            value: marcada,
                            title: Text(turma.nome),
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  selecionadas.add(turma.id);
                                } else {
                                  selecionadas.remove(turma.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGreen),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvou != true) return;

    final ids = selecionadas.toList();
    final nomes = todasTurmas
        .where((t) => selecionadas.contains(t.id))
        .map((t) => t.nome)
        .toList();

    try {
      await _provaService.atualizarTurmasDaProva(
        provaId: prova.id,
        turmasIds: ids,
        turmasNomes: nomes,
      );
      if (!mounted) return;
      _mostrarMsg('Turmas da prova atualizadas!');
    } catch (e) {
      if (!mounted) return;
      _mostrarMsg('Erro ao atualizar turmas: $e');
    }
  }

  void _mostrarMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Turma>>(
      stream: _turmasStream,
      builder: (context, turmasSnap) {
        final turmas = turmasSnap.data ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Montar prova')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título da prova',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _disciplinaController,
                decoration: const InputDecoration(
                  labelText: 'Disciplina / Matéria',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Atrelar às turmas (opcional — pode marcar várias)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (turmasSnap.connectionState == ConnectionState.waiting &&
                  !turmasSnap.hasData)
                const LinearProgressIndicator()
              else if (turmas.isEmpty)
                Text(
                  'Nenhuma turma cadastrada. Você pode salvar sem turma e atrelar depois.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: turmas.map((turma) {
                    final selecionada =
                        _turmasSelecionadasIds.contains(turma.id);
                    return FilterChip(
                      label: Text(turma.nome),
                      selected: selecionada,
                      onSelected: (marcado) {
                        setState(() {
                          if (marcado) {
                            _turmasSelecionadasIds.add(turma.id);
                          } else {
                            _turmasSelecionadasIds.remove(turma.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              const Text(
                'Selecione as questões',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Question>>(
                stream: _questoesStream,
                builder: (context, questoesSnap) {
                  if (questoesSnap.connectionState == ConnectionState.waiting &&
                      !questoesSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final questoes = questoesSnap.data ?? [];
                  if (questoes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhuma questão encontrada no banco.'),
                    );
                  }
                  return Column(
                    children: questoes.map((q) {
                      final marcada = _questoesSelecionadasIds.contains(q.id);
                      return CheckboxListTile(
                        value: marcada,
                        title: Text(
                          q.enunciado,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          q.assunto.isEmpty
                              ? q.materia
                              : '${q.materia} · ${q.assunto}',
                        ),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _questoesSelecionadasIds.add(q.id);
                            } else {
                              _questoesSelecionadasIds.remove(q.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kGreen),
                onPressed: _salvando ? null : () => _salvarProva(turmas),
                child: Text(_salvando ? 'Salvando...' : 'Salvar prova'),
              ),
              const Divider(height: 32),
              const Text(
                'Provas criadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<model.Prova>>(
                stream: _provasStream,
                builder: (context, provasSnap) {
                  final provas = provasSnap.data ?? [];
                  if (provas.isEmpty) {
                    return const Text('Nenhuma prova cadastrada ainda.');
                  }
                  return Column(
                    children: provas.map((prova) {
                      final turmasTexto = prova.turmasNomes.isEmpty
                          ? 'Sem turma atrelada'
                          : 'Turmas: ${prova.turmasNomes.join(', ')}';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(prova.titulo),
                          subtitle: Text(
                            '$turmasTexto · ${prova.questoesIds.length} questão(ões)',
                          ),
                          trailing: IconButton(
                            tooltip: 'Gerenciar turmas',
                            icon: const Icon(Icons.groups_outlined),
                            onPressed: () => _editarTurmasProva(prova, turmas),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}