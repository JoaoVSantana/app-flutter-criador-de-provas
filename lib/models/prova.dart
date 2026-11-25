import 'package:cloud_firestore/cloud_firestore.dart';

class Prova {
  final String id;
  final String titulo;
  final String disciplina;
  final List<String> turmasIds;
  final List<String> turmasNomes;
  final List<String> questoesIds;
  final String professorId;
  final DateTime? criadoEm;

  const Prova({
    required this.id,
    required this.titulo,
    required this.disciplina,
    this.turmasIds = const [],
    this.turmasNomes = const [],
    this.questoesIds = const [],
    this.professorId = '',
    this.criadoEm,
  });

  factory Prova.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final ts = data['criadoEm'] as Timestamp?;
    return Prova(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      disciplina: data['disciplina'] ?? '',
      turmasIds: List<String>.from(data['turmasIds'] ?? const []),
      turmasNomes: List<String>.from(data['turmasNomes'] ?? const []),
      questoesIds: List<String>.from(data['questoesIds'] ?? const []),
      professorId: data['professorId'] ?? '',
      criadoEm: ts?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'disciplina': disciplina,
      'turmasIds': turmasIds,
      'turmasNomes': turmasNomes,
      'questoesIds': questoesIds,
      'professorId': professorId,
    };
  }

  Prova copyWith({
    String? id,
    String? titulo,
    String? disciplina,
    List<String>? turmasIds,
    List<String>? turmasNomes,
    List<String>? questoesIds,
    String? professorId,
    DateTime? criadoEm,
  }) {
    return Prova(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      disciplina: disciplina ?? this.disciplina,
      turmasIds: turmasIds ?? this.turmasIds,
      turmasNomes: turmasNomes ?? this.turmasNomes,
      questoesIds: questoesIds ?? this.questoesIds,
      professorId: professorId ?? this.professorId,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}