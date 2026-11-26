import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class BolhaPosicao {
  final int questao;
  final int alternativa;
  final double x;
  final double y;
  final double raio;

  const BolhaPosicao({
    required this.questao,
    required this.alternativa,
    required this.x,
    required this.y,
    required this.raio,
  });
}

class RespostaLida {
  final int questao;
  final int? alternativa;
  final bool ambigua;
  final bool emBranco;

  const RespostaLida({
    required this.questao,
    required this.alternativa,
    required this.ambigua,
    required this.emBranco,
  });
}

class _Marcador {
  final double x;
  final double y;
  final int largura;
  final int altura;
  final int area;

  const _Marcador({
    required this.x,
    required this.y,
    required this.largura,
    required this.altura,
    required this.area,
  });
}

class OMRLeitor {
  static const double larguraPagina = 595.28;
  static const double alturaPagina = 841.89;
  static const double tamanhoMarcador = 18;
  static const double margemMarcador = 22;

  static const int larguraProcessamento = 1200;
  static const int limiteEscuridao = 85;

  static List<RespostaLida> analisar({
    required Uint8List bytes,
    required List<BolhaPosicao> bolhas,
  }) {
    if (bolhas.isEmpty) {
      throw Exception('Nenhuma posição de bolha foi informada.');
    }

    final imagemOriginal = img.decodeImage(bytes);

    if (imagemOriginal == null) {
      throw Exception('Não foi possível abrir a fotografia.');
    }

    final imagemCorrigida = _corrigirPerspectiva(imagemOriginal);

    final resultados = <int, Map<int, double>>{};

    for (final bolha in bolhas) {
      final centroX = (bolha.x * imagemCorrigida.width).round();
      final centroY = (bolha.y * imagemCorrigida.height).round();

      final raio = (bolha.raio *
          min(imagemCorrigida.width, imagemCorrigida.height))
          .round();

      final porcentagem = _pontuacaoPreenchimento(
        imagemCorrigida,
        centroX,
        centroY,
        raio,
      );

      resultados.putIfAbsent(bolha.questao, () => {});
      resultados[bolha.questao]![bolha.alternativa] = porcentagem;
    }

    final respostas = <RespostaLida>[];

    for (final questao in resultados.keys.toList()..sort()) {
      final alternativas = resultados[questao]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (alternativas.isEmpty) {
        respostas.add(
          RespostaLida(
            questao: questao,
            alternativa: null,
            ambigua: false,
            emBranco: true,
          ),
        );
        continue;
      }

      final primeira = alternativas.first;
      final segunda = alternativas.length > 1 ? alternativas[1] : null;

      final marcada = primeira.value >= 0.60;
      final multipla = segunda != null && segunda.value >= 0.60;

      final duvidosa = segunda != null &&
          primeira.value - segunda.value < 0.20;

      respostas.add(
        RespostaLida(
          questao: questao,
          alternativa: marcada && !multipla && !duvidosa
              ? primeira.key
              : null,
          ambigua: marcada && (multipla || duvidosa),
          emBranco: !marcada,
        ),
      );
    }

    return respostas;
  }

  static double _pontuacaoPreenchimento(
      img.Image imagem,
      int centroX,
      int centroY,
      int raio,
      ) {
    final raioCentro = raio * 0.70;
    final distanciaFundoMinima = raio * 1.25;
    final distanciaFundoMaxima = raio * 1.75;
    final faixaFundoVertical = raio * 0.65;

    var somaFundo = 0.0;
    var totalFundo = 0;

    for (var y = centroY - faixaFundoVertical.round();
    y <= centroY + faixaFundoVertical.round();
    y++) {
      for (var x = centroX - distanciaFundoMaxima.round();
      x <= centroX + distanciaFundoMaxima.round();
      x++) {
        if (x < 0 || y < 0 || x >= imagem.width || y >= imagem.height) {
          continue;
        }

        final distanciaHorizontal = (x - centroX).abs();

        if (distanciaHorizontal < distanciaFundoMinima ||
            distanciaHorizontal > distanciaFundoMaxima) {
          continue;
        }

        final pixel = imagem.getPixel(x, y);
        somaFundo +=
            0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        totalFundo++;
      }
    }

    if (totalFundo == 0) return 0;

    final luminosidadeFundo = somaFundo / totalFundo;
    final limiteLocal = luminosidadeFundo - max(22, luminosidadeFundo * 0.12);

    var pixelsEscuros = 0;
    var totalCentro = 0;

    for (var y = centroY - raioCentro.round();
    y <= centroY + raioCentro.round();
    y++) {
      for (var x = centroX - raioCentro.round();
      x <= centroX + raioCentro.round();
      x++) {
        if (x < 0 || y < 0 || x >= imagem.width || y >= imagem.height) {
          continue;
        }

        final distancia = sqrt(
          pow(x - centroX, 2) + pow(y - centroY, 2),
        );

        if (distancia > raioCentro) continue;

        final pixel = imagem.getPixel(x, y);
        final luminosidade =
            0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

        if (luminosidade < limiteLocal) {
          pixelsEscuros++;
        }

        totalCentro++;
      }
    }

    return totalCentro == 0 ? 0 : pixelsEscuros / totalCentro;
  }

  static img.Image _corrigirPerspectiva(img.Image original) {
    final marcadores = _localizarMarcadores(original);
    for (var i = 0; i < marcadores.length; i++) {
    }

    final destinoX = larguraPagina;
    final destinoY = alturaPagina;

    final pontosDestino = <List<double>>[
      [
        margemMarcador + tamanhoMarcador / 2,
        margemMarcador + tamanhoMarcador / 2,
      ],
      [
        destinoX - margemMarcador - tamanhoMarcador / 2,
        margemMarcador + tamanhoMarcador / 2,
      ],
      [
        margemMarcador + tamanhoMarcador / 2,
        destinoY - margemMarcador - tamanhoMarcador / 2,
      ],
      [
        destinoX - margemMarcador - tamanhoMarcador / 2,
        destinoY - margemMarcador - tamanhoMarcador / 2,
      ],
    ];

    final pontosOrigem = <List<double>>[
      [marcadores[0].x, marcadores[0].y],
      [marcadores[1].x, marcadores[1].y],
      [marcadores[2].x, marcadores[2].y],
      [marcadores[3].x, marcadores[3].y],
    ];

    final largura = larguraProcessamento;
    final altura = (largura * alturaPagina / larguraPagina).round();

    final escalaX = largura / larguraPagina;
    final escalaY = altura / alturaPagina;

    final pontosDestinoPixels = pontosDestino
        .map((p) => [p[0] * escalaX, p[1] * escalaY])
        .toList();

    final transformacao = _calcularHomografia(
      pontosDestinoPixels,
      pontosOrigem,
    );

    final resultado = img.Image(width: largura, height: altura);

    for (var y = 0; y < altura; y++) {
      for (var x = 0; x < largura; x++) {
        final denominador =
            transformacao[6] * x + transformacao[7] * y + 1;

        if (denominador.abs() < 0.000001) {
          resultado.setPixelRgb(x, y, 255, 255, 255);
          continue;
        }

        final origemX = (transformacao[0] * x +
            transformacao[1] * y +
            transformacao[2]) /
            denominador;

        final origemY = (transformacao[3] * x +
            transformacao[4] * y +
            transformacao[5]) /
            denominador;

        if (origemX < 0 ||
            origemY < 0 ||
            origemX >= original.width - 1 ||
            origemY >= original.height - 1) {
          resultado.setPixelRgb(x, y, 255, 255, 255);
          continue;
        }

        final pixel = original.getPixel(
          origemX.round(),
          origemY.round(),
        );

        resultado.setPixelRgb(
          x,
          y,
          pixel.r.round().clamp(0, 255),
          pixel.g.round().clamp(0, 255),
          pixel.b.round().clamp(0, 255),
        );
      }
    }

    return resultado;
  }

  static List<_Marcador> _localizarMarcadores(img.Image imagem) {
    final regioes = <List<int>>[
      [0, 0, imagem.width ~/ 5, imagem.height ~/ 5],
      [
        imagem.width * 4 ~/ 5,
        0,
        imagem.width,
        imagem.height ~/ 5,
      ],
      [
        0,
        imagem.height * 4 ~/ 5,
        imagem.width ~/ 5,
        imagem.height,
      ],
      [
        imagem.width * 4 ~/ 5,
        imagem.height * 4 ~/ 5,
        imagem.width,
        imagem.height,
      ],
    ];

    final marcadores = <_Marcador>[];

    final cantos = <List<double>>[
      [0, 0],
      [imagem.width.toDouble(), 0],
      [0, imagem.height.toDouble()],
      [imagem.width.toDouble(), imagem.height.toDouble()],
    ];

    for (var i = 0; i < regioes.length; i++) {
      final regiao = regioes[i];
      final candidatos = _encontrarComponentes(
        imagem,
        regiao[0],
        regiao[1],
        regiao[2],
        regiao[3],
      );

      if (candidatos.isEmpty) {
        throw Exception(
          'Não foi possível localizar um dos quatro marcadores da folha. '
              'Fotografe a página inteira, incluindo os quatro cantos.',
        );
      }

      final canto = cantos[i];
      candidatos.sort((a, b) {
        final distanciaA = pow(a.x - canto[0], 2) + pow(a.y - canto[1], 2);
        final distanciaB = pow(b.x - canto[0], 2) + pow(b.y - canto[1], 2);
        return distanciaA.compareTo(distanciaB);
      });

      marcadores.add(candidatos.first);
    }

    return marcadores;
  }

  static List<_Marcador> _encontrarComponentes(
      img.Image imagem,
      int inicioX,
      int inicioY,
      int fimX,
      int fimY,
      ) {
    final largura = fimX - inicioX;
    final altura = fimY - inicioY;

    final visitados = Uint8List(largura * altura);
    final candidatos = <_Marcador>[];

    final larguraMinima = imagem.width * 0.018;
    final alturaMinima = imagem.height * 0.012;
    final larguraMaxima = imagem.width * 0.09;
    final alturaMaxima = imagem.height * 0.07;

    for (var y = inicioY; y < fimY; y++) {
      for (var x = inicioX; x < fimX; x++) {
        final indice = (y - inicioY) * largura + (x - inicioX);

        if (visitados[indice] == 1) {
          continue;
        }

        visitados[indice] = 1;

        if (!_pixelEscuro(imagem, x, y)) {
          continue;
        }

        final fila = <int>[indice];

        var menorX = x;
        var maiorX = x;
        var menorY = y;
        var maiorY = y;
        var area = 0;

        while (fila.isNotEmpty) {
          final atual = fila.removeLast();

          final atualX = inicioX + atual % largura;
          final atualY = inicioY + atual ~/ largura;

          area++;

          menorX = min(menorX, atualX);
          maiorX = max(maiorX, atualX);
          menorY = min(menorY, atualY);
          maiorY = max(maiorY, atualY);

          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) {
                continue;
              }

              final nx = atualX + dx;
              final ny = atualY + dy;

              if (nx < inicioX ||
                  ny < inicioY ||
                  nx >= fimX ||
                  ny >= fimY) {
                continue;
              }

              final novoIndice =
                  (ny - inicioY) * largura + (nx - inicioX);

              if (visitados[novoIndice] == 1) {
                continue;
              }

              visitados[novoIndice] = 1;

              if (_pixelEscuro(imagem, nx, ny)) {
                fila.add(novoIndice);
              }
            }
          }
        }

        final larguraComponente = maiorX - menorX + 1;
        final alturaComponente = maiorY - menorY + 1;

        if (larguraComponente < larguraMinima ||
            alturaComponente < alturaMinima ||
            larguraComponente > larguraMaxima ||
            alturaComponente > alturaMaxima) {
          continue;
        }

        final proporcao = larguraComponente / alturaComponente;

        if (proporcao < 0.7 || proporcao > 1.3) {
          continue;
        }

        final areaMinima =
            larguraComponente * alturaComponente * 0.55;

        if (area < areaMinima) {
          continue;
        }

        candidatos.add(
          _Marcador(
            x: (menorX + maiorX) / 2,
            y: (menorY + maiorY) / 2,
            largura: larguraComponente,
            altura: alturaComponente,
            area: area,
          ),
        );
      }
    }

    return candidatos;
  }

  static bool _pixelEscuro(img.Image imagem, int x, int y) {
    final pixel = imagem.getPixel(x, y);

    final luminosidade =
        0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

    return luminosidade < limiteEscuridao;
  }

  static List<double> _calcularHomografia(
      List<List<double>> destino,
      List<List<double>> origem,
      ) {
    final matriz = <List<double>>[];

    for (var i = 0; i < 4; i++) {
      final x = destino[i][0];
      final y = destino[i][1];
      final u = origem[i][0];
      final v = origem[i][1];

      matriz.add([
        x,
        y,
        1,
        0,
        0,
        0,
        -u * x,
        -u * y,
        u,
      ]);

      matriz.add([
        0,
        0,
        0,
        x,
        y,
        1,
        -v * x,
        -v * y,
        v,
      ]);
    }

    for (var coluna = 0; coluna < 8; coluna++) {
      var pivo = coluna;

      for (var linha = coluna + 1; linha < 8; linha++) {
        if (matriz[linha][coluna].abs() >
            matriz[pivo][coluna].abs()) {
          pivo = linha;
        }
      }

      if (matriz[pivo][coluna].abs() < 0.0000001) {
        throw Exception(
          'Não foi possível corrigir a perspectiva da folha.',
        );
      }

      final temporaria = matriz[coluna];
      matriz[coluna] = matriz[pivo];
      matriz[pivo] = temporaria;

      final divisor = matriz[coluna][coluna];

      for (var j = coluna; j <= 8; j++) {
        matriz[coluna][j] /= divisor;
      }

      for (var linha = 0; linha < 8; linha++) {
        if (linha == coluna) {
          continue;
        }

        final fator = matriz[linha][coluna];

        for (var j = coluna; j <= 8; j++) {
          matriz[linha][j] -= fator * matriz[coluna][j];
        }
      }
    }

    return List<double>.generate(
      8,
          (i) => matriz[i][8],
    );
  }
}