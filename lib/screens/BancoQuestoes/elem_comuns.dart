import 'package:flutter/material.dart';

const kGreen = Color(0xFF2F5D4E);
const kCard = Color(0xFFD7E2D4);
const kListCard = Color(0xFFF1F3EE);
const kOrange = Color(0xFFC98B2E);
const kBg = Color(0xFFFEF7FF);

enum Nivel { baixo, medio, alto }

enum Tipo { multipla, vf }

extension NivelX on Nivel {
  String get label => switch (this) {
    Nivel.baixo => 'Baixo',
    Nivel.medio => 'Médio',
    Nivel.alto => 'Alto',
  };
  Color get color => switch (this) {
    Nivel.baixo => const Color(0xFF4CAF50),
    Nivel.medio => kOrange,
    Nivel.alto => const Color(0xFFC0504D),
  };
}

extension TipoX on Tipo {
  String get label => switch (this) {
    Tipo.multipla => 'Múltipla escolha',
    Tipo.vf => 'Verdadeiro ou falso',
  };
}

class Question {
  final String id;
  final String materia;
  final String assunto;
  final Nivel nivel;
  final Tipo tipo;
  final List<String> turmas;
  final String enunciado;
  final List<String> alternativas;
  final Set<int> corretas;

  const Question({
    required this.id,
    required this.materia,
    required this.assunto,
    required this.nivel,
    required this.tipo,
    required this.turmas,
    required this.enunciado,
    this.alternativas = const [],
    this.corretas = const {},
  });
}

const kMaterias = [
  'Matemática',
  'Biologia',
  'História',
  'Português',
  'Geografia',
];
const kTurmas = ['1º Ano A', '2º Ano B'];

class MenuTitle extends StatelessWidget {
  final String title;
  final double fontSize;

  const MenuTitle({super.key, required this.title, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: kGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kListCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            'Nenhuma questão encontrada',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

//card de questoes
class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToExam; // futuro: botão "Adicionar à prova"

  const QuestionCard({
    super.key,
    required this.question,
    this.onDelete,
    this.onAddToExam,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Container(
      decoration: BoxDecoration(
        color: kListCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.enunciado,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _LevelBadge(nivel: q.nivel),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.assunto.isEmpty ? q.materia : '${q.materia} · ${q.assunto}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MiniInfo(icon: Icons.checklist, text: q.tipo.label),
                    _MiniInfo(
                      icon: Icons.groups_outlined,
                      text: q.turmas.join(', '),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(q.enunciado, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < q.alternativas.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      q.corretas.contains(i)
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                      color: q.corretas.contains(i) ? kGreen : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.tipo == Tipo.multipla
                            ? '${String.fromCharCode(65 + i)}) ${q.alternativas[i]}'
                            : q.alternativas[i],
                        style: TextStyle(
                          fontWeight: q.corretas.contains(i)
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (onDelete != null || onAddToExam != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Excluir',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  if (onAddToExam != null)
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kGreen),
                      onPressed: onAddToExam,
                      child: const Text('Adicionar à prova'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final Nivel nivel;
  const _LevelBadge({required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: nivel.color.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        nivel.label,
        style: TextStyle(
          color: nivel.color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
