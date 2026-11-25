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

  String _turmaNome = '';
  String _disciplinaNome = '';

  bool _mostrarSelecaoAluno = false;
  Map<String, dynamic>? _dadosFolhaSelecionada;

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
      try {
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
      } catch (e) {
        debugPrint('Erro ao ler alunos de ${provaDoc.id}: $e');
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
      var respostasDoQr = [];

      if (raw.startsWith('{')) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        codigoLido = (decoded['codigo'] ??
            decoded['provaId'] ??
            decoded['id'] ??
            '')
            .toString()
            .trim();
        provaIdFromQr = decoded['provaId']?.toString();
        alunoIdFromQr = decoded['alunoId']?.toString();

        final rawRespostas = decoded['respostas'];
        if (rawRespostas is List) {
          for (final item in rawRespostas) {
            respostasDoQr.add(item?.toString());
          }
        }
      }

      if (codigoLido.isEmpty) {
        throw Exception('QR Code inválido: código não encontrado.');
      }

      final encontrada = await _buscarFolhaAlunoPorCodigo(
        codigoQr: codigoLido,
        provaIdInformada: provaIdFromQr ?? _provaSelecionadaId,
      );

      String provaIdFinal = provaIdFromQr ?? _provaSelecionadaId ?? codigoLido;
      String? alunoDocIdFinal = alunoIdFromQr ?? _alunoSelecionadoId;
      Map<String, dynamic>? dadosFolhaAluno;

      if (encontrada != null) {
        provaIdFinal = encontrada['provaId'].toString();
        alunoDocIdFinal = encontrada['alunoDocId']?.toString() ?? alunoDocIdFinal;
        if (encontrada['dadosAluno'] is Map) {
          dadosFolhaAluno =
          Map<String, dynamic>.from(encontrada['dadosAluno'] as Map);
        }
      }

      await _carregarEProcessarCorrecaoAutomatica(
        provaId: provaIdFinal,
        alunoId: alunoDocIdFinal,
        dadosFolhaAluno: dadosFolhaAluno,
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
    Map<String, dynamic>? dadosFolhaAluno,
    List<dynamic> respostasCapturadas = const [],
  }) async {
    if (_uid.isEmpty) {
      _mensagem('Usuário não autenticado. Faça login novamente.');
      return;
    }

    if (_carregando) return;

    setState(() => _carregando = true);

    String normalizarResposta(dynamic valor, int quantidadeAlternativas) {
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

      return resposta;
    }

    try {
      debugPrint('========== INICIANDO CORREÇÃO ==========');
      debugPrint('Prova: $provaId');
      debugPrint('Aluno: $alunoId');

      final provaDoc =
      await _db.collection('criarProvas').doc(provaId).get();

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

          final qDoc =
          await _db.collection('questoes').doc(questaoId).get();

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

        final rawCorretas = questao['corretas'];
        final rawCorreta = questao['correta'];

        dynamic respostaCorreta = gabaritoMap[questaoId];

        respostaCorreta ??=
        gabaritoMap[questao['codigo']?.toString()];

        respostaCorreta ??= questao['gabarito'];

        respostaCorreta ??= rawCorretas is List && rawCorretas.isNotEmpty
            ? rawCorretas.first
            : rawCorreta;

        if (respostaCorreta == null) {
          throw Exception(
            'Não foi possível encontrar o gabarito da questão ${i + 1}.',
          );
        }

        final gabarito = normalizarResposta(
          respostaCorreta,
          alternativas.length,
        );

        if (gabarito.isEmpty) {
          throw Exception(
            'Gabarito inválido na questão ${i + 1}.',
          );
        }

        questoesCarregadas.add({
          'id': questaoId,
          'enunciado': (questao['enunciado'] ?? '').toString(),
          'alternativas': alternativas,
          'gabarito': gabarito,
        });

        debugPrint(
          'Questão ${i + 1}: gabarito $gabarito',
        );
      }

      final dadosFolha = dadosFolhaAluno ?? <String, dynamic>{};

      final turmaId = (dadosFolha['turmaId'] ??
          dadosProva['turmaId'] ??
          '')
          .toString();

      String turmaNomeFinal = (dadosFolha['turmaNome'] ??
          dadosProva['turmaNome'] ??
          dadosProva['turma'] ??
          '')
          .toString();

      String disciplinaFinal = (dadosProva['disciplina'] ??
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

      String nomeAlunoFinal =
      (dadosFolha['alunoNome'] ?? '').toString();

      String matriculaFinal =
      (dadosFolha['matricula'] ?? '').toString();

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

            nomeAlunoFinal =
                (dadosAluno['nome'] ?? 'Aluno').toString();

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

      final List<dynamic> respostasOriginais =
      respostasCapturadas.isNotEmpty
          ? respostasCapturadas
          : (dadosFolha['gabarito'] is List
          ? List<dynamic>.from(dadosFolha['gabarito'])
          : []);

      if (respostasOriginais.isEmpty) {
        throw Exception(
          'Nenhuma resposta encontrada. Leia o QR Code da folha do aluno.',
        );
      }

      final List<String> respostasFinais = List.generate(
        questoesCarregadas.length,
            (i) {
          if (i >= respostasOriginais.length) {
            return '';
          }

          return normalizarResposta(
            respostasOriginais[i],
            (questoesCarregadas[i]['alternativas'] as List).length,
          );
        },
      );

      int acertos = 0;
      int emBranco = 0;

      for (int i = 0; i < questoesCarregadas.length; i++) {
        final marcada = respostasFinais[i];
        final correta = questoesCarregadas[i]['gabarito'].toString();

        if (marcada.isEmpty) {
          emBranco++;
        } else if (marcada == correta) {
          acertos++;
        }
      }

      final total = questoesCarregadas.length;
      final erros = total - acertos - emBranco;
      final nota = (acertos / total) * 10.0;
      final aproveitamento = acertos / total;

      final respostasDetalhadas = List.generate(total, (i) {
        final marcada = respostasFinais[i];
        final gabarito = questoesCarregadas[i]['gabarito'].toString();

        return {
          'questaoId': questoesCarregadas[i]['id'],
          'numero': i + 1,
          'marcada': marcada.isEmpty ? null : marcada,
          'gabarito': gabarito,
          'correta': marcada.isNotEmpty && marcada == gabarito,
        };
      });

      final usuario = _auth.currentUser;

      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      final dadosCorrecao = {
        'professorId': usuario.uid,
        'criadoPor': usuario.uid,
        'provaId': provaId,
        'tituloProva':
        dadosProva['titulo'] ?? dadosProva['nome'] ?? 'Prova',
        'turma': turmaNomeFinal,
        'turmaNome': turmaNomeFinal,
        'disciplina': disciplinaFinal,
        'turmaId': turmaId,
        'alunoId': alunoId ?? '',
        'alunoNome': nomeAlunoFinal,
        'matricula': matriculaFinal,
        'versao': dadosFolha['versao'] ?? 1,
        'respostas': respostasDetalhadas,
        'totalQuestoes': total,
        'acertos': acertos,
        'erros': erros,
        'emBranco': emBranco,
        'nota': nota,
        'aproveitamento': aproveitamento,
        'dataCorrecao': FieldValue.serverTimestamp(),
      };

      debugPrint('========== RESULTADO ==========');
      debugPrint('Aluno: $nomeAlunoFinal');
      debugPrint('Acertos: $acertos');
      debugPrint('Erros: $erros');
      debugPrint('Em branco: $emBranco');
      debugPrint('Nota: $nota');

      await _db.collection('correcoes').add(dadosCorrecao);

      if (!mounted) return;

      setState(() {
        _provaSelecionadaId = provaId;
        _prova = dadosProva;
        _turmaNome = turmaNomeFinal;
        _disciplinaNome = disciplinaFinal;
        _questoes = questoesCarregadas;
        _respostasLidas = respostasFinais;
        _alunoNome = nomeAlunoFinal;
        _alunoMatricula = matriculaFinal;
        etapa = 2;
      });

      debugPrint('========== CORREÇÃO CONCLUÍDA ==========');
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Erro Firebase: ${e.code} - ${e.message}');
      debugPrint('$stackTrace');

      _mensagem('Erro Firebase: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('Erro na correção: $e');
      debugPrint('$stackTrace');

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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

              final valorValido = docs.any(
                    (d) => d.id == _provaSelecionadaId,
              )
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
                      final disciplina =
                          d['disciplina'] ?? d['materia'] ?? '';

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
                        side: const BorderSide(
                          color: verde,
                          width: 1.5,
                        ),
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
                    StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
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
                            child: CircularProgressIndicator(
                              color: verde,
                            ),
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

                        final alunoValido = alunos.any(
                              (doc) => doc.id == _alunoSelecionadoId,
                        )
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
                                  _carregarEProcessarCorrecaoAutomatica(
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
              Text('Turma: ${_turmaNome.isNotEmpty ? _turmaNome : '—'}'),
              Text('Disciplina: ${_disciplinaNome.isNotEmpty ? _disciplinaNome : '—'}'),
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