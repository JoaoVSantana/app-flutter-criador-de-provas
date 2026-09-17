import 'package:flutter/material.dart';

/// Paleta reaproveitada das telas que já existem (Header, BlocoNav, Navegar),
/// concentrada aqui para manter o visual minimalista e consistente.
class CoresRel {
  static const Color verde = Color(0xFF4C6B5E);
  static const Color verdeEscuro = Color.fromARGB(255, 58, 95, 73);
  static const Color verdeClaro = Color.fromARGB(255, 214, 224, 211);
  static const Color fundo = Color.fromARGB(255, 245, 247, 245);
  static const Color cartao = Colors.white;
  static const Color texto = Color.fromARGB(255, 47, 51, 49);
  static const Color textoSuave = Color.fromARGB(255, 110, 122, 116);
  static const Color borda = Color.fromARGB(255, 223, 229, 225);

  static const Color bom = Color(0xFF3E8E5A);
  static const Color medio = Color(0xFFCB8A2E);
  static const Color ruim = Color(0xFFC0503F);
}

/// Cor conforme o aproveitamento (0.0 a 1.0).
Color corPorAproveitamento(double percentual) {
  if (percentual >= 0.75) return CoresRel.bom;
  if (percentual >= 0.45) return CoresRel.medio;
  return CoresRel.ruim;
}

/// Cor conforme a nota (0 a 10).
Color corPorNota(double nota) => corPorAproveitamento(nota / 10);

String formatarNota(double nota) => nota.toStringAsFixed(1).replaceAll('.', ',');

String formatarPercentual(double valor) =>
    '${(valor * 100).round()}%';

/// Estilos de texto padrão das telas de relatório.
const TextStyle tituloTelaStyle = TextStyle(
  fontSize: 20,
  fontFamily: 'Oswald',
  fontWeight: FontWeight.w600,
  color: CoresRel.verdeEscuro,
);

const TextStyle subtituloStyle = TextStyle(
  fontSize: 13,
  fontFamily: 'Poppins',
  color: CoresRel.textoSuave,
);

const TextStyle rotuloStyle = TextStyle(
  fontSize: 12,
  color: CoresRel.textoSuave,
);
