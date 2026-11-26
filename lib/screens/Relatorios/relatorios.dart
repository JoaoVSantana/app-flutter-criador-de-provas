import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/relatorio.dart';
import '../../models/turma.dart';
import '../../service/relatorio_service.dart';
import '../../service/turma_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/relatorios/cartao_prova.dart';
import '../../widgets/relatorios/cartao_resumo.dart';
import '../../widgets/relatorios/estilo_relatorios.dart';
import 'relatorio_prova.dart';
import 'relatorio_turma.dart';

/// Tela inicial dos relatórios: lista das provas já corrigidas e o
/// consolidado por turma.
class Relatorios extends StatefulWidget {
  const Relatorios({super.key});

  @override
  State<Relatorios> createState() => _RelatoriosState();
}

class _RelatoriosState extends State<Relatorios> {
  final TextEditingController _buscaController = TextEditingController();
  final RelatorioService _relatorioService = RelatorioService();
  final TurmaService _turmaService = TurmaService();

  StreamSubscription<List<ProvaCorrigida>>? _subProvas;
  StreamSubscription<List<Turma>>? _subTurmas;

  // Dados vindos do Firestore
  List<ProvaCorrigida> _provas = [];
  List<Turma> _turmas = [];
  final Map<String, int> _alunosPorTurma = {};

  bool _carregandoProvas = true;
  bool _carregandoTurmas = true;
  Object? _erro;

  String _turmaSelecionada = 'Todas';
  String _disciplinaSelecionada = 'Todas';
  String _busca = '';

  @override
  void initState() {
    super.initState();

    _subProvas = _relatorioService.observarProvasCorrigidas().listen(
      (provas) {
        if (!mounted) return;
        setState(() {
          _provas = provas;
          _carregandoProvas = false;
          _erro = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _carregandoProvas = false;
          _erro = e;
        });
      },
    );

    _subTurmas = _turmaService.getTurmas().listen(
      (turmas) {
        if (!mounted) return;
        setState(() {
          _turmas = turmas;
          _carregandoTurmas = false;
        });
        _carregarContagemAlunos(turmas);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _carregandoTurmas = false;
          _erro = e;
        });
      },
    );
  }

  @override
  void dispose() {
    _subProvas?.cancel();
    _subTurmas?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  /// Busca no banco quantos alunos cada turma tem cadastrados.
  Future<void> _carregarContagemAlunos(List<Turma> turmas) async {
    for (final turma in turmas) {
      try {
        final total = await _relatorioService.contarAlunos(turma.id);
        if (!mounted) return;
        setState(() => _alunosPorTurma[turma.id] = total);
      } catch (_) {
        // Sem a contagem a tela usa o número de alunos já corrigidos.
      }
    }
  }

  // ------------------------------------------------------------- filtros

  static String _normalizar(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  bool _provaDaTurma(ProvaCorrigida prova, Turma turma) {
    if (prova.turmaId.isNotEmpty) return prova.turmaId == turma.id;
    return _normalizar(prova.turma) == _normalizar(turma.nome);
  }

  /// Turma escolhida no filtro (null = "Todas").
  Turma? get _turmaFiltro {
    if (_turmaSelecionada == 'Todas') return null;
    for (final turma in _turmas) {
      if (turma.nome == _turmaSelecionada) return turma;
    }
    return null;
  }

  /// Opções do filtro de turma: as turmas cadastradas no banco.
  List<String> get _opcoesTurma =>
      ['Todas', ..._turmas.map((t) => t.nome)];

  /// Opções do filtro de disciplina: as que existem nas provas do banco.
  List<String> get _opcoesDisciplina {
    final set = _provas.map((p) => p.disciplina).toSet().toList()..sort();
    return ['Todas', ...set];
  }

  List<ProvaCorrigida> get _provasFiltradas {
    final turma = _turmaFiltro;
    final texto = _busca.trim().toLowerCase();

    return _provas.where((prova) {
      final porTurma = turma == null || _provaDaTurma(prova, turma);
      final porDisciplina = _disciplinaSelecionada == 'Todas' ||
          prova.disciplina == _disciplinaSelecionada;
      final porTexto = texto.isEmpty ||
          prova.titulo.toLowerCase().contains(texto) ||
          prova.disciplina.toLowerCase().contains(texto) ||
          prova.turma.toLowerCase().contains(texto);
      return porTurma && porDisciplina && porTexto;
    }).toList()
      ..sort((a, b) => b.dataCorrecao.compareTo(a.dataCorrecao));
  }

  void _abrirProva(ProvaCorrigida prova) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RelatorioProvaScreen(prova: prova)),
    );
  }

  void _abrirTurma(ResumoTurma resumo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RelatorioTurmaScreen(resumo: resumo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: CoresRel.fundo,
        drawer: const DrawerNav(),
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Header(),
        ),
        bottomNavigationBar: Navegar(
          onVoltar: () => Navigator.pop(context),
          onAvancar: null,
        ),
        body: Column(
          children: [
            const TituloTela(
              titulo: 'Relatórios',
              subtitulo: 'Provas corrigidas, notas e estatísticas',
            ),
            const TabBar(
              labelColor: CoresRel.verdeEscuro,
              unselectedLabelColor: CoresRel.textoSuave,
              indicatorColor: CoresRel.verde,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Provas corrigidas'),
                Tab(text: 'Turmas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _abaProvas(),
                  _abaTurmas(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- PROVAS

  Widget _abaProvas() {
    if (_carregandoProvas) {
      return const Center(
        child: CircularProgressIndicator(color: CoresRel.verde),
      );
    }
    if (_erro != null && _provas.isEmpty) {
      return _ListaVazia(
        mensagem: 'Não foi possível carregar as provas corrigidas.\n$_erro',
      );
    }

    final provas = _provasFiltradas;

    return Column(
      children: [
        _painelResumo(provas),
        _filtros(),
        Expanded(
          child: provas.isEmpty
              ? _ListaVazia(
                  mensagem: _provas.isEmpty
                      ? 'Nenhuma prova corrigida ainda. Corrija uma prova '
                          'para ela aparecer aqui.'
                      : 'Nenhuma prova corrigida encontrada com esses filtros.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: provas.length,
                  itemBuilder: (context, index) {
                    final prova = provas[index];
                    return CartaoProva(
                      prova: prova,
                      onTap: () => _abrirProva(prova),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Quadros de resumo: sempre calculados sobre as provas filtradas, então
  /// ao escolher uma turma mostram os números daquela turma.
  Widget _painelResumo(List<ProvaCorrigida> provas) {
    final resumo = ResumoTurma(turma: _turmaSelecionada, provas: provas);
    final daTurma = _turmaFiltro != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: CartaoResumo(
              rotulo: 'Provas',
              valor: '${resumo.totalProvas}',
              icone: Icons.fact_check_outlined,
              complemento: '${resumo.totalCorrecoes} correções',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CartaoResumo(
              rotulo: 'Média',
              valor: formatarNota(resumo.media),
              icone: Icons.trending_up,
              cor: corPorNota(resumo.media),
              complemento: daTurma ? 'da turma' : 'geral das provas',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CartaoResumo(
              rotulo: 'Acertos',
              valor: formatarPercentual(resumo.percentualAcerto),
              icone: Icons.check_circle_outline,
              cor: corPorAproveitamento(resumo.percentualAcerto),
              complemento: 'das respostas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _buscaController,
            onChanged: (valor) => setState(() => _busca = valor),
            decoration: InputDecoration(
              hintText: 'Buscar por prova, disciplina ou turma',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: CoresRel.cartao,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CoresRel.borda),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CoresRel.borda),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CoresRel.verde),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SeletorFiltro(
                  icone: Icons.groups_outlined,
                  valor: _turmaSelecionada,
                  opcoes: _opcoesTurma,
                  onChanged: (valor) =>
                      setState(() => _turmaSelecionada = valor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SeletorFiltro(
                  icone: Icons.menu_book_outlined,
                  valor: _disciplinaSelecionada,
                  opcoes: _opcoesDisciplina,
                  onChanged: (valor) =>
                      setState(() => _disciplinaSelecionada = valor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- TURMAS

  Widget _abaTurmas() {
    if (_carregandoTurmas || _carregandoProvas) {
      return const Center(
        child: CircularProgressIndicator(color: CoresRel.verde),
      );
    }
    if (_turmas.isEmpty) {
      return const _ListaVazia(
        mensagem: 'Nenhuma turma cadastrada. Crie uma turma para ver o '
            'desempenho dela aqui.',
      );
    }

    // Uma linha por turma cadastrada no banco, com as provas dela.
    final resumos = _turmas.map((turma) {
      return ResumoTurma(
        turma: turma.nome,
        turmaId: turma.id,
        provas: _provas.where((p) => _provaDaTurma(p, turma)).toList(),
        alunosCadastrados: _alunosPorTurma[turma.id],
      );
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: resumos.length,
      itemBuilder: (context, index) {
        final resumo = resumos[index];
        final temProvas = resumo.totalProvas > 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: CoresRel.cartao,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (temProvas) {
                  _abrirTurma(resumo);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Esta turma ainda não tem provas corrigidas.',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CoresRel.borda),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_outlined,
                            color: CoresRel.verde, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resumo.turma,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CoresRel.texto,
                            ),
                          ),
                        ),
                        Text(
                          temProvas ? formatarNota(resumo.media) : '—',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: temProvas
                                ? corPorNota(resumo.media)
                                : CoresRel.textoSuave,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BarraDesempenho(
                      percentual: temProvas ? resumo.percentualAcerto : 0,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      temProvas
                          ? '${resumo.totalProvas} prova(s) corrigida(s) · '
                              '${resumo.totalAlunos} alunos · '
                              '${formatarPercentual(resumo.taxaAprovacao)} '
                              'de aprovação'
                          : 'Nenhuma prova corrigida · '
                              '${resumo.totalAlunos} alunos',
                      style: rotuloStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeletorFiltro extends StatelessWidget {
  const _SeletorFiltro({
    required this.icone,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
  });

  final IconData icone;
  final String valor;
  final List<String> opcoes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CoresRel.cartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoresRel.borda),
      ),
      child: Row(
        children: [
          Icon(icone, size: 16, color: CoresRel.verde),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: opcoes.contains(valor) ? valor : opcoes.first,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: CoresRel.texto),
                items: opcoes
                    .map((op) => DropdownMenuItem(value: op, child: Text(op)))
                    .toList(),
                onChanged: (novo) {
                  if (novo != null) onChanged(novo);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 40, color: CoresRel.textoSuave),
            const SizedBox(height: 10),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: CoresRel.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
