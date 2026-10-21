import 'package:flutter/material.dart';

import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../widgets/drawernav.dart';
import 'elem_comuns.dart';

// ---------------------------------------------------------------------------
// Tela de pesquisa com filtros
// ---------------------------------------------------------------------------
class SearchQuestionsPage extends StatefulWidget {
  final List<Question> questions;
  final void Function(String id) onDelete;

  const SearchQuestionsPage({
    super.key,
    required this.questions,
    required this.onDelete,
  });

  @override
  State<SearchQuestionsPage> createState() => _SearchQuestionsPageState();
}

class _SearchQuestionsPageState extends State<SearchQuestionsPage> {
  String _texto = '';
  String? _turma;
  Nivel? _nivel;
  Tipo? _tipo;
  String? _materia;

  List<Question> get _filtradas {
    return widget.questions.where((q) {
      final t = _texto.toLowerCase();
      final okTexto =
          t.isEmpty ||
          q.enunciado.toLowerCase().contains(t) ||
          q.assunto.toLowerCase().contains(t);
      final okTurma = _turma == null || q.turmas.contains(_turma);
      final okNivel = _nivel == null || q.nivel == _nivel;
      final okTipo = _tipo == null || q.tipo == _tipo;
      final okMateria = _materia == null || q.materia == _materia;
      return okTexto && okTurma && okNivel && okTipo && okMateria;
    }).toList();
  }

  Future<void> _confirmDelete(Question q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir questão?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.onDelete(q.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
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
                    icon: Icons.groups_outlined,
                    allLabel: 'Todas as turmas',
                    value: _turma,
                    options: {for (final t in kTurmas) t: t},
                    onChanged: (v) => setState(() => _turma = v),
                  ),
                  _Filter<String>(
                    icon: Icons.menu_book_outlined,
                    allLabel: 'Todas as matérias',
                    value: _materia,
                    options: {for (final m in kMaterias) m: m},
                    onChanged: (v) => setState(() => _materia = v),
                  ),
                  _Filter<Nivel>(
                    icon: Icons.signal_cellular_alt,
                    allLabel: 'Todos os níveis',
                    value: _nivel,
                    options: {for (final n in Nivel.values) n: n.label},
                    onChanged: (v) => setState(() => _nivel = v),
                  ),
                  _Filter<Tipo>(
                    icon: Icons.checklist,
                    allLabel: 'Todos os tipos',
                    value: _tipo,
                    options: {for (final t in Tipo.values) t: t.label},
                    onChanged: (v) => setState(() => _tipo = v),
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
                child: lista.isEmpty
                    ? const Align(
                        alignment: Alignment.topCenter,
                        child: EmptyState(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: lista.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => QuestionCard(
                          question: lista[i],
                          onDelete: () => _confirmDelete(lista[i]),
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
