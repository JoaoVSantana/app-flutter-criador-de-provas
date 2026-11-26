import 'package:flutter/material.dart';

import '../../service/questao_service.dart';
import 'criar_questao.dart';
import 'elem_comuns.dart';

void _aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

Future<void> editarQuestao(BuildContext context, Question q) async {
  final editada = await showModalBottomSheet<Question>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: kBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CreateQuestionSheet(questao: q),
  );
  if (editada == null || !context.mounted) return;

  try {
    await QuestaoService().atualizar(editada);
    if (!context.mounted) return;
    _aviso(
      context,
      q.codigo.isEmpty
          ? 'Questão atualizada!'
          : 'Questão ${q.codigo} atualizada!',
    );
  } catch (e) {
    if (!context.mounted) return;
    _aviso(context, 'Erro ao salvar as alterações: $e');
  }
}

Future<void> excluirQuestao(BuildContext context, Question q) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        q.codigo.isEmpty
            ? 'Excluir questão?'
            : 'Excluir a questão ${q.codigo}?',
      ),
      content: const Text('Essa ação não pode ser desfeita.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Excluir', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await QuestaoService().excluir(q.id);
    if (!context.mounted) return;
    _aviso(context, 'Questão excluída.');
  } catch (e) {
    if (!context.mounted) return;
    _aviso(context, 'Erro ao excluir: $e');
  }
}
