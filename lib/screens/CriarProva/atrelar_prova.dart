import 'package:flutter/material.dart';

import '../../models/aluno.dart';
import '../../models/provas.dart';
import '../../models/turma.dart';
import '../../service/aluno_service.dart';
import '../../service/prova_service.dart';
import '../../service/turma_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';

class AtrelarProvaPage extends StatefulWidget {
  final ProvaSalva prova;
  const AtrelarProvaPage({super.key, required this.prova});

  @override
  State<AtrelarProvaPage> createState() => _AtrelarProvaPageState();
}

class _AtrelarProvaPageState extends State<AtrelarProvaPage> {
  final _provaService = ProvaService();
  final _alunoService = AlunoService();
  late final Stream<List<Turma>> _turmasStream = TurmaService().getTurmas();

  Turma? _turma;
  Stream<List<Aluno>>? _alunosStream;
  List<Aluno> _alunosAtuais = [];
  final Set<String> _marcados = {};
  bool _salvando = false;

  void _escolherTurma(Turma t) {
    setState(() {
      _turma = t;
      _marcados.clear();
      _alunosAtuais = [];
      _alunosStream = _alunoService.getAlunosPorTurma(t.id);
    });
  }

  Future<void> _aplicar() async {
    final turma = _turma;
    if (turma == null || _marcados.isEmpty) return;

    final escolhidos = _alunosAtuais
        .where((a) => _marcados.contains(a.id))
        .toList();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _salvando = true);
    try {
      final r = await _provaService.atrelar(
        prova: widget.prova,
        turmaId: turma.id,
        turmaNome: turma.nome,
        alunos: escolhidos,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r.jaTinham == 0
                ? 'Prova aplicada a ${r.novos} aluno(s).'
                : 'Prova aplicada a ${r.novos} aluno(s). '
                      '${r.jaTinham} já tinha(m) essa prova.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      messenger.showSnackBar(SnackBar(content: Text('Erro ao atrelar: $e')));
    }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MenuTitle(title: 'Atrelar prova', fontSize: 22),
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4, bottom: 12),
                child: Text(
                  widget.prova.titulo,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),

              StreamBuilder<List<Turma>>(
                stream: _turmasStream,
                builder: (context, snap) {
                  final turmas = snap.data ?? [];
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const LinearProgressIndicator();
                  }
                  if (turmas.isEmpty) {
                    return Text(
                      'Você ainda não tem turmas. Crie uma em "Turmas".',
                      style: TextStyle(color: Colors.grey.shade700),
                    );
                  }
                  return InputDecorator(
                    isEmpty: _turma == null,
                    decoration: InputDecoration(
                      labelText: 'Turma',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: turmas.any((t) => t.id == _turma?.id)
                            ? _turma!.id
                            : null,
                        isDense: true,
                        isExpanded: true,
                        items: [
                          for (final t in turmas)
                            DropdownMenuItem(value: t.id, child: Text(t.nome)),
                        ],
                        onChanged: (id) {
                          if (id == null) return;
                          _escolherTurma(turmas.firstWhere((t) => t.id == id));
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _alunosStream == null
                    ? Center(
                        child: Text(
                          'Escolha uma turma para ver os alunos.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : StreamBuilder<List<Aluno>>(
                        stream: _alunosStream,
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(
                              child: Text('Erro ao carregar: ${snap.error}'),
                            );
                          }
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final alunos = snap.data!;
                          _alunosAtuais = alunos;

                          if (alunos.isEmpty) {
                            return const Center(
                              child: Text('Esta turma ainda não tem alunos.'),
                            );
                          }

                          final todos = _marcados.length == alunos.length;
                          return ListView(
                            children: [
                              CheckboxListTile(
                                value: todos,
                                activeColor: kGreen,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  'Turma inteira',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _marcados.addAll(alunos.map((a) => a.id));
                                  } else {
                                    _marcados.clear();
                                  }
                                }),
                              ),
                              const Divider(height: 1),
                              for (final a in alunos)
                                CheckboxListTile(
                                  value: _marcados.contains(a.id),
                                  activeColor: kGreen,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(a.nome),
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _marcados.add(a.id);
                                    } else {
                                      _marcados.remove(a.id);
                                    }
                                  }),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (_marcados.isEmpty || _salvando) ? null : _aplicar,
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Aplicar prova (${_marcados.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
