import 'package:flutter/material.dart';

import '../../models/relatorio.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/relatorios/cartao_questao.dart';
import '../../widgets/relatorios/cartao_resumo.dart';
import '../../widgets/relatorios/estilo_relatorios.dart';
import '../../widgets/relatorios/grafico_faixas_notas.dart';
import 'relatorio_aluno.dart';

/// Relatório completo de uma prova: desempenho da turma, notas por aluno
/// e estatística de acertos por questão.
class RelatorioProvaScreen extends StatefulWidget {
  const RelatorioProvaScreen({super.key, required this.prova});

  final ProvaCorrigida prova;

  @override
  State<RelatorioProvaScreen> createState() => _RelatorioProvaScreenState();
}

class _RelatorioProvaScreenState extends State<RelatorioProvaScreen> {
  bool _somenteQuestoesCriticas = false;
  bool _ordenarPorNome = false;

  ProvaCorrigida get prova => widget.prova;

  void _exportarPlanilha() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CoresRel.verde,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Planilha de notas de "${prova.titulo}" pronta para exportação (.xlsx).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exportarPlanilha,
          backgroundColor: CoresRel.verde,
          icon: const Icon(Icons.table_view_outlined, color: Colors.white),
          label: const Text('Exportar', style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            TituloTela(
              titulo: prova.titulo,
              subtitulo:
                  '${prova.disciplina} · ${prova.turma} · corrigida em ${prova.dataFormatada}',
              mostrarVoltar: true,
            ),
            const TabBar(
              labelColor: CoresRel.verdeEscuro,
              unselectedLabelColor: CoresRel.textoSuave,
              indicatorColor: CoresRel.verde,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Resumo'),
                Tab(text: 'Notas'),
                Tab(text: 'Questões'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _abaResumo(),
                  _abaNotas(),
                  _abaQuestoes(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- RESUMO

  Widget _abaResumo() {
    final criticas = prova.questoesMaisErradas(limite: 3);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        Row(
          children: [
            Expanded(
              child: CartaoResumo(
                rotulo: 'Média',
                valor: formatarNota(prova.media),
                icone: Icons.trending_up,
                cor: corPorNota(prova.media),
                complemento: 'mediana ${formatarNota(prova.mediana)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CartaoResumo(
                rotulo: 'Maior nota',
                valor: formatarNota(prova.maiorNota),
                icone: Icons.arrow_upward,
                cor: CoresRel.bom,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CartaoResumo(
                rotulo: 'Menor nota',
                valor: formatarNota(prova.menorNota),
                icone: Icons.arrow_downward,
                cor: CoresRel.ruim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CartaoResumo(
                rotulo: 'Aprovados',
                valor: '${prova.aprovados}/${prova.totalAlunos}',
                icone: Icons.verified_outlined,
                cor: corPorAproveitamento(prova.taxaAprovacao),
                complemento:
                    '${formatarPercentual(prova.taxaAprovacao)} da turma',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CartaoResumo(
                rotulo: 'Acertos',
                valor: formatarPercentual(prova.percentualAcertoGeral),
                icone: Icons.check_circle_outline,
                cor: corPorAproveitamento(prova.percentualAcertoGeral),
                complemento: '${prova.totalQuestoes} questões',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Bloco(
          titulo: 'Distribuição das notas',
          descricao: 'Quantidade de alunos por faixa de nota',
          filho: GraficoFaixasNotas(faixas: prova.faixasDeNota),
        ),
        const SizedBox(height: 12),
        _Bloco(
          titulo: 'Questões que mais derrubaram a turma',
          descricao: 'Menor percentual de acerto — revisar em sala',
          filho: Column(
            children: criticas.map((est) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        'Q${est.questao.numero}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CoresRel.texto,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            est.questao.enunciado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: CoresRel.texto),
                          ),
                          const SizedBox(height: 4),
                          BarraDesempenho(
                            percentual: est.percentualAcerto,
                            altura: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatarPercentual(est.percentualAcerto),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: corPorAproveitamento(est.percentualAcerto),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _Bloco(
          titulo: 'Sobre a aplicação',
          descricao: null,
          filho: Column(
            children: [
              _LinhaInfo(rotulo: 'Código da prova', valor: prova.id),
              _LinhaInfo(
                  rotulo: 'Versões geradas', valor: '${prova.versoes}'),
              _LinhaInfo(
                rotulo: 'Folhas de resposta lidas',
                valor: '${prova.totalAlunos}',
              ),
              _LinhaInfo(
                rotulo: 'Nota mínima para aprovação',
                valor: formatarNota(prova.notaMinimaAprovacao),
              ),
              _LinhaInfo(
                rotulo: 'Questões em branco',
                valor:
                    '${prova.resultados.fold<int>(0, (a, r) => a + r.emBranco())}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- NOTAS

  Widget _abaNotas() {
    final lista = _ordenarPorNome
        ? ([...prova.resultados]..sort((a, b) => a.nome.compareTo(b.nome)))
        : prova.ranking;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '${prova.totalAlunos} alunos avaliados',
                style: rotuloStyle,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _ordenarPorNome = !_ordenarPorNome),
                icon: const Icon(Icons.swap_vert, size: 18),
                label: Text(
                  _ordenarPorNome ? 'Ordenar por nota' : 'Ordenar por nome',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(foregroundColor: CoresRel.verde),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final aluno = lista[index];
              final nota = aluno.nota(prova.questoes);
              final posicao = prova.ranking.indexOf(aluno) + 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: CoresRel.cartao,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RelatorioAlunoScreen(
                            prova: prova,
                            aluno: aluno,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CoresRel.borda),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                corPorNota(nota).withOpacity(0.15),
                            child: Text(
                              '$posicao',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: corPorNota(nota),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  aluno.nome,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CoresRel.texto,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Matrícula ${aluno.matricula} · '
                                  '${aluno.acertos(prova.questoes)}/${prova.totalQuestoes} acertos',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: CoresRel.textoSuave),
                                ),
                                const SizedBox(height: 6),
                                BarraDesempenho(
                                  percentual: aluno.percentual(prova.questoes),
                                  altura: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formatarNota(nota),
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: corPorNota(nota),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: CoresRel.textoSuave),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- QUESTÕES

  Widget _abaQuestoes() {
    final todas = prova.estatisticas;
    final visiveis = _somenteQuestoesCriticas
        ? todas.where((e) => e.percentualAcerto < 0.6).toList()
        : todas;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Acertos por questão e alternativa mais marcada',
                  style: rotuloStyle,
                ),
              ),
              Switch(
                value: _somenteQuestoesCriticas,
                activeColor: CoresRel.verde,
                onChanged: (valor) =>
                    setState(() => _somenteQuestoesCriticas = valor),
              ),
              const Text(
                'Só críticas',
                style: TextStyle(fontSize: 11, color: CoresRel.textoSuave),
              ),
            ],
          ),
        ),
        Expanded(
          child: visiveis.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nenhuma questão com aproveitamento abaixo de 60%.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: CoresRel.textoSuave),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: visiveis.length,
                  itemBuilder: (context, index) =>
                      CartaoQuestao(estatistica: visiveis[index]),
                ),
        ),
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.titulo,
    required this.descricao,
    required this.filho,
  });

  final String titulo;
  final String? descricao;
  final Widget filho;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresRel.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresRel.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CoresRel.texto,
            ),
          ),
          if (descricao != null) ...[
            const SizedBox(height: 2),
            Text(descricao!, style: rotuloStyle),
          ],
          const SizedBox(height: 12),
          filho,
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: rotuloStyle)),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CoresRel.texto,
            ),
          ),
        ],
      ),
    );
  }
}
