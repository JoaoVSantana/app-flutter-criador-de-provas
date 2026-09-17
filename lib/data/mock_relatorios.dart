// Dados simulados (mock) usados enquanto o back-end de correção não existe.
// Basta trocar `provasCorrigidasMock` pela consulta real depois.

import '../models/relatorio.dart';

/// Converte uma string de gabarito/respostas ("CABBE-A") em lista.
/// O caractere '-' representa questão em branco ou não lida.
List<String?> _respostas(String marcadas) =>
    marcadas.split('').map((c) => c == '-' ? null : c).toList();

List<Questao> _questoes(String gabarito, List<String> enunciados,
    List<String> assuntos) {
  final letras = gabarito.split('');
  return List.generate(letras.length, (i) {
    return Questao(
      numero: i + 1,
      enunciado: i < enunciados.length ? enunciados[i] : 'Questão ${i + 1}',
      gabarito: letras[i],
      assunto: i < assuntos.length ? assuntos[i] : '',
    );
  });
}

/// Monta as provas com os resultados já preenchidos.
ProvaCorrigida _montarProva({
  required String id,
  required String titulo,
  required String disciplina,
  required String turma,
  required DateTime data,
  required int versoes,
  required String gabarito,
  required List<String> enunciados,
  required List<String> assuntos,
  required Map<String, String> respostasPorAluno,
  required Map<String, String> matriculas,
}) {
  return ProvaCorrigida(
    id: id,
    titulo: titulo,
    disciplina: disciplina,
    turma: turma,
    dataCorrecao: data,
    versoes: versoes,
    questoes: _questoes(gabarito, enunciados, assuntos),
    resultados: respostasPorAluno.entries
        .map(
          (e) => ResultadoAluno(
            nome: e.key,
            matricula: matriculas[e.key] ?? '—',
            respostas: _respostas(e.value),
          ),
        )
        .toList(),
  );
}

const Map<String, String> _matriculas1AnoA = {
  'Ana Silva Costa': '2023001',
  'Bruno Gomes Souza': '2023002',
  'Carla Mendes Lima': '2023003',
  'Diego Ferreira Alves': '2023004',
  'Eduarda Nunes Pires': '2023005',
  'Felipe Rocha Martins': '2023006',
  'Gabriela Souza Dias': '2023007',
  'Heitor Lima Barbosa': '2023008',
  'Isabela Cardoso Reis': '2023009',
  'João Pedro Almeida': '2023010',
  'Larissa Moreira Sá': '2023011',
  'Mateus Oliveira Cruz': '2023012',
};

const Map<String, String> _matriculas2AnoB = {
  'Alice Ramos Teixeira': '2022101',
  'Caio Bernardes Luz': '2022102',
  'Daniela Prado Matos': '2022103',
  'Enzo Carvalho Pinto': '2022104',
  'Fernanda Klein Bauer': '2022105',
  'Guilherme Antunes Sá': '2022106',
  'Helena Duarte Fogaça': '2022107',
  'Igor Balbinot Kunz': '2022108',
  'Júlia Scheffer Maas': '2022109',
  'Lucas Weber Hoffmann': '2022110',
};

const Map<String, String> _matriculas3AnoA = {
  'Beatriz Nardelli Sell': '2021201',
  'Cristian Bortolini Reif': '2021202',
  'Douglas Marcondes Faria': '2021203',
  'Elisa Kretzer Voltolini': '2021204',
  'Gustavo Zimmermann Reis': '2021205',
  'Ingrid Sasse Brandenburg': '2021206',
  'Murilo Deschamps Vieira': '2021207',
  'Natália Piazera Gonçalves': '2021208',
  'Otávio Schmitt Laurindo': '2021209',
};

/// Lista principal consumida pelas telas de Relatórios.
final List<ProvaCorrigida> provasCorrigidasMock = [
  _montarProva(
    id: 'PRV-2026-014',
    titulo: 'Avaliação Bimestral - Funções',
    disciplina: 'Matemática',
    turma: '1º Ano A',
    data: DateTime(2026, 9, 10),
    versoes: 4,
    gabarito: 'CABBEACBDA',
    enunciados: [
      'Domínio e imagem de uma função',
      'Função afim: coeficiente angular',
      'Raiz da função do 1º grau',
      'Gráfico da função quadrática',
      'Vértice da parábola',
      'Função crescente e decrescente',
      'Sistema de equações do 1º grau',
      'Função composta',
      'Função inversa',
      'Problema aplicado com funções',
    ],
    assuntos: [
      'Funções',
      'Função afim',
      'Função afim',
      'Função quadrática',
      'Função quadrática',
      'Funções',
      'Sistemas',
      'Funções',
      'Funções',
      'Aplicações',
    ],
    matriculas: _matriculas1AnoA,
    respostasPorAluno: {
      'Ana Silva Costa': 'CABBEAEEDA',
      'Bruno Gomes Souza': 'CBABEAECDA',
      'Carla Mendes Lima': 'CDABCACADE',
      'Diego Ferreira Alves': 'CABBEACEDC',
      'Eduarda Nunes Pires': 'CABBBAAEDA',
      'Felipe Rocha Martins': 'DDBCECCADC',
      'Gabriela Souza Dias': 'CDDDBAEADA',
      'Heitor Lima Barbosa': 'CDBDBAAADC',
      'Isabela Cardoso Reis': 'CABCBACCD-',
      'João Pedro Almeida': 'DCBCBEECBC',
      'Larissa Moreira Sá': 'CBBBDCCADC',
      'Mateus Oliveira Cruz': 'CDBCBAEBDC',
    },
  ),
  _montarProva(
    id: 'PRV-2026-011',
    titulo: 'Prova de Recuperação - Citologia',
    disciplina: 'Biologia',
    turma: '2º Ano B',
    data: DateTime(2026, 9, 4),
    versoes: 1,
    gabarito: 'BDACEBDA',
    enunciados: [
      'Estrutura da membrana plasmática',
      'Organelas e suas funções',
      'Transporte ativo e passivo',
      'Mitocôndria e respiração celular',
      'Divisão celular: mitose',
      'Divisão celular: meiose',
      'Células procariontes x eucariontes',
      'Ciclo celular',
    ],
    assuntos: [
      'Membrana',
      'Organelas',
      'Transporte',
      'Metabolismo',
      'Mitose',
      'Meiose',
      'Citologia',
      'Ciclo celular',
    ],
    matriculas: _matriculas2AnoB,
    respostasPorAluno: {
      'Alice Ramos Teixeira': 'BDACEBDA',
      'Caio Bernardes Luz': 'CCDCCB-A',
      'Daniela Prado Matos': 'BD-CCDDA',
      'Enzo Carvalho Pinto': 'BDACCEDC',
      'Fernanda Klein Bauer': 'BDDCEEDD',
      'Guilherme Antunes Sá': 'BDACEEDA',
      'Helena Duarte Fogaça': 'BDACCEBC',
      'Igor Balbinot Kunz': 'BEDCBBBA',
      'Júlia Scheffer Maas': '-DAAEBDA',
      'Lucas Weber Hoffmann': 'CDDCEE-A',
    },
  ),
  _montarProva(
    id: 'PRV-2026-009',
    titulo: 'Avaliação Mensal - Brasil República',
    disciplina: 'História',
    turma: '1º Ano A',
    data: DateTime(2026, 8, 21),
    versoes: 2,
    gabarito: 'ADCBEDACBE',
    enunciados: [
      'Proclamação da República',
      'República da Espada',
      'Política do café com leite',
      'Coronelismo e voto de cabresto',
      'Revolta da Vacina',
      'Semana de Arte Moderna',
      'Revolução de 1930',
      'Estado Novo',
      'Era Vargas: legislação trabalhista',
      'Redemocratização de 1945',
    ],
    assuntos: [
      'República Velha',
      'República Velha',
      'República Velha',
      'República Velha',
      'República Velha',
      'Modernismo',
      'Era Vargas',
      'Era Vargas',
      'Era Vargas',
      'Era Vargas',
    ],
    matriculas: _matriculas1AnoA,
    respostasPorAluno: {
      'Ana Silva Costa': 'ADCBED-EBC',
      'Bruno Gomes Souza': 'BDCBAEACBC',
      'Carla Mendes Lima': 'ADCBEDDCBE',
      'Diego Ferreira Alves': 'ECCDADAEBE',
      'Eduarda Nunes Pires': 'ACCBEDACDE',
      'Felipe Rocha Martins': 'ADCAEDBCE-',
      'Gabriela Souza Dias': 'EDCEADDABE',
      'Heitor Lima Barbosa': 'A-CEADAEBE',
      'Isabela Cardoso Reis': 'AD-DEDACBE',
      'João Pedro Almeida': 'ACABADAEDE',
      'Larissa Moreira Sá': 'ACCBEDAEBE',
      'Mateus Oliveira Cruz': 'ADCBADAABD',
    },
  ),
  _montarProva(
    id: 'PRV-2026-007',
    titulo: 'Simulado - Cinemática e Dinâmica',
    disciplina: 'Física',
    turma: '3º Ano A',
    data: DateTime(2026, 8, 14),
    versoes: 3,
    gabarito: 'CBDAECBD',
    enunciados: [
      'Movimento uniforme',
      'Movimento uniformemente variado',
      'Lançamento vertical',
      'Leis de Newton: 1ª lei',
      'Leis de Newton: 2ª lei',
      'Força de atrito',
      'Plano inclinado',
      'Trabalho e energia',
    ],
    assuntos: [
      'Cinemática',
      'Cinemática',
      'Cinemática',
      'Dinâmica',
      'Dinâmica',
      'Dinâmica',
      'Dinâmica',
      'Energia',
    ],
    matriculas: _matriculas3AnoA,
    respostasPorAluno: {
      'Beatriz Nardelli Sell': 'BBBAECDD',
      'Cristian Bortolini Reif': 'CDDCEADD',
      'Douglas Marcondes Faria': 'CBBADA-D',
      'Elisa Kretzer Voltolini': 'CBBADADD',
      'Gustavo Zimmermann Reis': 'CE-AEABA',
      'Ingrid Sasse Brandenburg': 'CEBACADD',
      'Murilo Deschamps Vieira': 'CBDABABB',
      'Natália Piazera Gonçalves': 'ABBADCDD',
      'Otávio Schmitt Laurindo': 'CECADADA',
    },
  ),
];

/// Agrupa as provas por turma para a aba "Turmas".
List<ResumoTurma> resumosPorTurmaMock() {
  final mapa = <String, List<ProvaCorrigida>>{};
  for (final prova in provasCorrigidasMock) {
    mapa.putIfAbsent(prova.turma, () => []).add(prova);
  }
  final lista = mapa.entries
      .map((e) => ResumoTurma(turma: e.key, provas: e.value))
      .toList();
  lista.sort((a, b) => a.turma.compareTo(b.turma));
  return lista;
}

/// Disciplinas disponíveis para o filtro.
List<String> disciplinasMock() {
  final set = provasCorrigidasMock.map((p) => p.disciplina).toSet().toList()
    ..sort();
  return ['Todas', ...set];
}

/// Turmas disponíveis para o filtro.
List<String> turmasMock() {
  final set = provasCorrigidasMock.map((p) => p.turma).toSet().toList()..sort();
  return ['Todas', ...set];
}
