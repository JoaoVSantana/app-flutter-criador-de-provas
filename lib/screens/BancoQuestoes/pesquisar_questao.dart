import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'elem_comuns.dart';
import '/service/questao_service.dart';
import 'acoes_questao.dart';

class SearchQuestionsPage extends StatefulWidget {
  const SearchQuestionsPage({super.key});

  @override
  State<SearchQuestionsPage> createState() => _SearchQuestionsPageState();
}

class _SearchQuestionsPageState extends State<SearchQuestionsPage> {
  final _service = QuestaoService();

  late final Stream<List<Question>> _stream = _service.observarMinhas();

  String _texto = '';
  Nivel? _nivel;
  String? _materia;

  List<Question> _filtrar(List<Question> todas) {
    return todas.where((q) {
      final t = _texto.toLowerCase();
      final okTexto =
          t.isEmpty ||
          q.enunciado.toLowerCase().contains(t) ||
          q.assunto.toLowerCase().contains(t) ||
          q.codigo.toLowerCase().contains(t);
      final okNivel = _nivel == null || q.nivel == _nivel;
      final okMateria = _materia == null || q.materia == _materia;
      return okTexto && okNivel && okMateria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Question>>(
      stream: _stream,
      builder: (context, snap) {
        final todas = snap.data ?? [];
        final lista = _filtrar(todas);
        final materias = todas.map((q) => q.materia).toSet().toList()..sort();

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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MenuTitle(title: 'Pesquisar questão', fontSize: 26),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setState(() => _texto = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por enunciado ou assunto',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: kListCard,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Filter<String>(
                        icon: Icons.menu_book_outlined,
                        allLabel: 'Todas as matérias',
                        value: _materia,
                        options: {for (final m in materias) m: m},
                        onChanged: (v) => setState(() => _materia = v),
                      ),
                      _Filter<Nivel>(
                        icon: Icons.signal_cellular_alt,
                        allLabel: 'Todos os níveis',
                        value: _nivel,
                        options: {for (final n in Nivel.values) n: n.label},
                        onChanged: (v) => setState(() => _nivel = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${lista.length} questão(ões) encontrada(s)',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: snap.hasError
                        ? Text('Erro ao carregar: ${snap.error}')
                        : snap.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : lista.isEmpty
                        ? const Align(
                            alignment: Alignment.topCenter,
                            child: EmptyState(),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: lista.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => QuestionCard(
                              question: lista[i],
                              onEdit: () => editarQuestao(context, lista[i]),
                              onDelete: () => excluirQuestao(context, lista[i]),
                            ),
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

class _Filter<T> extends StatelessWidget {
  final IconData icon;
  final String allLabel;
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  const _Filter({
    required this.icon,
    required this.allLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kListCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: [
                DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
                ...options.entries.map(
                  (e) =>
                      DropdownMenuItem<T?>(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
