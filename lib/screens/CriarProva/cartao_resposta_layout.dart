class CartaoRespostaLayout {
  static const double pageWidth = 595.28;
  static const double pageHeight = 841.89;

  static const double markerSize = 18;
  static const double markerMargin = 22;

  static const double contentLeft = 55;
  static const double contentTop = 55;

  static const double questionTop = 164;
  static const double rowHeight = 16.5;
  static const int maxQuestions = 30;
  static const int maxAlternatives = 5;

  static const double questionNumberWidth = 42;
  static const double bubbleStartX = 110;
  static const double bubbleGap = 34;
  static const double bubbleSize = 18;

  static double bubbleX(int alternativa) {
    return bubbleStartX + alternativa * bubbleGap;
  }

  static double bubbleY(int questao) {
    return questionTop +
        questao * rowHeight +
        (rowHeight - bubbleSize) / 2;
  }

  static double bubbleCenterX(int alternativa) {
    return bubbleX(alternativa) + bubbleSize / 2;
  }

  static double bubbleCenterY(int questao) {
    return bubbleY(questao) + bubbleSize / 2;
  }

  static void validarQuantidade(int questoes, int alternativas) {
    if (questoes > maxQuestions) {
      throw ArgumentError(
        'O cartão-resposta suporta no máximo $maxQuestions questões.',
      );
    }

    if (alternativas > maxAlternatives) {
      throw ArgumentError(
        'O cartão-resposta suporta no máximo $maxAlternatives alternativas.',
      );
    }
  }
}
