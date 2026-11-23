import 'package:flutter/material.dart';

import '../../models/provas.dart';
import '../../service/prova_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';
import 'atrelar_prova.dart';
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
  late final Stream<List<VinculoProva>> _vinculos = _service.observarVinculos(
    widget.provaId,
  );
  int _versaoSel = 1;

  void _confirmarExclusao(ProvaSalva prova) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir prova?'),
        content: Text(
          'A prova "${prova.titulo}" e a atribuição dela aos alunos serão '
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
                  // Menu lateral + título da prova
                  MenuTitle(title: prova.titulo, fontSize: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 4),
                    child: Text(
                      '${prova.questoes.length} questões · ${prova.versoes.length} versões',
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AtrelarProvaPage(prova: prova),
                        ),
                      ),
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Atrelar a alunos/turmas'),
                    ),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Alunos com esta prova',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<VinculoProva>>(
                    stream: _vinculos,
                    builder: (context, vsnap) {
                      final lista = vsnap.data ?? [];
                      if (lista.isEmpty) {
                        return Text(
                          'Ainda não foi atrelada a nenhum aluno.',
                          style: TextStyle(color: Colors.grey.shade700),
                        );
                      }
                      return Column(
                        children: [
                          for (final v in lista)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(v.alunoNome),
                              subtitle: Text(v.turmaNome),
                              trailing: Text(
                                'Versão ${v.versao}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
