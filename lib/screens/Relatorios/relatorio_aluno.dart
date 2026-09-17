import 'package:flutter/material.dart';

import '../../models/relatorio.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/relatorios/cartao_resumo.dart';
import '../../widgets/relatorios/estilo_relatorios.dart';

/// Espelho da correção de um aluno: mostra, questão a questão, qual
class RelatorioAlunoScreen extends StatelessWidget {
  const RelatorioAlunoScreen({
    super.key,
    required this.prova,
    required this.aluno,
  });

  final ProvaCorrigida prova;
  final ResultadoAluno aluno;

  @override
  Widget build(BuildContext context) {
    final nota = aluno.nota(prova.questoes);
    final acertos = aluno.acertos(prova.questoes);
    final brancos = aluno.emBranco();
    final erros = prova.totalQuestoes - acertos - brancos;

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
            titulo: aluno.nome,
            subtitulo:
                'Matrícula ${aluno.matricula} · ${prova.turma} · ${prova.titulo}',
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
                        rotulo: 'Nota',
                        valor: formatarNota(nota),
                        icone: Icons.grade_outlined,
                        cor: corPorNota(nota),
                        complemento:
                            nota >= prova.notaMinimaAprovacao
                                ? 'aprovado'
                                : 'abaixo da média',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CartaoResumo(
                        rotulo: 'Acertos',
                        valor: '$acertos/${prova.totalQuestoes}',
                        icone: Icons.check_circle_outline,
                        cor: CoresRel.bom,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CartaoResumo(
                        rotulo: 'Erros',
                        valor: '$erros',
                        icone: Icons.cancel_outlined,
                        cor: CoresRel.ruim,
                        complemento: '$brancos em branco',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Respostas questão a questão',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CoresRel.texto,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'A alternativa marcada fica ao lado do gabarito, para analisar '
                  'onde o aluno se confundiu.',
                  style: rotuloStyle,
                ),
                const SizedBox(height: 10),
                ...List.generate(prova.questoes.length, (i) {
                  final questao = prova.questoes[i];
                  final marcada =
                      i < aluno.respostas.length ? aluno.respostas[i] : null;
                  return _LinhaResposta(
                    questao: questao,
                    marcada: marcada,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaResposta extends StatelessWidget {
  const _LinhaResposta({required this.questao, required this.marcada});

  final Questao questao;
  final String? marcada;

  @override
  Widget build(BuildContext context) {
    final emBranco = marcada == null;
    final correta = marcada == questao.gabarito;
    final cor = emBranco
        ? CoresRel.textoSuave
        : (correta ? CoresRel.bom : CoresRel.ruim);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CoresRel.cartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CoresRel.borda),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${questao.numero}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questao.enunciado,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: CoresRel.texto),
                ),
                if (questao.assunto.isNotEmpty)
                  Text(questao.assunto, style: rotuloStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Bolinha(
            letra: emBranco ? '—' : marcada!,
            cor: cor,
            rotulo: 'marcou',
          ),
          const SizedBox(width: 6),
          _Bolinha(
            letra: questao.gabarito,
            cor: CoresRel.verde,
            rotulo: 'gabarito',
          ),
          const SizedBox(width: 6),
          Icon(
            emBranco
                ? Icons.remove_circle_outline
                : (correta ? Icons.check_circle : Icons.cancel),
            color: cor,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _Bolinha extends StatelessWidget {
  const _Bolinha({
    required this.letra,
    required this.cor,
    required this.rotulo,
  });

  final String letra;
  final Color cor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cor),
            color: cor.withOpacity(0.10),
          ),
          child: Text(
            letra,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(rotulo, style: const TextStyle(fontSize: 9, color: CoresRel.textoSuave)),
      ],
    );
  }
}
