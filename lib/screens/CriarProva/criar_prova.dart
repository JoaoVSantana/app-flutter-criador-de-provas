import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/provas.dart';
import '../../service/prova_service.dart';
import '../../service/questao_service.dart';
import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../BancoQuestoes/elem_comuns.dart';
import 'detalhe_prova.dart';
import 'previa_papel.dart';

class CriarProvaPage extends StatefulWidget {
  /// Quando informada, a tela abre preenchida para editar essa prova.
  final ProvaSalva? prova;

  const CriarProvaPage({super.key, this.prova});

  @override
  State<CriarProvaPage> createState() => _CriarProvaPageState();
}

class _CriarProvaPageState extends State<CriarProvaPage> {
  final _service = ProvaService();
  final _titulo = TextEditingController();
  final List<Question> _selecionadas = [];
  static const _maxVersoes = 70;
  final _versoesController = TextEditingController(text: '2');
  ModoEmbaralhar _modo = ModoEmbaralhar.ambos;
  String? _erro;
  bool _salvando = false;

  bool get _editando => widget.prova != null;

  @override
  void initState() {
    super.initState();
    final prova = widget.prova;
    if (prova == null) return;

    _titulo.text = prova.titulo;
    _escreverVersoes(prova.versoes.length);
    _modo = descobrirModo(prova.versoes);
    // Usa a cópia das questões salva na própria prova
    _selecionadas.addAll(
      prova.questoes.map(
        (q) => Question(
          id: q.questaoId,
          codigo: q.codigo,
          materia: q.materia,
          assunto: q.assunto,
          nivel: Nivel.baixo, // o nível não é guardado na prova
          enunciado: q.enunciado,
          alternativas: q.alternativas,
          corretas: {q.correta},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titulo.dispose();
    _versoesController.dispose();
    super.dispose();
  }

  void _setErro(String msg) => setState(() => _erro = msg);

  /// Número digitado no campo de versões (0 quando está vazio).
  int get _versoes => int.tryParse(_versoesController.text) ?? 0;

  void _escreverVersoes(int valor) {
    final texto = '$valor';
    _versoesController.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  void _mudarVersoes(int valor) =>
      setState(() => _escreverVersoes(valor.clamp(1, _maxVersoes)));

  void _versoesDigitadas(String _) {
    // Não deixa passar do limite
    if (_versoes > _maxVersoes) _escreverVersoes(_maxVersoes);
    setState(() => _erro = null);
  }

  String get _explicacaoModo => switch (_modo) {
    ModoEmbaralhar.questoes =>
      'Muda só a ordem das questões. As alternativas ficam iguais.',
    ModoEmbaralhar.alternativas =>
      'Muda só a ordem das alternativas. As questões ficam na mesma ordem.',
    ModoEmbaralhar.ambos =>
      'Muda a ordem das questões e também das alternativas.',
  };

  Widget _opcaoModo(ModoEmbaralhar modo, String texto) => ChoiceChip(
    label: Text(texto),
    selected: _modo == modo,
    selectedColor: kCard,
    onSelected: (_) => setState(() => _modo = modo),
  );

  List<ProvaQuestao> _paraProvaQuestoes() => _selecionadas
      .map(
        (q) => ProvaQuestao(
          questaoId: q.id,
          codigo: q.codigo,
          materia: q.materia,
          assunto: q.assunto,
          enunciado: q.enunciado,
          alternativas: q.alternativas,
          correta: q.corretas.isEmpty ? 0 : q.corretas.first,
        ),
      )
      .toList();

  Future<void> _adicionar() async {
    final novas = await showModalBottomSheet<List<Question>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SeletorQuestoes(
        jaSelecionadas: _selecionadas.map((q) => q.id).toSet(),
      ),
    );
    if (novas == null || novas.isEmpty) return;
    setState(() {
      _selecionadas.addAll(novas);
      _erro = null;
    });
  }

  void _reordenar(int de, int para) {
    setState(() {
      if (para > de) para -= 1;
      final q = _selecionadas.removeAt(de);
      _selecionadas.insert(para, q);
    });
  }

  void _previa() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Prévia da prova',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kGreen,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: PreviaPapel(
                  titulo: _titulo.text,
                  subtitulo: 'Versão 1',
                  itens: montarOriginal(_paraProvaQuestoes()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      _setErro('Dê um título para a prova.');
      return;
    }
    if (_selecionadas.isEmpty) {
      _setErro('Adicione pelo menos uma questão.');
      return;
    }
    final quantidade = _versoes;
    if (quantidade < 1) {
      _setErro('Informe quantas versões você quer (de 1 a $_maxVersoes).');
      return;
    }
    final semGabarito = _selecionadas
        .where((q) => q.corretas.isEmpty || q.alternativas.length < 2)
        .toList();
    if (semGabarito.isNotEmpty) {
      final codigos = semGabarito
          .map((q) => q.codigo.isEmpty ? 'sem código' : q.codigo)
          .join(', ');
      _setErro(
        'Estas questões não têm alternativa correta marcada: $codigos. '
        'Edite-as no banco de questões.',
      );
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    if (_editando) {
      await _salvarEdicao(titulo, quantidade);
      return;
    }

    try {
      final r = await _service.criar(
        titulo: titulo,
        questoes: _paraProvaQuestoes(),
        quantidadeVersoes: quantidade,
        modo: _modo,
      );
      if (!mounted) return;

      if (r.versoes < quantidade) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Só foi possível gerar ${r.versoes} versão(ões) diferente(s) '
              'com essas questões e esse tipo de embaralhamento.',
            ),
          ),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DetalheProvaPage(provaId: r.id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Erro ao salvar a prova: $e';
      });
    }
  }

  /// Diz se a mudança exige gerar as versões de novo.
  bool _mudouVersoes(int quantidade) {
    final prova = widget.prova!;
    final antes = prova.questoes.map((q) => q.questaoId).join('|');
    final depois = _selecionadas.map((q) => q.id).join('|');
    return antes != depois ||
        quantidade != prova.versoes.length ||
        (quantidade > 1 && _modo != descobrirModo(prova.versoes));
  }

  Future<bool> _confirmarNovasVersoes(int alunos) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atualizar a prova dos alunos?'),
        content: Text(
          '$alunos aluno(s) já têm esta prova. As versões serão geradas de '
          'novo e a versão e o gabarito deles podem mudar. PDFs já baixados '
          'ou impressos ficam desatualizados: baixe e imprima novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
    return confirmou == true;
  }

  Future<void> _salvarEdicao(String titulo, int quantidade) async {
    final id = widget.prova!.id;
    try {
      var geradas = quantidade;
      if (_mudouVersoes(quantidade)) {
        final alunos = await _service.contarAlunos(id);
        if (!mounted) return;
        if (alunos > 0 && !await _confirmarNovasVersoes(alunos)) {
          if (mounted) setState(() => _salvando = false);
          return;
        }
        geradas = await _service.atualizar(
          provaId: id,
          titulo: titulo,
          questoes: _paraProvaQuestoes(),
          quantidadeVersoes: quantidade,
          modo: _modo,
        );
      } else {
        await _service.renomear(id, titulo);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            geradas < quantidade
                ? 'Prova atualizada. Só foi possível gerar $geradas '
                      'versão(ões) diferente(s).'
                : 'Prova atualizada!',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Erro ao salvar a prova: $e';
      });
    }
  }

  Widget _secao(String texto) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: MenuTitle(
                  title: _editando ? 'Editar prova' : 'Nova prova',
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titulo,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Título da prova',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              _secao('Questões (${_selecionadas.length})'),
              if (_selecionadas.isEmpty)
                Text(
                  'Nenhuma questão ainda. Adicione do banco de questões.',
                  style: TextStyle(color: Colors.grey.shade700),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: _reordenar,
                  children: [
                    for (var i = 0; i < _selecionadas.length; i++)
                      Container(
                        key: ValueKey(_selecionadas[i].id),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        decoration: BoxDecoration(
                          color: kListCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${i + 1}. ${_selecionadas[i].enunciado}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover',
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  setState(() => _selecionadas.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _adicionar,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar questões do banco'),
              ),
              _secao('Versões da prova'),
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Diminuir',
                    onPressed: _versoes > 1
                        ? () => _mudarVersoes(_versoes - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _versoesController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      // Ao tocar, seleciona o número para digitar por cima
                      onTap: () => _versoesController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _versoesController.text.length,
                      ),
                      onChanged: _versoesDigitadas,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Aumentar',
                    onPressed: _versoes < _maxVersoes
                        ? () => _mudarVersoes(_versoes + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Digite ou use os botões (máximo $_maxVersoes).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              _secao('O que embaralhar'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _opcaoModo(ModoEmbaralhar.questoes, 'Só questões'),
                  _opcaoModo(ModoEmbaralhar.alternativas, 'Só alternativas'),
                  _opcaoModo(ModoEmbaralhar.ambos, 'Os dois'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_explicacaoModo A versão 1 mantém a ordem original.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selecionadas.isEmpty ? null : _previa,
                      child: const Text('Prévia'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kGreen),
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _editando ? 'Salvar alterações' : 'Salvar prova',
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Folha para escolher questões do banco.
class _SeletorQuestoes extends StatefulWidget {
  final Set<String> jaSelecionadas;
  const _SeletorQuestoes({required this.jaSelecionadas});

  @override
  State<_SeletorQuestoes> createState() => _SeletorQuestoesState();
}

class _SeletorQuestoesState extends State<_SeletorQuestoes> {
  late final Stream<List<Question>> _stream = QuestaoService().observarMinhas();
  final List<Question> _marcadas = [];
  String _busca = '';

  bool _estaMarcada(Question q) => _marcadas.any((m) => m.id == q.id);

  void _alternar(Question q) {
    setState(() {
      if (_estaMarcada(q)) {
        _marcadas.removeWhere((m) => m.id == q.id);
      } else {
        _marcadas.add(q);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Banco de questões',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kGreen,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _busca = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar questão',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Question>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text('Erro ao carregar: ${snap.error}'),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final lista = snap.data!
                      .where((q) => !widget.jaSelecionadas.contains(q.id))
                      .where(
                        (q) =>
                            _busca.isEmpty ||
                            q.enunciado.toLowerCase().contains(_busca) ||
                            q.materia.toLowerCase().contains(_busca) ||
                            q.assunto.toLowerCase().contains(_busca) ||
                            q.codigo.toLowerCase().contains(_busca),
                      )
                      .toList();

                  if (lista.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma questão encontrada.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final q = lista[i];
                      return CheckboxListTile(
                        value: _estaMarcada(q),
                        onChanged: (_) => _alternar(q),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: kGreen,
                        title: Text(
                          q.enunciado,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            if (q.codigo.isNotEmpty) q.codigo,
                            q.materia,
                            if (q.assunto.isNotEmpty) q.assunto,
                            q.nivel.label,
                          ].join(' · '),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGreen),
                  onPressed: _marcadas.isEmpty
                      ? null
                      : () => Navigator.pop(context, _marcadas),
                  child: Text('Adicionar (${_marcadas.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
