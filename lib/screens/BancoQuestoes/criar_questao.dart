import 'dart:async';

import 'package:flutter/material.dart';

import '/models/turma.dart';
import '/service/materia_service.dart';
import '/service/turma_service.dart';
import 'elem_comuns.dart';

const _novo = '__novo__';

class CreateQuestionSheet extends StatefulWidget {
  /// Se vier preenchida, a tela funciona como edição dessa questão.
  final Question? questao;

  const CreateQuestionSheet({super.key, this.questao});

  @override
  State<CreateQuestionSheet> createState() => _CreateQuestionSheetState();
}

class _CreateQuestionSheetState extends State<CreateQuestionSheet> {
  final _turmaService = TurmaService();
  final _materiaService = MateriaService();

  late final Stream<List<Turma>> _turmasStream = _turmaService.getTurmas();
  late final Stream<List<String>> _materiasStream = _materiaService.getMaterias(
    padrao: kMaterias,
  );

  int _step = 0;
  String? _erro;

  String? _materiaId;
  String? _assunto;
  Nivel? _nivel;

  final _enunciado = TextEditingController();
  late final List<TextEditingController> _alts;
  int? _correta;

  bool get _editando => widget.questao != null;

  @override
  void initState() {
    super.initState();

    final q = widget.questao;
    final alts = q?.alternativas ?? const <String>[];
    final qtd = alts.length >= 2 ? alts.length : 4;
    _alts = List.generate(
      qtd,
      (i) => TextEditingController(text: i < alts.length ? alts[i] : ''),
    );

    if (q != null) {
      _nivel = q.nivel;
      _enunciado.text = q.enunciado;
      _correta = q.corretas.isEmpty ? null : q.corretas.first;
      _prepararEdicao(q);
    }

    _sub = _materiaService.observar().listen(
      (lista) {
        if (mounted) setState(() => _materias = lista);
      },
      onError: (e) {
        if (mounted) setState(() => _erro = 'Erro ao carregar matérias: $e');
      },
    );
  }

  /// Seleciona a matéria e o assunto da questão. Se ainda não existirem no
  /// cadastro do professor (questões antigas), cria.
  Future<void> _prepararEdicao(Question q) async {
    if (q.materia.trim().isEmpty) return;
    try {
      final m = await _materiaService.criarMateria(q.materia);
      if (q.assunto.isNotEmpty && !m.assuntos.contains(q.assunto)) {
        await _materiaService.adicionarAssunto(m.id, q.assunto);
      }
      if (!mounted) return;
      setState(() {
        _materiaId = m.id;
        _assunto = q.assunto.isEmpty ? null : q.assunto;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Erro ao carregar a questão: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _enunciado.dispose();
    for (final c in _alts) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _abrirModalNovaMateria() async {
    final controller = TextEditingController();
    String? erroModal;
    bool salvando = false;

    final criada = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova matéria'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome da matéria',
                      hintText: 'Ex.: Inglês, Física, Química',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (erroModal != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      erroModal!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: salvando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGreen),
                  onPressed: salvando
                      ? null
                      : () async {
                          setDialogState(() {
                            salvando = true;
                            erroModal = null;
                          });
                          try {
                            final nomeSalvo = await _materiaService
                                .adicionarMateria(controller.text);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, nomeSalvo);
                            }
                          } catch (e) {
                            setDialogState(() {
                              salvando = false;
                              erroModal = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  child: Text(salvando ? 'Salvando...' : 'Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (criada != null && criada.isNotEmpty && mounted) {
      setState(() {
        _materia = criada;
        _erro = null;
      });
    }
  }

  void _proximo() {
    if (_materia == null) return _setErro('Escolha ou crie uma matéria.');
    if (_nivel == null) return _setErro('Escolha o nível da questão.');
    if (_tipo == null) return _setErro('Escolha o tipo de questão.');
    setState(() {
      _erro = null;
      _corretas = {};
      _step = 1;
    });
  }

  bool get _podeAvancar =>
      _materiaAtual != null && _assunto != null && _nivel != null;

  void _setErro(String msg) => setState(() => _erro = msg);

  Future<void> _criarMateria() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => const _NomeDialog(
        titulo: 'Nova matéria',
        rotulo: 'Nome da matéria',
        exemplo: 'Ex.: Matemática',
      ),
    );
    if (nome == null || !mounted) return;

    try {
      final m = await _materiaService.criarMateria(nome);
      if (!mounted) return;
      setState(() {
        _materiaId = m.id;
        _assunto = null;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      _setErro('Não foi possível criar a matéria: $e');
    }
  }

  Future<void> _criarAssunto() async {
    final materia = _materiaAtual;
    if (materia == null) return;

    final nome = await showDialog<String>(
      context: context,
      builder: (_) => const _NomeDialog(
        titulo: 'Novo assunto',
        rotulo: 'Nome do assunto',
        exemplo: 'Ex.: Funções, Revolução Francesa',
      ),
    );
    if (nome == null || !mounted) return;

    // Se já existir (ignorando maiúsculas), só seleciona
    final existente = materia.assuntos.where(
      (a) => a.toLowerCase() == nome.toLowerCase(),
    );
    if (existente.isNotEmpty) {
      setState(() => _assunto = existente.first);
      return;
    }

    try {
      await _materiaService.adicionarAssunto(materia.id, nome);
      if (!mounted) return;
      setState(() {
        _assunto = nome;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      _setErro('Não foi possível criar o assunto: $e');
    }
  }

  void _proximo() {
    if (!_podeAvancar) return;
    setState(() {
      _erro = null;
      _step = 1;
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
      if (_correta == i) {
        _correta = null;
      } else if (_correta != null && _correta! > i) {
        _correta = _correta! - 1;
      }
    });
  }

  void _finalizar() {
    if (_enunciado.text.trim().isEmpty) {
      return _setErro('Escreva o enunciado da questão.');
    }
    if (_alts.any((c) => c.text.trim().isEmpty)) {
      return _setErro('Preencha todas as alternativas (ou remova as vazias).');
    }
    if (_correta == null) {
      return _setErro('Marque qual alternativa é a correta.');
    }

    final q = Question(
      // na edição mantém o id e o código da questão original
      id:
          widget.questao?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      codigo: widget.questao?.codigo ?? '',
      materia: _materiaAtual!.nome,
      assunto: _assunto!,
      nivel: _nivel!,
      enunciado: _enunciado.text.trim(),
      alternativas: _alts.map((c) => c.text.trim()).toList(),
      corretas: {_correta!},
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
                Expanded(
                  child: Text(
                    _editando ? 'Editar questão' : 'Nova questão',
                    style: const TextStyle(
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
                    // No passo 1, só habilita com matéria, assunto e nível
                    onPressed: _step == 0
                        ? (_podeAvancar ? _proximo : null)
                        : _finalizar,
                    child: Text(
                      _step == 0
                          ? 'Próximo'
                          : (_editando ? 'Salvar' : 'Finalizar'),
                    ),
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

  // Seletor controlado (sem estado interno), para o item "Criar ..." nunca
  // ficar marcado como escolhido.
  Widget _seletor({
    required String rotulo,
    required String? valor,
    required List<DropdownMenuItem<String>> itens,
    required ValueChanged<String?>? onChanged,
  }) {
    return InputDecorator(
      isEmpty: valor == null,
      decoration: InputDecoration(
        labelText: rotulo,
        enabled: onChanged != null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isDense: true,
          isExpanded: true,
          items: itens,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _etapa1() {
    final materia = _materiaAtual;
    final assuntos = materia?.assuntos ?? const <String>[];
    final assuntoValor = assuntos.contains(_assunto) ? _assunto : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<String>>(
          stream: _materiasStream,
          initialData: kMaterias,
          builder: (context, snap) {
            final materiasDisponiveis = snap.data ?? kMaterias;
            final materiaValida =
                _materia != null && materiasDisponiveis.contains(_materia)
                ? _materia
                : null;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: materiaValida,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Matéria',
                      border: OutlineInputBorder(),
                    ),
                    items: materiasDisponiveis
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _materia = v),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _abrirModalNovaMateria,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nova'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _seletor(
          rotulo: 'Assunto',
          valor: assuntoValor,
          itens: <DropdownMenuItem<String>>[
            ...assuntos.map(
              (a) => DropdownMenuItem(
                value: a,
                child: Text(a, overflow: TextOverflow.ellipsis),
              ),
            ),
            const DropdownMenuItem(
              value: _novo,
              child: _OpcaoCriar('Criar assunto'),
            ),
          ],
          // Só libera depois de escolher a matéria
          onChanged: materia == null
              ? null
              : (v) {
                  if (v == _novo) {
                    _criarAssunto();
                    return;
                  }
                  setState(() => _assunto = v);
                },
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
        _label('Turmas (opcional — pode marcar mais de uma)'),
        StreamBuilder<List<Turma>>(
          stream: _turmasStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: LinearProgressIndicator(),
              );
            }
            final turmasDisponiveis = (snap.data ?? [])
                .map((t) => t.nome.trim())
                .where((nome) => nome.isNotEmpty)
                .toSet()
                .toList();

            if (turmasDisponiveis.isEmpty) {
              return Text(
                'Nenhuma turma cadastrada ainda. Você pode criar a questão sem turma.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 6,
              children: turmasDisponiveis
                  .map(
                    (t) => FilterChip(
                      label: Text(t),
                      selected: _turmas.contains(t),
                      onSelected: (sel) => setState(
                        () => sel ? _turmas.add(t) : _turmas.remove(t),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
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
        Text(
          '${_materiaAtual?.nome ?? ''} · ${_assunto ?? ''} · ${_nivel?.label ?? ''}',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _enunciado,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Enunciado',
            border: OutlineInputBorder(),
          ),
        ),
        _label('Alternativas — marque a correta'),
        for (var i = 0; i < _alts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Marcar como correta',
                  onPressed: () => setState(() => _correta = i),
                  icon: Icon(
                    _correta == i
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _correta == i ? kGreen : Colors.grey,
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
      ],
    );
  }
}

class _OpcaoCriar extends StatelessWidget {
  final String texto;
  const _OpcaoCriar(this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.add, size: 18, color: kGreen),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(color: kGreen, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _NomeDialog extends StatefulWidget {
  final String titulo;
  final String rotulo;
  final String exemplo;

  const _NomeDialog({
    required this.titulo,
    required this.rotulo,
    required this.exemplo,
  });

  @override
  State<_NomeDialog> createState() => _NomeDialogState();
}

class _NomeDialogState extends State<_NomeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    Navigator.pop(context, texto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.rotulo,
          hintText: widget.exemplo,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _salvar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kGreen),
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
