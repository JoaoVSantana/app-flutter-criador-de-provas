import 'package:flutter/material.dart';

import '../../models/relatorio.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/relatorios/cartao_prova.dart';
import '../../widgets/relatorios/cartao_resumo.dart';
import '../../widgets/relatorios/estilo_relatorios.dart';
import 'relatorio_prova.dart';

/// Desempenho consolidado de uma turma: evolução das médias, ranking dos
/// alunos somando todas as provas e a lista das avaliações corrigidas.
class RelatorioTurmaScreen extends StatelessWidget {
  const RelatorioTurmaScreen({super.key, required this.resumo});

  final ResumoTurma resumo;

  /// Média de cada aluno considerando todas as provas da turma.
  List<_MediaAluno> _mediasPorAluno() {
    final acumulado = <String, _MediaAluno>{};

    for (final prova in resumo.provas) {
      for (final resultado in prova.resultados) {
        final chave = resultado.matricula;
        final registro = acumulado.putIfAbsent(
          chave,
          () => _MediaAluno(
            nome: resultado.nome,
            matricula: resultado.matricula,
          ),
        );
        registro.notas.add(resultado.nota(prova.questoes));
      }
    }

    final lista = acumulado.values.toList()
      ..sort((a, b) => b.media.compareTo(a.media));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final medias = _mediasPorAluno();
    final provas = resumo.porData;
    final abaixoDaMedia = medias.where((m) => m.media < 6).length;

    return Scaffold(
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
          TituloTela(
            titulo: resumo.turma,
            subtitulo: 'Desempenho da turma nas provas corrigidas',
            mostrarVoltar: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CartaoResumo(
                        rotulo: 'Média da turma',
                        valor: formatarNota(resumo.media),
                        icone: Icons.trending_up,
                        cor: corPorNota(resumo.media),
                        complemento: '${resumo.totalProvas} prova(s)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CartaoResumo(
                        rotulo: 'Aprovação',
                        valor: formatarPercentual(resumo.taxaAprovacao),
                        icone: Icons.verified_outlined,
                        cor: corPorAproveitamento(resumo.taxaAprovacao),
                        complemento: '$abaixoDaMedia abaixo da média',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CartaoResumo(
                        rotulo: 'Acertos',
                        valor: formatarPercentual(resumo.percentualAcerto),
                        icone: Icons.check_circle_outline,
                        cor: corPorAproveitamento(resumo.percentualAcerto),
                        complemento: '${resumo.totalAlunos} alunos',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Secao(
                  titulo: 'Evolução das médias',
                  descricao: 'Média da turma em cada avaliação, da mais antiga '
                      'para a mais recente',
                  filho: Column(
                    children: provas.map((prova) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 62,
                              child: Text(
                                prova.dataFormatada.substring(0, 5),
                                style: rotuloStyle,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prova.disciplina,
                                    style: const TextStyle(
                                        fontSize: 12, color: CoresRel.texto),
                                  ),
                                  const SizedBox(height: 4),
                                  BarraDesempenho(
                                    percentual: prova.media / 10,
                                    altura: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatarNota(prova.media),
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: corPorNota(prova.media),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _Secao(
                  titulo: 'Notas dos alunos',
                  descricao: 'Média de cada aluno somando as provas da turma',
                  filho: Column(
                    children: medias.map((aluno) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  corPorNota(aluno.media).withOpacity(0.15),
                              child: Text(
                                aluno.nome.substring(0, 1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: corPorNota(aluno.media),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12.5, color: CoresRel.texto),
                                  ),
                                  const SizedBox(height: 4),
                                  BarraDesempenho(
                                    percentual: aluno.media / 10,
                                    altura: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatarNota(aluno.media),
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: corPorNota(aluno.media),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Avaliações corrigidas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CoresRel.texto,
                    ),
                  ),
                ),
                ...resumo.provas.map(
                  (prova) => CartaoProva(
                    prova: prova,
                    margemHorizontal: 0,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RelatorioProvaScreen(prova: prova),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaAluno {
  _MediaAluno({required this.nome, required this.matricula});

  final String nome;
  final String matricula;
  final List<double> notas = [];

  double get media {
    if (notas.isEmpty) return 0;
    return notas.fold<double>(0, (a, b) => a + b) / notas.length;
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.descricao,
    required this.filho,
  });

  final String titulo;
  final String descricao;
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
          const SizedBox(height: 2),
          Text(descricao, style: rotuloStyle),
          const SizedBox(height: 10),
          filho,
        ],
      ),
    );
  }
}
