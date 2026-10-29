
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';

class Corrigir extends StatefulWidget {
  const Corrigir({super.key});

  @override
  State<Corrigir> createState() => _CorrigirState();
}

class _CorrigirState extends State<Corrigir> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color fundo = Color.fromARGB(255, 228, 235, 230);
  static const Color cinza = Color.fromARGB(255, 212, 214, 213);
  static const Color verde = Color(0xFF4C6B5E);
  static const Color texto = Color.fromARGB(255, 26, 29, 28);

  final List<String> etapas = [
    'Identificar prova',
    'Conferir gabarito',
    'Ler prova',
  ];

  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();

  int etapa = 0;
  String? _provaId;
  Map<String, dynamic>? _prova;
  List<Map<String, dynamic>> _questoes = [];
  List<String?> _respostas = [];
  bool _carregando = false;
  bool _salvando = false;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _carregarProva(String id) async {
    setState(() {
      _carregando = true;
      _provaId = id;
    });

    try {
      final doc = await _db.collection('provas').doc(id).get();

      if (!doc.exists) {
        throw Exception('Prova não encontrada.');
      }

      final dados = doc.data()!;

      final ids = List<String>.from(dados['questoesIds'] ?? []);
      if (ids.isEmpty) {
        throw Exception('Esta prova não possui questões vinculadas.');
      }

      final gabarito = Map<String, dynamic>.from(dados['gabarito'] ?? {});
      final questoes = <Map<String, dynamic>>[];

      for (final questaoId in ids) {
        final qDoc = await _db.collection('questoes').doc(questaoId).get();

        if (!qDoc.exists) continue;

        final q = qDoc.data()!;
        final alternativas = List<String>.from(q['alternativas'] ?? []);
        final corretas = List<int>.from(q['corretas'] ?? []);
        final letraCorreta = corretas.isNotEmpty &&
            corretas.first >= 0 &&
            corretas.first < alternativas.length
            ? String.fromCharCode(65 + corretas.first)
            : '';

        questoes.add({
          'id': qDoc.id,
          'enunciado': q['enunciado'] ?? '',
          'materia': q['materia'] ?? '',
          'assunto': q['assunto'] ?? '',
          'alternativas': alternativas,
          'gabarito': (gabarito[qDoc.id] ?? letraCorreta).toString(),
        });
      }

      if (questoes.isEmpty) {
        throw Exception('Não foi possível carregar as questões desta prova.');
      }

      if (!mounted) return;

      setState(() {
        _prova = dados;
        _questoes = questoes;
        _respostas = List<String?>.filled(questoes.length, null);
        _codigoController.text = (dados['codigoQr'] ?? id).toString();
        etapa = 1;
      });
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _validarCodigo() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty || _provaId == null || _prova == null) {
      _mensagem('Selecione uma prova e informe o código.');
      return;
    }

    final codigoEsperado = (_prova!['codigoQr'] ?? _provaId).toString();

    if (codigo != codigoEsperado && codigo != _provaId) {
      _mensagem('O código informado não corresponde à prova selecionada.');
      return;
    }

    setState(() => etapa = 2);
  }

  void _irParaRespostas() {
    if (_questoes.any((q) => (q['gabarito'] as String).isEmpty)) {
      _mensagem('Existe questão sem alternativa correta definida.');
      return;
    }

    setState(() => etapa = 3);
  }

  Future<void> _salvarCorrecao() async {
    if (_uid.isEmpty) {
      _mensagem('Faça login para salvar a correção.');
      return;
    }

    if (_provaId == null || _prova == null || _questoes.isEmpty) {
      _mensagem('Selecione uma prova válida.');
      return;
    }

    if (_nomeController.text.trim().isEmpty) {
      _mensagem('Informe o nome do aluno.');
      return;
    }

    if (_respostas.length != _questoes.length) {
      _mensagem('Confira as respostas antes de continuar.');
      return;
    }

    setState(() => _salvando = true);

    try {
      var acertos = 0;
      var emBranco = 0;

      for (var i = 0; i < _questoes.length; i++) {
        if (_respostas[i] == null) {
          emBranco++;
        } else if (_respostas[i] == _questoes[i]['gabarito']) {
          acertos++;
        }
      }

      final total = _questoes.length;
      final erros = total - acertos - emBranco;
      final nota = total == 0 ? 0.0 : (acertos / total) * 10;
      final respostasSalvas = List.generate(total, (i) {
        return {
          'questaoId': _questoes[i]['id'],
          'numero': i + 1,
          'marcada': _respostas[i],
          'gabarito': _questoes[i]['gabarito'],
          'correta': _respostas[i] != null &&
              _respostas[i] == _questoes[i]['gabarito'],
        };
      });

      final correcao = _db.collection('correcoes').doc();

      await correcao.set({
        'professorId': _uid,
        'provaId': _provaId,
        'tituloProva': _prova!['titulo'] ?? 'Prova',
        'disciplina': _prova!['disciplina'] ?? '',
        'turma': _prova!['turma'] ?? '',
        'alunoNome': _nomeController.text.trim(),
        'matricula': _matriculaController.text.trim(),
        'respostas': respostasSalvas,
        'totalQuestoes': total,
        'acertos': acertos,
        'erros': erros,
        'emBranco': emBranco,
        'nota': nota,
        'aproveitamento': acertos / total,
        'dataCorrecao': FieldValue.serverTimestamp(),
      });

      await _db.collection('provas').doc(_provaId).update({
        'ultimaCorrecaoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        etapa = 4;
      });
    } catch (e) {
      _mensagem('Não foi possível salvar a correção: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _criarProva() async {
    final nomeController = TextEditingController();
    final disciplinaController = TextEditingController();
    final turmaController = TextEditingController();
    final selecionadas = <String>{};

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, atualizarDialogo) => AlertDialog(
          backgroundColor: fundo,
          title: const Text('Cadastrar prova'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Título da prova'),
                  ),
                  TextField(
                    controller: disciplinaController,
                    decoration: const InputDecoration(labelText: 'Disciplina'),
                  ),
                  TextField(
                    controller: turmaController,
                    decoration: const InputDecoration(labelText: 'Turma'),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selecione as questões',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 240,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection('questoes')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Erro ao carregar questões.'));
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('Você ainda não cadastrou questões.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final dados = doc.data();
                            final titulo = (dados['enunciado'] ?? 'Questão').toString();

                            return CheckboxListTile(
                              value: selecionadas.contains(doc.id),
                              activeColor: verde,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${dados['materia'] ?? ''} • ${dados['assunto'] ?? ''}',
                              ),
                              onChanged: (valor) {
                                atualizarDialogo(() {
                                  if (valor == true) {
                                    selecionadas.add(doc.id);
                                  } else {
                                    selecionadas.remove(doc.id);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                foregroundColor: Colors.white,
              ),
              child: const Text('Criar prova'),
            ),
          ],
        ),
      ),
    );

    if (confirmou != true) return;

    if (nomeController.text.trim().isEmpty ||
        disciplinaController.text.trim().isEmpty ||
        turmaController.text.trim().isEmpty ||
        selecionadas.isEmpty) {
      _mensagem('Preencha os campos e selecione ao menos uma questão.');
      return;
    }

    try {
      final gabarito = <String, String>{};

      for (final id in selecionadas) {
        final doc = await _db.collection('questoes').doc(id).get();

        if (!doc.exists) continue;

        final dados = doc.data()!;
        final corretas = List<int>.from(dados['corretas'] ?? []);
        final alternativas = List<String>.from(dados['alternativas'] ?? []);

        if (corretas.isEmpty ||
            corretas.first < 0 ||
            corretas.first >= alternativas.length) {
          throw Exception(
            'Uma das questões selecionadas não tem alternativa correta válida.',
          );
        }

        gabarito[id] = String.fromCharCode(65 + corretas.first);
      }

      final provaRef = _db.collection('provas').doc();

      await provaRef.set({
        'professorId': _uid,
        'titulo': nomeController.text.trim(),
        'disciplina': disciplinaController.text.trim(),
        'turma': turmaController.text.trim(),
        'questoesIds': selecionadas.toList(),
        'gabarito': gabarito,
        'codigoQr': provaRef.id,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _mensagem('Prova cadastrada. Código: ${provaRef.id}');
      await _carregarProva(provaRef.id);
    } catch (e) {
      _mensagem('Não foi possível cadastrar a prova: $e');
    } finally {
      nomeController.dispose();
      disciplinaController.dispose();
      turmaController.dispose();
    }
  }

  void _mensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _reiniciar() {
    setState(() {
      etapa = 0;
      _provaId = null;
      _prova = null;
      _questoes = [];
      _respostas = [];
      _codigoController.clear();
      _nomeController.clear();
      _matriculaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: Scaffold(
                drawer: const DrawerNav(),
                backgroundColor: fundo,
                appBar: AppBar(
                  backgroundColor: fundo,
                  foregroundColor: verde,
                  elevation: 0,
                  title: const Text('Correção de provas'),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildConteudo(),
                    ),
                  ),
                ),
              ),
            ),
            const Navegar(onVoltar: null, onAvancar: null),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (etapa == 0) return _buildInicio();
    if (etapa == 4) return _buildResultado();
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        _buildProgresso(),
        const SizedBox(height: 30),
        if (etapa == 1) _buildIdentificacao(),
        if (etapa == 2) _buildGabarito(),
        if (etapa == 3) _buildRespostas(),
      ],
    );
  }

  Widget _buildInicio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verde.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: verde,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 50,
              color: fundo,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Correção de provas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w800,
              color: verde,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Selecione uma prova cadastrada ou crie uma usando suas questões.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: texto),
          ),
          const SizedBox(height: 28),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('provas')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Erro ao carregar provas do Firebase.');
              }

              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: [
                  if (docs.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: docs.any((d) => d.id == _provaId) ? _provaId : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Prova cadastrada',
                        filled: true,
                        fillColor: fundo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: docs.map((doc) {
                        final dados = doc.data();
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            '${dados['titulo'] ?? 'Prova'} • ${dados['turma'] ?? ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (id) => setState(() => _provaId = id),
                    )
                  else
                    const Text('Nenhuma prova cadastrada ainda.'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _criarProva,
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar prova'),
                      style: _estiloBotao(),
                    ),
                  ),
                  if (docs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _provaId == null
                            ? null
                            : () => _carregarProva(_provaId!),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar correção'),
                        style: _estiloBotao(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgresso() {
    return Row(
      children: List.generate(etapas.length, (i) {
        final concluida = i < etapa;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: concluida ? verde : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  etapas[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: concluida ? verde : Colors.grey.shade700,
                    fontWeight: concluida ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _painel({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Widget conteudo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verde.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: verde,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icone, color: fundo, size: 45),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w800,
              color: verde,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: texto),
          ),
          const SizedBox(height: 24),
          conteudo,
        ],
      ),
    );
  }

  Widget _buildIdentificacao() {
    return _painel(
      icone: Icons.qr_code_scanner,
      titulo: 'Identificar prova',
      descricao: 'Confira o código da prova selecionada.',
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            controller: _codigoController,
            label: 'Código da prova',
            icone: Icons.qr_code,
          ),
          const SizedBox(height: 18),
          _botao('Validar código', Icons.check, _validarCodigo),
          TextButton(
            onPressed: _reiniciar,
            child: const Text('Cancelar correção'),
          ),
        ],
      ),
    );
  }

  Widget _buildGabarito() {
    return _painel(
      icone: Icons.fact_check_outlined,
      titulo: 'Conferir gabarito',
      descricao: 'Confira as alternativas corretas carregadas do Firebase.',
      conteudo: Column(
        children: [
          ...List.generate(_questoes.length, (i) {
            final q = _questoes[i];
            return Card(
              color: fundo,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: verde,
                  foregroundColor: Colors.white,
                  child: Text('${i + 1}'),
                ),
                title: Text(
                  q['enunciado'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Gabarito: ${q['gabarito']}'),
              ),
            );
          }),
          const SizedBox(height: 16),
          _botao('Continuar para respostas', Icons.arrow_forward, _irParaRespostas),
          TextButton(
            onPressed: () => setState(() => etapa = 1),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRespostas() {
    return _painel(
      icone: Icons.description_outlined,
      titulo: 'Respostas do aluno',
      descricao: 'Informe os dados do aluno e marque a alternativa de cada questão. Deixe sem seleção quando estiver em branco.',
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campo(
            controller: _nomeController,
            label: 'Nome do aluno',
            icone: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _campo(
            controller: _matriculaController,
            label: 'Matrícula (opcional)',
            icone: Icons.badge_outlined,
          ),
          const SizedBox(height: 18),
          ...List.generate(_questoes.length, (i) {
            final q = _questoes[i];
            final alternativas = List<String>.from(q['alternativas'] ?? []);

            return Card(
              color: fundo,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questão ${i + 1}',
                      style: const TextStyle(
                        color: verde,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(q['enunciado'].toString()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(alternativas.length, (j) {
                        final letra = String.fromCharCode(65 + j);
                        return ChoiceChip(
                          label: Text(letra),
                          selected: _respostas[i] == letra,
                          selectedColor: verde.withOpacity(0.25),
                          onSelected: (selecionado) {
                            setState(() {
                              _respostas[i] = selecionado ? letra : null;
                            });
                          },
                        );
                      }),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _respostas[i] = null),
                        child: const Text('Marcar em branco'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          _botao(
            _salvando ? 'Salvando...' : 'Corrigir e salvar resultado',
            Icons.save_outlined,
            _salvando ? null : _salvarCorrecao,
          ),
          TextButton(
            onPressed: () => setState(() => etapa = 2),
            child: const Text('Voltar ao gabarito'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    var acertos = 0;
    var emBranco = 0;

    for (var i = 0; i < _questoes.length; i++) {
      if (_respostas[i] == null) {
        emBranco++;
      } else if (_respostas[i] == _questoes[i]['gabarito']) {
        acertos++;
      }
    }

    final total = _questoes.length;
    final erros = total - acertos - emBranco;
    final nota = total == 0 ? 0.0 : acertos / total * 10;
    final aproveitamento = total == 0 ? 0 : acertos / total * 100;

    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: verde,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.check, color: fundo, size: 55),
        ),
        const SizedBox(height: 20),
        const Text(
          'Correção concluída!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w800,
            color: verde,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _nomeController.text.trim(),
          style: const TextStyle(fontSize: 18, color: texto),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cinza,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'NOTA FINAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: verde,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nota.toStringAsFixed(1).replaceAll('.', ','),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: verde,
                ),
              ),
              const Text('de 10,0', style: TextStyle(color: texto)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 600;
            final largura = mobile
                ? (constraints.maxWidth - 12) / 2
                : (constraints.maxWidth - 36) / 4;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: largura,
                  child: _infoCard('Acertos', '$acertos', Icons.check_circle_outline),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard('Erros', '$erros', Icons.cancel_outlined),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard('Em branco', '$emBranco', Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard(
                    'Aproveitamento',
                    '${aproveitamento.toStringAsFixed(0)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cinza,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados da prova',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: verde,
                ),
              ),
              const SizedBox(height: 14),
              Text('Aluno: ${_nomeController.text.trim()}'),
              Text('Matrícula: ${_matriculaController.text.trim().isEmpty ? '—' : _matriculaController.text.trim()}'),
              Text('Turma: ${_prova?['turma'] ?? '—'}'),
              Text('Disciplina: ${_prova?['disciplina'] ?? '—'}'),
              Text('Prova: ${_prova?['titulo'] ?? '—'}'),
              Text('Data: ${DateTime.now().toString().substring(0, 10)}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _reiniciar,
            icon: const Icon(Icons.refresh),
            label: const Text('Nova correção'),
            style: _estiloBotao(),
          ),
        ),
      ],
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icone,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, color: verde),
        filled: true,
        fillColor: fundo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _botao(String titulo, IconData icone, VoidCallback? acao) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: acao,
        icon: Icon(icone),
        label: Text(titulo, textAlign: TextAlign.center),
        style: _estiloBotao(),
      ),
    );
  }

  ButtonStyle _estiloBotao() {
    return ElevatedButton.styleFrom(
      backgroundColor: verde,
      foregroundColor: Colors.white,
      disabledBackgroundColor: verde.withOpacity(0.4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _infoCard(String titulo, String valor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icone, color: verde, size: 28),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: verde,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: texto, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
