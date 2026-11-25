import 'package:flutter/material.dart';

import 'elem_comuns.dart';

class CreateQuestionSheet extends StatefulWidget {
  const CreateQuestionSheet({super.key});

  @override
  State<CreateQuestionSheet> createState() => _CreateQuestionSheetState();
}

class _CreateQuestionSheetState extends State<CreateQuestionSheet> {
  int _step = 0;
  String? _erro;

  String? _materia;
  final _assunto = TextEditingController();
  Nivel? _nivel;
  final Set<String> _turmas = {};
  Tipo? _tipo;

  final _enunciado = TextEditingController();
  final List<TextEditingController> _alts = List.generate(
    4,
    (_) => TextEditingController(),
  );
  Set<int> _corretas = {};
  bool _variasCorretas = false;

  @override
  void dispose() {
    _assunto.dispose();
    _enunciado.dispose();
    for (final c in _alts) {
      c.dispose();
    }
    super.dispose();
  }

  void _proximo() {
    if (_materia == null) return _setErro('Escolha a matéria.');
    if (_nivel == null) return _setErro('Escolha o nível da questão.');
    if (_turmas.isEmpty) return _setErro('Marque pelo menos uma turma.');
    if (_tipo == null) return _setErro('Escolha o tipo de questão.');
    setState(() {
      _erro = null;
      _corretas = {};
      _step = 1;
    });
  }

  void _setErro(String msg) => setState(() => _erro = msg);

  void _toggleCorreta(int i) {
    setState(() {
      if (_variasCorretas) {
        _corretas.contains(i) ? _corretas.remove(i) : _corretas.add(i);
      } else {
        _corretas = {i};
      }
    });
  }

  void _addAlt() {
    if (_alts.length >= 5) return;
    setState(() => _alts.add(TextEditingController()));
  }

  void _removeAlt(int i) {
    if (_alts.length <= 2) return;
    setState(() {
      final c = _alts.removeAt(i);
      WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
      _corretas = _corretas
          .where((c) => c != i)
          .map((c) => c > i ? c - 1 : c)
          .toSet();
    });
  }

  void _finalizar() {
    if (_enunciado.text.trim().isEmpty) {
      return _setErro('Escreva o enunciado da questão.');
    }
    if (_tipo == Tipo.multipla) {
      if (_alts.any((c) => c.text.trim().isEmpty)) {
        return _setErro(
          'Preencha todas as alternativas (ou remova as vazias).',
        );
      }
      if (_corretas.isEmpty) {
        return _setErro('Marque qual alternativa é a correta.');
      }
    }
    if (_tipo == Tipo.vf && _corretas.isEmpty) {
      return _setErro('Escolha se a afirmação é verdadeira ou falsa.');
    }

    final q = Question(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      materia: _materia!,
      assunto: _assunto.text.trim(),
      nivel: _nivel!,
      tipo: _tipo!,
      turmas: _turmas.toList(),
      enunciado: _enunciado.text.trim(),
      alternativas: switch (_tipo!) {
        Tipo.multipla => _alts.map((c) => c.text.trim()).toList(),
        Tipo.vf => ['Verdadeiro', 'Falso'],
      },
      corretas: _corretas,
    );
    Navigator.pop(context, q);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nova questão',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ),
                Text(
                  'Etapa ${_step + 1} de 2',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (_step + 1) / 2,
              color: kGreen,
              backgroundColor: kCard,
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 20),
            if (_step == 0) _etapa1() else _etapa2(),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _step == 0
                        ? () => Navigator.pop(context)
                        : () => setState(() {
                            _erro = null;
                            _step = 0;
                          }),
                    child: Text(_step == 0 ? 'Cancelar' : 'Voltar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: kGreen),
                    onPressed: _step == 0 ? _proximo : _finalizar,
                    child: Text(_step == 0 ? 'Próximo' : 'Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _etapa1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _materia,
          decoration: const InputDecoration(
            labelText: 'Matéria',
            border: OutlineInputBorder(),
          ),
          items: kMaterias
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _materia = v),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _assunto,
          decoration: const InputDecoration(
            labelText: 'Assunto (opcional)',
            hintText: 'Ex.: Funções, Revolução Francesa',
            border: OutlineInputBorder(),
          ),
        ),
        _label('Nível da questão'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<Nivel>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: Nivel.values
                .map((n) => ButtonSegment(value: n, label: Text(n.label)))
                .toList(),
            selected: _nivel == null ? {} : {_nivel!},
            onSelectionChanged: (s) =>
                setState(() => _nivel = s.isEmpty ? null : s.first),
          ),
        ),
        _label('Turmas (pode marcar mais de uma)'),
        Wrap(
          spacing: 8,
          children: kTurmas
              .map(
                (t) => FilterChip(
                  label: Text(t),
                  selected: _turmas.contains(t),
                  onSelected: (sel) =>
                      setState(() => sel ? _turmas.add(t) : _turmas.remove(t)),
                ),
              )
              .toList(),
        ),
        _label('Tipo de questão'),
        Wrap(
          spacing: 8,
          children: Tipo.values
              .map(
                (t) => ChoiceChip(
                  label: Text(t.label),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _etapa2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _enunciado,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Enunciado',
            border: OutlineInputBorder(),
          ),
        ),
        if (_tipo == Tipo.multipla) ..._alternativas(),
        if (_tipo == Tipo.vf) ..._verdadeiroFalso(),
      ],
    );
  }

  List<Widget> _alternativas() {
    return [
      _label('Alternativas — marque a correta'),
      for (var i = 0; i < _alts.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Marcar como correta',
                onPressed: () => _toggleCorreta(i),
                icon: Icon(
                  _corretas.contains(i)
                      ? (_variasCorretas
                            ? Icons.check_box
                            : Icons.radio_button_checked)
                      : (_variasCorretas
                            ? Icons.check_box_outline_blank
                            : Icons.radio_button_unchecked),
                  color: _corretas.contains(i) ? kGreen : Colors.grey,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _alts[i],
                  decoration: InputDecoration(
                    labelText: 'Alternativa ${String.fromCharCode(65 + i)}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              if (_alts.length > 2)
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => _removeAlt(i),
                  icon: const Icon(Icons.close, size: 20),
                ),
            ],
          ),
        ),
      if (_alts.length < 5)
        TextButton.icon(
          onPressed: _addAlt,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar alternativa'),
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Mais de uma alternativa correta'),
        value: _variasCorretas,
        onChanged: (v) => setState(() {
          _variasCorretas = v;
          if (!v && _corretas.length > 1) _corretas = {_corretas.first};
        }),
      ),
    ];
  }

  List<Widget> _verdadeiroFalso() {
    return [
      _label('A afirmação é:'),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: 0, label: Text('Verdadeiro')),
            ButtonSegment(value: 1, label: Text('Falso')),
          ],
          selected: _corretas,
          onSelectionChanged: (s) => setState(() => _corretas = s),
        ),
      ),
    ];
  }
}
