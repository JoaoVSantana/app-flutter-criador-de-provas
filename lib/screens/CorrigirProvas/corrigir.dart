import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/drawernav.dart';
import '../../widgets/header.dart';
import '../../widgets/navegar.dart';
import '../../service/omr_leitor.dart';

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

  static const double _pageWidth = 595.28;
  static const double _pageHeight = 841.89;
  static const double _questionTop = 164;
  static const double _rowHeight = 16.5;
  static const double _bubbleStartX = 110;
  static const double _bubbleGap = 34;
  static const double _bubbleSize = 18;
  static const int _maxQuestions = 30;
  static const int _maxAlternatives = 5;

  int etapa = 0;

  String? _provaSelecionadaId;
  Map<String, dynamic>? _prova;
  var _questoes = [];

  String? _alunoSelecionadoId;
  String _alunoNome = '';
  String _alunoMatricula = '';

  String _turmaNome = '';
  String _disciplinaNome = '';

  bool _mostrarSelecaoAluno = false;
  Map<String, dynamic>? _dadosFolhaSelecionada;

  var _respostasLidas = [];
  bool _carregando = false;
  bool _processandoLeitura = false;

  MobileScannerController? _scannerController;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imagemFolha;
  final Set<int> _respostasAmbiguas = {};
  String _turmaId = '';
  dynamic _versaoFolha = 1;

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

  Future<dynamic> _buscarFolhaAlunoPorCodigo({
    required String codigoQr,
    String? provaIdInformada,
  }) async {
    final uidAtual = _auth.currentUser?.uid;
    if (uidAtual == null) return null;

    final codigoLimpo = codigoQr.trim();
    if (codigoLimpo.isEmpty) return null;

    if (provaIdInformada != null && provaIdInformada.isNotEmpty) {
      final snap = await _db
          .collection('criarProvas')
          .doc(provaIdInformada)
          .collection('alunos')
          .where('criadoPor', isEqualTo: uidAtual)
          .where('codigo', isEqualTo: codigoLimpo)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return {
          'provaId': provaIdInformada,
          'alunoDocId': snap.docs.first.id,
          'dadosAluno': snap.docs.first.data(),
        };
      }
    }

    final provasSnap = await _db
        .collection('criarProvas')
        .where('criadoPor', isEqualTo: uidAtual)
        .get();

    for (final provaDoc in provasSnap.docs) {
      final alunosSnap = await provaDoc.reference
          .collection('alunos')
          .where('criadoPor', isEqualTo: uidAtual)
          .where('codigo', isEqualTo: codigoLimpo)
          .limit(1)
          .get();

      if (alunosSnap.docs.isNotEmpty) {
        return {
          'provaId': provaDoc.id,
          'alunoDocId': alunosSnap.docs.first.id,
          'dadosAluno': alunosSnap.docs.first.data(),
        };
      }
    }

    return null;
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
      String codigoLido = raw;
      String? provaIdFromQr;
      String? alunoIdFromQr;

      if (raw.startsWith('{')) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        codigoLido =
            (decoded['codigo'] ?? decoded['provaId'] ?? decoded['id'] ?? '')
                .toString()
                .trim();
        provaIdFromQr = decoded['provaId']?.toString();
        alunoIdFromQr = decoded['alunoId']?.toString();
      }

      if (codigoLido.isEmpty) {
        throw Exception('QR Code inválido: código não encontrado.');
      }

      final encontrada = await _buscarFolhaAlunoPorCodigo(
        codigoQr: codigoLido,
        provaIdInformada: provaIdFromQr ?? _provaSelecionadaId,
      );

      if (encontrada == null && (provaIdFromQr == null || alunoIdFromQr == null)) {
        throw Exception('Não foi possível identificar o aluno e a prova pelo QR Code.');
      }

      final provaIdFinal = encontrada?['provaId']?.toString() ??
          provaIdFromQr ??
          _provaSelecionadaId!;
      final alunoDocIdFinal = encontrada?['alunoDocId']?.toString() ??
          alunoIdFromQr ??
          _alunoSelecionadoId;

      Map<String, dynamic>? dadosFolhaAluno;
      if (encontrada?['dadosAluno'] is Map) {
        dadosFolhaAluno =
        Map<String, dynamic>.from(encontrada!['dadosAluno'] as Map);
      }

      await _carregarDadosParaCorrecao(
        provaId: provaIdFinal,
        alunoId: alunoDocIdFinal,
        dadosFolhaAluno: dadosFolhaAluno,
      );

      if (mounted && etapa == 1) {
        await _scannerController?.start();
      }
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) {
        setState(() => _processandoLeitura = false);
        await _scannerController?.start();
      }
    }
  }

  String _normalizarResposta(dynamic valor, int quantidadeAlternativas) {
    if (valor == null) return '';

    final resposta = valor.toString().trim().toUpperCase();
    if (resposta.isEmpty || resposta == '-1') return '';

    final indice = int.tryParse(resposta);
    if (indice != null) {
      if (indice >= 0 && indice < quantidadeAlternativas) {
        return String.fromCharCode(65 + indice);
      }
      return '';
    }

    if (RegExp(r'^[A-Z]$').hasMatch(resposta)) {
      return resposta;
    }

    return '';
  }

  Future<void> _carregarDadosParaCorrecao({
    required String provaId,
    String? alunoId,
    Map<String, dynamic>? dadosFolhaAluno,
  }) async {
    if (_uid.isEmpty) {
      _mensagem('Usuário não autenticado. Faça login novamente.');
      return;
    }

    if (_carregando) return;
    setState(() => _carregando = true);

    try {
      final provaDoc = await _db.collection('criarProvas').doc(provaId).get();

      if (!provaDoc.exists) {
        throw Exception('Prova não encontrada.');
      }

      final dadosProva = provaDoc.data() ?? <String, dynamic>{};
      final rawQuestoesIds =
          dadosProva['questoesIds'] ?? dadosProva['questoes'];
      final List<dynamic> listaQuestoes =
      rawQuestoesIds is List ? rawQuestoesIds : [];

      if (listaQuestoes.isEmpty) {
        throw Exception('A prova não possui questões vinculadas.');
      }

      if (listaQuestoes.length > _maxQuestions) {
        throw Exception(
          'O cartão-resposta suporta no máximo ${_maxQuestions} questões.',
        );
      }

      final Map<String, dynamic> gabaritoMap = {};
      final rawGabarito = dadosProva['gabarito'];

      if (rawGabarito is Map) {
        rawGabarito.forEach((chave, valor) {
          gabaritoMap[chave.toString()] = valor;
        });
      }

      final List<Map<String, dynamic>> questoesCarregadas = [];

      for (int i = 0; i < listaQuestoes.length; i++) {
        final item = listaQuestoes[i];

        late Map<String, dynamic> questao;
        late String questaoId;

        if (item is Map) {
          questao = Map<String, dynamic>.from(item);
          questaoId = (questao['id'] ??
              questao['questaoId'] ??
              questao['codigo'] ??
              'questao_$i')
              .toString();
        } else {
          questaoId = item.toString();
          final qDoc = await _db.collection('questoes').doc(questaoId).get();

          if (!qDoc.exists) {
            throw Exception('Questão $questaoId não encontrada.');
          }

          questao = qDoc.data() ?? <String, dynamic>{};
          questaoId = qDoc.id;
        }

        final rawAlternativas = questao['alternativas'];
        final List<String> alternativas = rawAlternativas is List
            ? rawAlternativas.map((e) => e.toString()).toList()
            : [];

        if (alternativas.isEmpty) {
          throw Exception('A questão ${i + 1} não possui alternativas.');
        }

        if (alternativas.length > _maxAlternatives) {
          throw Exception(
            'A questão ${i + 1} possui mais alternativas que o cartão-resposta suporta.',
          );
        }

        dynamic respostaCorreta = gabaritoMap[questaoId];
        respostaCorreta ??= gabaritoMap[questao['codigo']?.toString()];
        respostaCorreta ??= questao['gabarito'];

        final rawCorretas = questao['corretas'];
        final rawCorreta = questao['correta'];
        respostaCorreta ??= rawCorretas is List && rawCorretas.isNotEmpty
            ? rawCorretas.first
            : rawCorreta;

        if (respostaCorreta == null) {
          throw Exception(
            'Não foi possível encontrar o gabarito da questão ${i + 1}.',
          );
        }

        final gabarito =
        _normalizarResposta(respostaCorreta, alternativas.length);

        if (gabarito.isEmpty) {
          throw Exception('Gabarito inválido na questão ${i + 1}.');
        }

        questoesCarregadas.add({
          'id': questaoId,
          'enunciado': (questao['enunciado'] ?? '').toString(),
          'alternativas': alternativas,
          'gabarito': gabarito,
        });
      }

      final dadosFolha = dadosFolhaAluno ?? <String, dynamic>{};
      final turmaId =
      (dadosFolha['turmaId'] ?? dadosProva['turmaId'] ?? '').toString();

      String turmaNomeFinal = (dadosFolha['turmaNome'] ??
          dadosProva['turmaNome'] ??
          dadosProva['turma'] ??
          '')
          .toString();

      final disciplinaFinal = (dadosProva['disciplina'] ??
          dadosProva['disciplinaNome'] ??
          dadosProva['materia'] ??
          '')
          .toString();

      if (turmaNomeFinal.isEmpty && turmaId.isNotEmpty) {
        final turmaDoc = await _db.collection('turmas').doc(turmaId).get();

        if (turmaDoc.exists) {
          final dadosTurma = turmaDoc.data() ?? {};
          turmaNomeFinal = (dadosTurma['nome'] ??
              dadosTurma['turmaNome'] ??
              dadosTurma['nomeTurma'] ??
              '')
              .toString();
        }
      }

      String nomeAlunoFinal = (dadosFolha['alunoNome'] ?? '').toString();
      String matriculaFinal = (dadosFolha['matricula'] ?? '').toString();

      if (nomeAlunoFinal.isEmpty && alunoId != null && alunoId.isNotEmpty) {
        if (turmaId.isNotEmpty) {
          final docAluno = await _db
              .collection('turmas')
              .doc(turmaId)
              .collection('alunos')
              .doc(alunoId)
              .get();

          if (docAluno.exists) {
            final dadosAluno = docAluno.data() ?? {};
            nomeAlunoFinal = (dadosAluno['nome'] ?? 'Aluno').toString();
            matriculaFinal =
                (dadosAluno['matricula'] ?? alunoId).toString();
          }
        }

        if (nomeAlunoFinal.isEmpty) {
          nomeAlunoFinal = 'Aluno ($alunoId)';
          matriculaFinal = alunoId;
        }
      }

      if (nomeAlunoFinal.isEmpty) {
        nomeAlunoFinal = 'Aluno não identificado';
      }

      if (!mounted) return;
      setState(() {
        _provaSelecionadaId = provaId;
        _prova = dadosProva;
        _questoes = questoesCarregadas;
        _alunoSelecionadoId = alunoId;
        _alunoNome = nomeAlunoFinal;
        _alunoMatricula = matriculaFinal;
        _turmaNome = turmaNomeFinal;
        _disciplinaNome = disciplinaFinal;
        _turmaId = turmaId;
        _versaoFolha = dadosFolha['versao'] ?? 1;
        _dadosFolhaSelecionada = dadosFolha;
        _imagemFolha = null;
        _respostasLidas = [];
        _respostasAmbiguas.clear();
        etapa = 2;
      });
    } on FirebaseException catch (e) {
      _mensagem('Erro Firebase: ${e.code} - ${e.message}');
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

  Future<void> _capturarFotoFolha() async {
    if (_questoes.isEmpty) {
      _mensagem('Nenhuma questão carregada para corrigir.');
      return;
    }

    try {
      final arquivo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (arquivo == null) return;

      setState(() => _carregando = true);

      final bytes = await arquivo.readAsBytes();
      final bolhas = <BolhaPosicao>[];

      for (var i = 0; i < _questoes.length; i++) {
        final alternativas =
        _questoes[i]['alternativas'] as List<dynamic>;

        for (var alternativa = 0;
        alternativa < alternativas.length;
        alternativa++) {
          bolhas.add(
            BolhaPosicao(
              questao: i + 1,
              alternativa: alternativa,
              x: (_bubbleStartX + alternativa * _bubbleGap + _bubbleSize / 2) /
                  _pageWidth,
              y: (_questionTop + i * _rowHeight +
                  (_rowHeight - _bubbleSize) / 2 +
                  _bubbleSize / 2) /
                  _pageHeight,
              raio: (_bubbleSize / 2) / _pageWidth,
            ),
          );
        }
      }

      final leitura = OMRLeitor.analisar(
        bytes: bytes,
        bolhas: bolhas,
      );

      final respostas = List<String>.filled(_questoes.length, '');
      final ambiguas = <int>{};

      for (final resposta in leitura) {
        final indice = resposta.questao - 1;
        if (indice < 0 || indice >= respostas.length) continue;

        if (resposta.ambigua) {
          ambiguas.add(indice);
        } else if (resposta.alternativa != null) {
          respostas[indice] =
              String.fromCharCode(65 + resposta.alternativa!);
        }
      }

      if (!mounted) return;
      setState(() {
        _imagemFolha = bytes;
        _respostasLidas = respostas;
        _respostasAmbiguas
          ..clear()
          ..addAll(ambiguas);
        etapa = 3;
      });
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _salvarCorrecao() async {
    if (_provaSelecionadaId == null || _prova == null) {
      _mensagem('Não foi possível identificar a prova.');
      return;
    }

    if (_respostasAmbiguas.isNotEmpty) {
      _mensagem('Revise todas as marcações ambíguas antes de salvar.');
      return;
    }

    if (_respostasLidas.length != _questoes.length) {
      _mensagem('A leitura das respostas está incompleta.');
      return;
    }

    setState(() => _carregando = true);

    try {
      final usuario = _auth.currentUser;
      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      int acertos = 0;
      int emBranco = 0;

      for (var i = 0; i < _questoes.length; i++) {
        final marcada = _respostasLidas[i];
        final correta = _questoes[i]['gabarito'].toString();

        if (marcada.isEmpty) {
          emBranco++;
        } else if (marcada == correta) {
          acertos++;
        }
      }

      final total = _questoes.length;
      final erros = total - acertos - emBranco;
      final nota = total == 0 ? 0.0 : (acertos / total) * 10.0;
      final aproveitamento = total == 0 ? 0.0 : acertos / total;

      final respostasDetalhadas = List.generate(total, (i) {
        final marcada = _respostasLidas[i];
        final gabarito = _questoes[i]['gabarito'].toString();

        return {
          'questaoId': _questoes[i]['id'],
          'numero': i + 1,
          'marcada': marcada.isEmpty ? null : marcada,
          'gabarito': gabarito,
          'correta': marcada.isNotEmpty && marcada == gabarito,
        };
      });

      final dadosCorrecao = {
        'professorId': usuario.uid,
        'criadoPor': usuario.uid,
        'provaId': _provaSelecionadaId,
        'tituloProva': _prova!['titulo'] ?? _prova!['nome'] ?? 'Prova',
        'turma': _turmaNome,
        'turmaNome': _turmaNome,
        'disciplina': _disciplinaNome,
        'turmaId': _turmaId,
        'alunoId': _alunoSelecionadoId ?? '',
        'alunoNome': _alunoNome,
        'matricula': _alunoMatricula,
        'versao': _versaoFolha,
        'respostas': respostasDetalhadas,
        'totalQuestoes': total,
        'acertos': acertos,
        'erros': erros,
        'emBranco': emBranco,
        'nota': nota,
        'aproveitamento': aproveitamento,
        'dataCorrecao': FieldValue.serverTimestamp(),
      };

      final correcaoRef =
      await _db.collection('correcoes').add(dadosCorrecao);
      final correcaoSalva = await correcaoRef.get();

      if (!correcaoSalva.exists) {
        throw Exception('Não foi possível confirmar o salvamento da correção.');
      }

      if (!mounted) return;
      setState(() => etapa = 4);
      _mensagem('Correção salva com sucesso.');
    } on FirebaseException catch (e) {
      _mensagem('Erro Firebase: ${e.code} - ${e.message}');
    } catch (e) {
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _alterarResposta(int indice, String? valor) {
    if (valor == null) return;

    setState(() {
      _respostasLidas[indice] = valor;
      _respostasAmbiguas.remove(indice);
    });
  }

  void _mensagem(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reiniciar() {
    _scannerController?.dispose();
    _scannerController = null;

    setState(() {
      etapa = 0;
      _provaSelecionadaId = null;
      _prova = null;
      _questoes = [];
      _respostasLidas = [];
      _alunoSelecionadoId = null;
      _alunoNome = '';
      _alunoMatricula = '';
      _dadosFolhaSelecionada = null;
      _mostrarSelecaoAluno = false;
      _processandoLeitura = false;
      _turmaNome = '';
      _disciplinaNome = '';
      _imagemFolha = null;
      _respostasAmbiguas.clear();
      _turmaId = '';
      _versaoFolha = 1;
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
            Text('Processando folha de respostas...'),
          ],
        ),
      );
    }

    if (etapa == 1) return _buildLeitorQrCode();
    if (etapa == 2) return _buildCapturaFoto();
    if (etapa == 3) return _buildRevisao();
    if (etapa == 4) return _buildResultado();
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
            child: const Icon(Icons.qr_code_scanner, size: 50, color: fundo),
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
            'Aponte a câmera para o QR Code para identificar a prova e o aluno. Depois, fotografe o cartão-resposta físico para ler as bolinhas.',
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
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                      final titulo =
                          d['titulo'] ?? d['nome'] ?? 'Prova sem título';
                      final turma = d['turma'] ?? d['turmaNome'] ?? '';
                      final disciplina = d['disciplina'] ?? d['materia'] ?? '';

                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          '$titulo'
                              '${disciplina.toString().isNotEmpty ? " • $disciplina" : ""}'
                              '${turma.toString().isNotEmpty ? " ($turma)" : ""}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        _provaSelecionadaId = id;
                        _alunoSelecionadoId = null;
                        _dadosFolhaSelecionada = null;
                        _mostrarSelecaoAluno = false;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: valorValido == null
                          ? null
                          : () {
                        setState(() {
                          _mostrarSelecaoAluno = true;
                          _alunoSelecionadoId = null;
                          _dadosFolhaSelecionada = null;
                        });
                      },
                      icon: const Icon(Icons.people_outline),
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
                  if (_mostrarSelecaoAluno && valorValido != null) ...[
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selecione o aluno que deseja corrigir:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: verde,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection('criarProvas')
                          .doc(valorValido)
                          .collection('alunos')
                          .where('criadoPor', isEqualTo: _uid)
                          .snapshots(),
                      builder: (context, alunoSnapshot) {
                        if (alunoSnapshot.hasError) {
                          return Text(
                            'Erro ao carregar alunos: ${alunoSnapshot.error}',
                          );
                        }

                        if (!alunoSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: verde),
                          );
                        }

                        final alunos = alunoSnapshot.data!.docs;

                        if (alunos.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Nenhum aluno cadastrado para esta prova.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final alunoValido =
                        alunos.any((doc) => doc.id == _alunoSelecionadoId)
                            ? _alunoSelecionadoId
                            : null;

                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: alunoValido,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Aluno',
                                filled: true,
                                fillColor: fundo,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: alunos.map((doc) {
                                final dados = doc.data();
                                final nome =
                                    dados['alunoNome'] ?? 'Aluno sem nome';
                                final codigo = dados['codigo'] ?? '';

                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    '$nome${codigo.toString().isNotEmpty ? " • $codigo" : ""}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id == null) return;

                                final aluno = alunos.firstWhere(
                                      (doc) => doc.id == id,
                                );

                                setState(() {
                                  _alunoSelecionadoId = aluno.id;
                                  _dadosFolhaSelecionada = aluno.data();
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: alunoValido == null
                                    ? null
                                    : () {
                                  _carregarDadosParaCorrecao(
                                    provaId: valorValido,
                                    alunoId: _alunoSelecionadoId,
                                    dadosFolhaAluno:
                                    _dadosFolhaSelecionada,
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Corrigir Aluno'),
                                style: _estiloBotao(),
                              ),
                            ),
                          ],
                        );
                      },
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
            label: const Text(
              'Cancelar leitura',
              style: TextStyle(color: verde),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCapturaFoto() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.document_scanner_outlined, size: 64, color: verde),
          const SizedBox(height: 16),
          const Text(
            'Fotografar cartão-resposta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.bold,
              color: verde,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prova: ${_prova?['titulo'] ?? _prova?['nome'] ?? 'Prova'}\nAluno: $_alunoNome',
            textAlign: TextAlign.center,
            style: const TextStyle(color: texto, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Coloque a folha inteira em uma superfície plana. Enquadre os quatro marcadores pretos dos cantos, mantenha boa iluminação e evite sombras.',
            textAlign: TextAlign.center,
            style: TextStyle(color: texto),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _capturarFotoFolha,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Fotografar folha'),
              style: _estiloBotao(),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _reiniciar,
            child: const Text('Cancelar', style: TextStyle(color: verde)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisao() {
    final totalAmbiguas = _respostasAmbiguas.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Conferir respostas identificadas',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'Oswald',
            fontWeight: FontWeight.bold,
            color: verde,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Aluno: $_alunoNome',
          textAlign: TextAlign.center,
          style: const TextStyle(color: texto),
        ),
        const SizedBox(height: 12),
        if (totalAmbiguas > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange),
            ),
            child: Text(
              '$totalAmbiguas marcação(ões) ambígua(s). Selecione manualmente a resposta correta em cada questão destacada.',
              style: const TextStyle(color: texto),
            ),
          )
        else
          const Text(
            'Confira as respostas antes de salvar. Você pode alterar qualquer alternativa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: texto),
          ),
        const SizedBox(height: 16),
        if (_imagemFolha != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _imagemFolha!,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        const SizedBox(height: 16),
        ...List.generate(_questoes.length, (i) {
          final alternativas =
          _questoes[i]['alternativas'] as List<dynamic>;
          final opcoes = List.generate(
            alternativas.length,
                (j) => String.fromCharCode(65 + j),
          );
          final respostaAtual = _respostasLidas[i];
          final ambigua = _respostasAmbiguas.contains(i);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cinza,
              borderRadius: BorderRadius.circular(12),
              border: ambigua
                  ? Border.all(color: Colors.orange, width: 1.5)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questão ${i + 1}${ambigua ? ' • revisar marcação' : ''}',
                  style: const TextStyle(
                    color: verde,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((_questoes[i]['enunciado'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 8),
                    child: Text(
                      _questoes[i]['enunciado'].toString(),
                      style: const TextStyle(color: texto),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: respostaAtual,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Resposta marcada',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: fundo,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Em branco'),
                    ),
                    ...opcoes.map(
                          (opcao) => DropdownMenuItem(
                        value: opcao,
                        child: Text(
                          '$opcao — ${alternativas[opcoes.indexOf(opcao)]}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (valor) => _alterarResposta(i, valor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gabarito oficial: ${_questoes[i]['gabarito']}',
                  style: const TextStyle(color: verde, fontSize: 12),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: totalAmbiguas > 0 ? null : _salvarCorrecao,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Confirmar e salvar correção'),
            style: _estiloBotao(),
          ),
        ),
        TextButton.icon(
          onPressed: _capturarFotoFolha,
          icon: const Icon(Icons.camera_alt_outlined, color: verde),
          label: const Text(
            'Tirar outra foto',
            style: TextStyle(color: verde),
          ),
        ),
        TextButton(
          onPressed: _reiniciar,
          child: const Text('Cancelar correção', style: TextStyle(color: verde)),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    int acertos = 0;
    int emBranco = 0;

    for (int i = 0; i < _questoes.length; i++) {
      final resp = i < _respostasLidas.length ? _respostasLidas[i] : '';
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
          'Nota salva no Firebase após conferência',
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
                    'Acertos',
                    '$acertos',
                    Icons.check_circle_outline,
                  ),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard('Erros', '$erros', Icons.cancel_outlined),
                ),
                SizedBox(
                  width: largura,
                  child: _infoCard(
                    'Em branco',
                    '$emBranco',
                    Icons.remove_circle_outline,
                  ),
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
              Text('Turma: ${_turmaNome.isNotEmpty ? _turmaNome : '—'}'),
              Text(
                'Disciplina: ${_disciplinaNome.isNotEmpty ? _disciplinaNome : '—'}',
              ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
