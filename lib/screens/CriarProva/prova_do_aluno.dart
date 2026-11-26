import 'package:flutter/material.dart';

import '../../models/provas.dart';
import '../../service/prova_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';
import 'previa_papel.dart';

import 'package:printing/printing.dart';

import 'pdf_prova.dart';

class ProvaDoAlunoPage extends StatefulWidget {
  final ProvaSalva prova;
  final FolhaAluno folha;

  const ProvaDoAlunoPage({super.key, required this.prova, required this.folha});

  @override
  State<ProvaDoAlunoPage> createState() => _ProvaDoAlunoPageState();
}

class _ProvaDoAlunoPageState extends State<ProvaDoAlunoPage> {
  final _service = ProvaService();
  bool _gerando = false;

  String _nomeArquivo() {
    final base =
        '${widget.prova.titulo}_${widget.folha.alunoNome}'
        '_V${widget.folha.versao}';
    final limpo = base.replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ]+'), '_');
    return '$limpo.pdf';
  }

  Future<void> _baixarPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _gerando = true);
    try {
      final bytes = await gerarPdfProvaAluno(
        prova: widget.prova,
        folha: widget.folha,
      );
      await Printing.sharePdf(bytes: bytes, filename: _nomeArquivo());
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao gerar o PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  void _confirmarRemocao() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover prova do aluno?'),
        content: Text(
          'A prova de ${widget.folha.alunoNome} (código ${widget.folha.codigo}) '
          'será removida e esse código deixa de valer.',
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
                await _service.removerFolha(
                  widget.prova.id,
                  widget.folha.alunoId,
                );
                if (mounted) Navigator.pop(context);
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
    final folha = widget.folha;
    final prova = widget.prova;
    final itens = prova.versao(folha.versao).montar(prova.questoes);
    final gabarito = [
      for (var i = 0; i < folha.gabarito.length; i++)
        '${i + 1}-${String.fromCharCode(65 + folha.gabarito[i])}',
    ].join('   ');
    final autoria = [
      if (folha.criadoPorNome.isNotEmpty) 'Criada por ${folha.criadoPorNome}',
      if (folha.criadoEm != null) 'em ${formatarData(folha.criadoEm)}',
    ].join(' ');

    return Scaffold(
      drawer: const DrawerNav(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Header(),
      ),
      bottomNavigationBar: Navegar(onVoltar: () => Navigator.pop(context)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuTitle(title: folha.alunoNome, fontSize: 24),
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4),
                child: Text(
                  '${folha.turmaNome} · Versão ${folha.versao}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              if (autoria.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 2),
                  child: Text(
                    autoria,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _gerando ? null : _baixarPdf,
                  icon: _gerando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_gerando ? 'Gerando...' : 'Baixar PDF'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gabarito: $gabarito',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 12),
              PreviaPapel(
                titulo: prova.titulo,
                subtitulo: 'Versão ${folha.versao}',
                itens: itens,
                nomeAluno: folha.alunoNome,
                turmaNome: folha.turmaNome,
                codigo: folha.codigo,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _confirmarRemocao,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Remover prova do aluno',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
