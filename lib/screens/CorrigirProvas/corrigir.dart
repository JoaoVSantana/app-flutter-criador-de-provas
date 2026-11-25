import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  int etapa = 0;

  String? _provaSelecionadaId;
  Map<String, dynamic>? _prova;
  var _questoes = [];

  String? _alunoSelecionadoId;
  String _alunoNome = '';
  String _alunoMatricula = '';

  var _respostasLidas = [];
  bool _carregando = false;
  bool _processandoLeitura = false;

  MobileScannerController? _scannerController;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _iniciarCamera() {
    if (kIsWeb) {
      _mensagem(
        'A leitura de QR Code pela câmera funciona no Android/mobile. No navegador, selecione a prova abaixo.',
      );
      return;
    }

    if (_uid.isEmpty) {
      _mensagem('Faça login para escanear provas.');
      return;
    }

    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    setState(() {
      _processandoLeitura = false;
      etapa = 1;
    });
  }

  Future<void> _aoDetectarQrCode(BarcodeCapture capture) async {
    if (_processandoLeitura) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final raw = barcodes.first.rawValue!.trim();
    if (raw.isEmpty) return;

    setState(() => _processandoLeitura = true);
    await _scannerController?.stop();

    try {
      String provaId = raw;
      String? alunoId;
      var respostasDoQr = [];

      if (raw.startsWith('{')) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        provaId = (decoded['provaId'] ?? decoded['id'] ?? '').toString();
        alunoId = decoded['alunoId']?.toString();
        final rawRespostas = decoded['respostas'];
        if (rawRespostas is List) {
          for (final item in rawRespostas) {
            respostasDoQr.add(item?.toString());
          }
        }
      }

      if (provaId.isEmpty) {
        throw Exception('QR Code inválido: identificador da prova não encontrado.');
      }

      await _carregarEProcessarCorrecaoAutomatica(
        provaId: provaId,
        alunoId: alunoId ?? _alunoSelecionadoId,
        respostasCapturadas: respostasDoQr,
      );
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) {
        setState(() => _processandoLeitura = false);
        await _scannerController?.start();
      }
    }
  }

  Future<void> _carregarEProcessarCorrecaoAutomatica({
    required String provaId,
    String? alunoId,
    respostasCapturadas = const [],
  }) async {
    if (_uid.isEmpty) {
      _mensagem('Usuário não autenticado. Faça login novamente.');
      return;
    }

    setState(() => _carregando = true);

    try {
      final provaDoc = await _db.collection('criarProvas').doc(provaId).get();
      if (!provaDoc.exists) {
        throw Exception('Prova ($provaId) não encontrada em criarProvas.');
      }

      final dadosProva = provaDoc.data() ?? <String, dynamic>{};
      final rawQuestoesIds = dadosProva['questoesIds'] ?? dadosProva['questoes'];
      List<String> questoesIds = [];
      if (rawQuestoesIds is List) {
        for (final item in rawQuestoesIds) {
          questoesIds.add(item.toString());
        }
      }

      if (questoesIds.isEmpty) {
        throw Exception('A prova selecionada não possui questões vinculadas.');
      }

      final rawGabarito = dadosProva['gabarito'];
      Map<String, dynamic> gabaritoMap = {};
      if (rawGabarito is Map) {
        rawGabarito.forEach((k, v) {
          gabaritoMap[k.toString()] = v;
        });
      }

      var questoesCarregadas = [];

      for (final qId in questoesIds) {
        final qDoc = await _db.collection('questoes').doc(qId).get();
        if (!qDoc.exists) continue;

        final q = qDoc.data() ?? <String, dynamic>{};
        final rawAlternativas = q['alternativas'];
        List<String> alternativas = [];
        if (rawAlternativas is List) {
          for (final alt in rawAlternativas) {
            alternativas.add(alt.toString());
          }
        }

        final rawCorretas = q['corretas'];
        List<int> corretas = [];
        if (rawCorretas is List) {
          for (final c in rawCorretas) {
            final parsed = c is int ? c : int.tryParse(c.toString()) ?? -1;
            corretas.add(parsed);
          }
        }

        final int primeiroIndice = corretas.isNotEmpty ? corretas.first : -1;
        final String letraCorreta =
        (primeiroIndice >= 0 && primeiroIndice < alternativas.length)
            ? String.fromCharCode(65 + primeiroIndice)
            : '';

        questoesCarregadas.add({
          'id': qDoc.id,
          'enunciado': (q['enunciado'] ?? '').toString(),
          'alternativas': alternativas,
          'gabarito': (gabaritoMap[qDoc.id] ?? letraCorreta).toString(),
        });
      }

      if (questoesCarregadas.isEmpty) {
        throw Exception('Não foi possível carregar as questões desta prova.');
      }

      String nomeAlunoFinal = 'Aluno não identificado';
      String matriculaFinal = '';
      final turmaId = (dadosProva['turmaId'] ?? '').toString();

      if (alunoId != null && alunoId.isNotEmpty && turmaId.isNotEmpty) {
        final docSub = await _db
            .collection('turmas')
            .doc(turmaId)
            .collection('alunos')
            .doc(alunoId)
            .get();

        if (docSub.exists) {
          final dadosAluno = docSub.data() ?? <String, dynamic>{};
          nomeAlunoFinal = (dadosAluno['nome'] ?? 'Aluno').toString();
          matriculaFinal = (dadosAluno['matricula'] ?? alunoId).toString();
        } else {
          nomeAlunoFinal = 'Aluno ($alunoId)';
          matriculaFinal = alunoId;
        }
      } else if (alunoId != null && alunoId.isNotEmpty) {
        nomeAlunoFinal = 'Aluno ($alunoId)';
        matriculaFinal = alunoId;
    }

    var respostasFinais = List.generate(
    questoesCarregadas.length,
    (i) {
    if (i < respostasCapturadas.length) {
    return respostasCapturadas[i];
    }
    return questoesCarregadas[i]['gabarito'];
    },
    );

    int acertos = 0;
    int emBranco = 0;

    for (int i = 0; i < questoesCarregadas.length; i++) {
    final marcada = respostasFinais[i];
    final correta = questoesCarregadas[i]['gabarito'];
    if (marcada == null || marcada.toString().isEmpty) {
    emBranco++;
    } else if (marcada.toString() == correta.toString()) {
    acertos++;
    }
    }

    final total = questoesCarregadas.length;
    final erros = total - acertos - emBranco;
    final nota = total == 0 ? 0.0 : (acertos / total) * 10.0;
    final aproveitamento = total == 0 ? 0.0 : (acertos / total);

    final respostasDetalhadas = List.generate(total, (i) {
    final marcadaStr = respostasFinais[i]?.toString();
    final gabStr = questoesCarregadas[i]['gabarito'].toString();
    return {
    'questaoId': questoesCarregadas[i]['id'],
    'numero': i + 1,
    'marcada': marcadaStr,
    'gabarito': gabStr,
    'correta': marcadaStr != null && marcadaStr == gabStr,
    };
    });

    await _db.collection('correcoes').add({
    'professorId': _uid,
    'criadoPor': _uid,
    'provaId': provaId,
    'tituloProva': dadosProva['titulo'] ?? dadosProva['nome'] ?? 'Prova',
    'disciplina': dadosProva['disciplina'] ?? dadosProva['materia'] ?? '',
    'turma': dadosProva['turma'] ?? dadosProva['turmaNome'] ?? '',
    'turmaId': turmaId,
    'alunoId': alunoId ?? '',
    'alunoNome': nomeAlunoFinal,
    'matricula': matriculaFinal,
    'respostas': respostasDetalhadas,
    'totalQuestoes': total,
    'acertos': acertos,
    'erros': erros,
    'emBranco': emBranco,
    'nota': nota,
    'aproveitamento': aproveitamento,
    'dataCorrecao': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
    _provaSelecionadaId = provaId;
    _prova = dadosProva;
    _questoes = questoesCarregadas;
    _respostasLidas = respostasFinais;
    _alunoNome = nomeAlunoFinal;
    _alunoMatricula = matriculaFinal;
    etapa = 2;
    });
    } catch (e) {
    _mensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
    if (mounted) {
    setState(() {
    _carregando = false;
    _processandoLeitura = false;
    });
    }
    }
  }

  void _mensagem(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _reiniciar() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      etapa = 0;
      _prova = null;
      _questoes = [];
      _respostasLidas = [];
      _alunoNome = '';
      _alunoMatricula = '';
      _processandoLeitura = false;
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
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Column(
          children: [
            CircularProgressIndicator(color: verde),
            SizedBox(height: 16),
            Text('Processando gabarito e salvando nota no Firebase...'),
          ],
        ),
      );
    }

    if (etapa == 1) return _buildLeitorQrCode();
    if (etapa == 2) return _buildResultado();
    return _buildInicio();
  }

  Widget _buildInicio() {
    if (_uid.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cinza,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Faça login para acessar e corrigir suas provas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: texto),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verde.withValues(alpha: 0.25)),
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
              Icons.qr_code_scanner,
              size: 50,
              color: fundo,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Correção automática',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w800,
              color: verde,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aponte a câmera para o QR Code da folha de respostas para identificar a prova, o aluno e calcular a nota automaticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: texto),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _iniciarCamera,
              icon: const Icon(Icons.camera_alt_outlined, size: 24),
              label: const Text(
                'Escanear QR Code da Prova',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: _estiloBotao(),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Ou selecione uma prova cadastrada no sistema:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: texto,
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder(
            stream: _db
                .collection('criarProvas')
                .where('criadoPor', isEqualTo: _uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Erro ao carregar provas: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(color: verde);
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text(
                  'Nenhuma prova cadastrada. Crie uma prova na aba "Criar Prova".',
                  textAlign: TextAlign.center,
                );
              }

              final valorValido = docs.any((d) => d.id == _provaSelecionadaId)
                  ? _provaSelecionadaId
                  : null;

              Map<String, dynamic>? provaAtual;
              if (valorValido != null) {
                provaAtual =
                    docs.firstWhere((d) => d.id == valorValido).data();
              }
              final turmaIdSelecionada =
              (provaAtual?['turmaId'] ?? '').toString();

              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: valorValido,
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
                      final d = doc.data();
                      final titulo = d['titulo'] ?? d['nome'] ?? 'Prova sem título';
                      final turma = d['turma'] ?? d['turmaNome'] ?? '';
                      final disc = d['disciplina'] ?? d['materia'] ?? '';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          '$titulo${disc.toString().isNotEmpty ? " • $disc" : ""}${turma.toString().isNotEmpty ? " ($turma)" : ""}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        _provaSelecionadaId = id;
                        _alunoSelecionadoId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (turmaIdSelecionada.isNotEmpty)
                    StreamBuilder(
                      stream: _db
                          .collection('turmas')
                          .doc(turmaIdSelecionada)
                          .collection('alunos')
                          .snapshots(),
                      builder: (context, alunoSnap) {
                        if (!alunoSnap.hasData ||
                            alunoSnap.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final alunosDocs = alunoSnap.data!.docs;
                        final alunoValido = alunosDocs
                            .any((a) => a.id == _alunoSelecionadoId)
                            ? _alunoSelecionadoId
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: alunoValido,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText:
                              'Aluno da turma (opcional se estiver no QR Code)',
                              filled: true,
                              fillColor: fundo,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: alunosDocs.map((doc) {
                              final a = doc.data();
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  a['nome'] ?? 'Aluno',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (id) =>
                                setState(() => _alunoSelecionadoId = id),
                          ),
                        );
                      },
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: valorValido == null
                          ? null
                          : () => _carregarEProcessarCorrecaoAutomatica(
                        provaId: valorValido,
                        alunoId: _alunoSelecionadoId,
                      ),
                      icon: const Icon(Icons.bolt),
                      label: const Text('Corrigir Prova Selecionada'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: verde,
                        side: const BorderSide(color: verde, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeitorQrCode() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Escaneando Folha de Respostas',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.bold,
              color: verde,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Posicione o QR Code impresso no gabarito dentro da moldura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: texto),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 340,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_scannerController != null && !kIsWeb)
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _aoDetectarQrCode,
                    ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _reiniciar,
            icon: const Icon(Icons.close, color: verde),
            label:
            const Text('Cancelar leitura', style: TextStyle(color: verde)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    int acertos = 0;
    int emBranco = 0;

    for (int i = 0; i < _questoes.length; i++) {
      final resp = _respostasLidas[i];
      if (resp == null || resp.toString().isEmpty) {
        emBranco++;
      } else if (resp.toString() == _questoes[i]['gabarito'].toString()) {
        acertos++;
      }
    }

    final total = _questoes.length;
    final erros = total - acertos - emBranco;
    final nota = total == 0 ? 0.0 : (acertos / total) * 10;
    final aproveitamento = total == 0 ? 0 : (acertos / total) * 100;

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
        const SizedBox(height: 6),
        Text(
          'Nota salva automaticamente no Firebase',
          style: TextStyle(
            fontSize: 14,
            color: verde.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: verde),
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
                  child: _infoCard(
                      'Acertos', '$acertos', Icons.check_circle_outline),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard('Erros', '$erros', Icons.cancel_outlined),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard('Em branco', '$emBranco',
                      Icons.remove_circle_outline),
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
                'Dados da correção',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: verde,
                ),
              ),
              const SizedBox(height: 14),
              Text('Aluno: $_alunoNome'),
              if (_alunoMatricula.isNotEmpty)
                Text('Matrícula: $_alunoMatricula'),
              Text('Turma: ${_prova?['turma'] ?? _prova?['turmaNome'] ?? '—'}'),
              Text('Disciplina: ${_prova?['disciplina'] ?? _prova?['materia'] ?? '—'}'),
              Text('Prova: ${_prova?['titulo'] ?? _prova?['nome'] ?? '—'}'),
              Text('Data: ${DateTime.now().toString().substring(0, 10)}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _iniciarCamera,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Ler próxima prova'),
                  style: _estiloBotao(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _reiniciar,
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Início'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: verde,
                    side: const BorderSide(color: verde),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _estiloBotao() {
    return ElevatedButton.styleFrom(
      backgroundColor: verde,
      foregroundColor: Colors.white,
      disabledBackgroundColor: verde.withValues(alpha: 0.4),
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