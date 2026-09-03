import 'package:flutter/material.dart';

class Corrigir extends StatefulWidget {
  const Corrigir({super.key});

  @override
  State<Corrigir> createState() => _CorrigirState();
}

class _CorrigirState extends State<Corrigir> {
  int etapa = 0;

  final List<String> etapas = ['Ler QR Code', 'Ler Gabarito', 'Ler Prova'];

  // Cores utilizadas no sistema
  static const Color fundo = Color.fromARGB(255, 228, 235, 230);
  static const Color cinza = Color.fromARGB(255, 212, 214, 213);
  static const Color verde = Color(0xFF4C6B5E);
  static const Color texto = Color.fromARGB(255, 26, 29, 28);

  void iniciarCorrecao() {
    setState(() {
      etapa = 1;
    });
  }

  void proximaEtapa() {
    if (etapa < 3) {
      setState(() {
        etapa++;
      });
    } else {
      setState(() {
        etapa = 4;
      });
    }
  }

  void reiniciar() {
    setState(() {
      etapa = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: verde,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _buildConteudo(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (etapa == 0) {
      return _buildInicio();
    }

    if (etapa == 4) {
      return _buildResultado();
    }

    return _buildEtapa();
  }

  // ============================================================
  // TELA INICIAL
  // ============================================================

  Widget _buildInicio() {
    return Container(
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: verde.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: verde,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 55,
              color: fundo,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Correção de provas',
            style: TextStyle(
              fontSize: 38,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w800,
              color: verde,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          const Text(
            'Inicie o processo para realizar a correção '
            'de uma prova.',
            style: TextStyle(fontSize: 17, color: texto),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: 300,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: iniciarCorrecao,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Iniciar correção',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                foregroundColor: fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ETAPAS DA CORREÇÃO
  // ============================================================

  Widget _buildEtapa() {
    final index = etapa - 1;

    return Column(
      children: [
        // Título

        // Indicador das etapas
        Row(
          children: List.generate(etapas.length, (index) {
            final concluida = index < etapa;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: concluida ? verde : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    etapas[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: concluida
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: concluida ? verde : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 50),

        // Card principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(45),
          decoration: BoxDecoration(
            color: cinza,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: verde.withOpacity(0.20)),
          ),
          child: Column(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: verde,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_getIcon(index), size: 60, color: fundo),
              ),

              const SizedBox(height: 30),

              Text(
                etapas[index],
                style: const TextStyle(
                  fontSize: 30,
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w800,
                  color: verde,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _getDescricao(index),
                style: const TextStyle(fontSize: 16, color: texto),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 35),

              // Simulação
              // Ação da etapa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: fundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIcon(index),
                      color: verde,
                      size: 35,
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTituloAcao(index),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: verde,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            _getTextoAcao(index),
                            style: TextStyle(
                              color: texto.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: proximaEtapa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    foregroundColor: fundo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    index == 2 ? 'Finalizar correção' : 'Continuar',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULTADO
  // ============================================================

  Widget _buildResultado() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: verde,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check, size: 60, color: fundo),
          ),

          const SizedBox(height: 25),

          const Text(
            'Correção concluída!',
            style: TextStyle(
              fontSize: 36,
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w800,
              color: verde,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Resultado da prova',
            style: TextStyle(fontSize: 17, color: texto),
          ),

          const SizedBox(height: 30),

          // Nota
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: cinza,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'NOTA FINAL',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: verde,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  '8,5',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: verde,
                  ),
                ),

                Text(
                  'de 10,0',
                  style: TextStyle(color: texto.withOpacity(0.65)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Estatísticas
          // Estatísticas responsivas
          LayoutBuilder(
            builder: (context, constraints) {
              final bool mobile = constraints.maxWidth < 600;

              final double larguraCard = mobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: larguraCard,
                    child: _buildInfoCard(
                      'Acertos',
                      '17',
                      Icons.check_circle_outline,
                    ),
                  ),

                  SizedBox(
                    width: larguraCard,
                    child: _buildInfoCard(
                      'Erros',
                      '3',
                      Icons.cancel_outlined,
                    ),
                  ),

                  SizedBox(
                    width: larguraCard,
                    child: _buildInfoCard(
                      'Questões',
                      '20',
                      Icons.quiz_outlined,
                    ),
                  ),

                  SizedBox(
                    width: larguraCard,
                    child: _buildInfoCard(
                      'Aproveitamento',
                      '85%',
                      Icons.trending_up,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 15),

          // Dados da prova
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: cinza,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dados da prova',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: verde,
                  ),
                ),

                SizedBox(height: 18),

                Text('Aluno: João da Silva', style: TextStyle(color: texto)),

                SizedBox(height: 8),

                Text('Turma: 2º Ano A', style: TextStyle(color: texto)),

                SizedBox(height: 8),

                Text(
                  'Prova: Avaliação de Matemática',
                  style: TextStyle(color: texto),
                ),

                SizedBox(height: 8),

                Text('Data: 03/09/2026', style: TextStyle(color: texto)),
              ],
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: reiniciar,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Nova correção',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                foregroundColor: fundo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE INFORMAÇÃO
  // ============================================================

  Widget _buildInfoCard(String titulo, String valor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cinza,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icone, color: verde, size: 30),

          const SizedBox(height: 8),

          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: verde,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            titulo,
            style: TextStyle(color: texto.withOpacity(0.70), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PEGAR TÍTULO DA AÇÃO
  // ============================================================

  String _getTituloAcao(int index) {
    switch (index) {
      case 0:
        return 'Clique para ler o QR Code';
      case 1:
        return 'Clique para ler o gabarito';
      case 2:
        return 'Clique para ler a prova';
      default:
        return '';
    }
  }

  String _getTextoAcao(int index) {
    switch (index) {
      case 0:
        return 'Clique em continuar para realizar a leitura do QR Code da prova.';
      case 1:
        return 'Clique em continuar para realizar a leitura do gabarito.';
      case 2:
        return 'Clique em continuar para realizar a leitura da prova do aluno.';
      default:
        return '';
    }
  }

  // ============================================================
  // ÍCONES
  // ============================================================

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.qr_code_scanner;
      case 1:
        return Icons.fact_check_outlined;
      case 2:
        return Icons.description_outlined;
      default:
        return Icons.check;
    }
  }

  // ============================================================
  // DESCRIÇÕES
  // ============================================================

  String _getDescricao(int index) {
    switch (index) {
      case 0:
        return 'Identifique a prova através do QR Code.';
      case 1:
        return 'Identifique o gabarito que será utilizado '
            'para realizar a correção.';
      case 2:
        return 'Realize a leitura da prova respondida pelo aluno.';
      default:
        return '';
    }
  }
}
