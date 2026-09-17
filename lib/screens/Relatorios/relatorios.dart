import 'package:flutter/material.dart';

import '../../data/mock_relatorios.dart';
import '../../models/relatorio.dart';
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

  String _turmaSelecionada = 'Todas';
  String _disciplinaSelecionada = 'Todas';
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<ProvaCorrigida> get _provasFiltradas {
    return provasCorrigidasMock.where((prova) {
      final porTurma =
          _turmaSelecionada == 'Todas' || prova.turma == _turmaSelecionada;
      final porDisciplina = _disciplinaSelecionada == 'Todas' ||
          prova.disciplina == _disciplinaSelecionada;
      final texto = _busca.trim().toLowerCase();
      final porTexto = texto.isEmpty ||
          prova.titulo.toLowerCase().contains(texto) ||
          prova.disciplina.toLowerCase().contains(texto) ||
          prova.turma.toLowerCase().contains(texto);
      return porTurma && porDisciplina && porTexto;
    }).toList()
      ..sort((a, b) => b.dataCorrecao.compareTo(a.dataCorrecao));
  }

  double get _mediaGeral {
    final provas = _provasFiltradas;
    if (provas.isEmpty) return 0;
    return provas.fold<double>(0, (a, p) => a + p.media) / provas.length;
  }

  double get _aproveitamentoGeral {
    final provas = _provasFiltradas;
    if (provas.isEmpty) return 0;
    return provas.fold<double>(0, (a, p) => a + p.percentualAcertoGeral) /
        provas.length;
  }

  int get _totalCorrecoes =>
      _provasFiltradas.fold<int>(0, (a, p) => a + p.totalAlunos);

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
    final provas = _provasFiltradas;

    return Column(
      children: [
        _painelResumo(),
        _filtros(),
        Expanded(
          child: provas.isEmpty
              ? const _ListaVazia(
                  mensagem:
                      'Nenhuma prova corrigida encontrada com esses filtros.',
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

  Widget _painelResumo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: CartaoResumo(
              rotulo: 'Provas',
              valor: '${_provasFiltradas.length}',
              icone: Icons.fact_check_outlined,
              complemento: '$_totalCorrecoes correções',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CartaoResumo(
              rotulo: 'Média',
              valor: formatarNota(_mediaGeral),
              icone: Icons.trending_up,
              cor: corPorNota(_mediaGeral),
              complemento: 'geral das provas',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CartaoResumo(
              rotulo: 'Acertos',
              valor: formatarPercentual(_aproveitamentoGeral),
              icone: Icons.check_circle_outline,
              cor: corPorAproveitamento(_aproveitamentoGeral),
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
                  opcoes: turmasMock(),
                  onChanged: (valor) =>
                      setState(() => _turmaSelecionada = valor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SeletorFiltro(
                  icone: Icons.menu_book_outlined,
                  valor: _disciplinaSelecionada,
                  opcoes: disciplinasMock(),
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
    final resumos = resumosPorTurmaMock();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: resumos.length,
      itemBuilder: (context, index) {
        final resumo = resumos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: CoresRel.cartao,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _abrirTurma(resumo),
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
                          formatarNota(resumo.media),
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: corPorNota(resumo.media),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BarraDesempenho(percentual: resumo.percentualAcerto),
                    const SizedBox(height: 8),
                    Text(
                      '${resumo.totalProvas} prova(s) corrigida(s) · '
                      '${resumo.totalAlunos} alunos · '
                      '${formatarPercentual(resumo.taxaAprovacao)} de aprovação',
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
                value: valor,
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
