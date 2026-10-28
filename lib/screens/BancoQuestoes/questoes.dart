import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'elem_comuns.dart';
import 'criar_questao.dart';
import 'pesquisar_questao.dart';
import '/service/questao_service.dart'; // AJUSTE o caminho (Ctrl+. corrige)

// ---------------------------------------------------------------------------
// Tela principal do Banco de Questões
// ---------------------------------------------------------------------------
class ListaQuestoes extends StatefulWidget {
  const ListaQuestoes({super.key});

  @override
  State<ListaQuestoes> createState() => _ListaQuestoesState();
}

class _ListaQuestoesState extends State<ListaQuestoes> {
  final _service = QuestaoService();

  // Criado uma vez só, para o stream não reiniciar a cada rebuild
  late final Stream<List<Question>> _stream = _service.observarMinhas();

  Future<void> _openCreate() async {
    final q = await showModalBottomSheet<Question>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreateQuestionSheet(),
    );
    if (q == null || !mounted) return;

    try {
      await _service.criar(q);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questão criada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar a questão: $e')));
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchQuestionsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Question>>(
      stream: _stream,
      builder: (context, snap) {
        final todas = snap.data ?? [];
        final recentes = todas.take(3).toList();

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MenuTitle(title: 'Banco de questões', fontSize: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Crie questões novas ou encontre as que já estão no banco.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _BigButton(
                          icon: Icons.search,
                          label: 'Pesquisar questão',
                          onTap: _openSearch,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BigButton(
                          icon: Icons.add_circle_outline,
                          label: 'Criar questão',
                          onTap: _openCreate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'Últimas questões',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${todas.length} no banco',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snap.hasError)
                    Text('Erro ao carregar: ${snap.error}')
                  else if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (recentes.isEmpty)
                    const EmptyState()
                  else
                    ...recentes.map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuestionCard(question: q),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: kGreen),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
