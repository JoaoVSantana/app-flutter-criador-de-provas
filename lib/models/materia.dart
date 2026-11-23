class Materia {
  final String id;
  final String nome;
  final List<String> assuntos;

  const Materia({
    required this.id,
    required this.nome,
    this.assuntos = const [],
  });

  factory Materia.fromMap(String id, Map<String, dynamic> m) {
    final assuntos = List<String>.from(m['assuntos'] ?? [])
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return Materia(id: id, nome: m['nome'] ?? '', assuntos: assuntos);
  }
}
