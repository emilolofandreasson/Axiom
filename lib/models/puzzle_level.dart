import 'package:flutter/foundation.dart';

@immutable
class WordPair {
  const WordPair({
    required this.id,
    required this.sourceWord,
    required this.targetWord,
  });

  final String id;
  final String sourceWord; // learner's native language
  final String targetWord; // language being learned
}

@immutable
class PuzzleLevel {
  const PuzzleLevel({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.courseLanguage,
    required this.cefrLevel,
    required this.pairs,
    this.xpReward = 20,
    this.unlocksAfter,
  });

  final String id;
  final int levelNumber;
  final String title;
  final String courseLanguage;
  final String cefrLevel;
  final List<WordPair> pairs; // exactly 6 pairs → 3×4 grid
  final int xpReward;
  final String? unlocksAfter; // id of level that must be completed first
}

// ---------------------------------------------------------------------------
// Seed data — Spanish A1/A2 vocabulary path
// ---------------------------------------------------------------------------
const kPuzzleLevels = [
  PuzzleLevel(
    id: 'es-puzzle-01',
    levelNumber: 1,
    title: 'Greetings',
    courseLanguage: 'es',
    cefrLevel: 'A1',
    xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',    targetWord: 'Hola'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',  targetWord: 'Adiós'),
      WordPair(id: 'p3', sourceWord: 'Please',   targetWord: 'Por favor'),
      WordPair(id: 'p4', sourceWord: 'Thank you', targetWord: 'Gracias'),
      WordPair(id: 'p5', sourceWord: 'Yes',      targetWord: 'Sí'),
      WordPair(id: 'p6', sourceWord: 'No',       targetWord: 'No'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-02',
    levelNumber: 2,
    title: 'Numbers',
    courseLanguage: 'es',
    cefrLevel: 'A1',
    xpReward: 20,
    unlocksAfter: 'es-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'Uno'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'Dos'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'Tres'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'Cuatro'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'Cinco'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'Seis'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-03',
    levelNumber: 3,
    title: 'Colors',
    courseLanguage: 'es',
    cefrLevel: 'A1',
    xpReward: 25,
    unlocksAfter: 'es-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Red',    targetWord: 'Rojo'),
      WordPair(id: 'p2', sourceWord: 'Blue',   targetWord: 'Azul'),
      WordPair(id: 'p3', sourceWord: 'Green',  targetWord: 'Verde'),
      WordPair(id: 'p4', sourceWord: 'Yellow', targetWord: 'Amarillo'),
      WordPair(id: 'p5', sourceWord: 'Black',  targetWord: 'Negro'),
      WordPair(id: 'p6', sourceWord: 'White',  targetWord: 'Blanco'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-04',
    levelNumber: 4,
    title: 'Animals',
    courseLanguage: 'es',
    cefrLevel: 'A1',
    xpReward: 25,
    unlocksAfter: 'es-puzzle-03',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Dog',   targetWord: 'Perro'),
      WordPair(id: 'p2', sourceWord: 'Cat',   targetWord: 'Gato'),
      WordPair(id: 'p3', sourceWord: 'Bird',  targetWord: 'Pájaro'),
      WordPair(id: 'p4', sourceWord: 'Fish',  targetWord: 'Pez'),
      WordPair(id: 'p5', sourceWord: 'Horse', targetWord: 'Caballo'),
      WordPair(id: 'p6', sourceWord: 'Cow',   targetWord: 'Vaca'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-05',
    levelNumber: 5,
    title: 'Food & Drink',
    courseLanguage: 'es',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'es-puzzle-04',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Water', targetWord: 'Agua'),
      WordPair(id: 'p2', sourceWord: 'Bread', targetWord: 'Pan'),
      WordPair(id: 'p3', sourceWord: 'Meat',  targetWord: 'Carne'),
      WordPair(id: 'p4', sourceWord: 'Fruit', targetWord: 'Fruta'),
      WordPair(id: 'p5', sourceWord: 'Milk',  targetWord: 'Leche'),
      WordPair(id: 'p6', sourceWord: 'Rice',  targetWord: 'Arroz'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// French A1 vocabulary path
// ---------------------------------------------------------------------------
const kFrenchPuzzleLevels = [
  PuzzleLevel(
    id: 'fr-puzzle-01',
    levelNumber: 1,
    title: 'Greetings',
    courseLanguage: 'fr',
    cefrLevel: 'A1',
    xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: 'Bonjour'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: 'Au revoir'),
      WordPair(id: 'p3', sourceWord: 'Please',    targetWord: 'S\'il vous plaît'),
      WordPair(id: 'p4', sourceWord: 'Thank you', targetWord: 'Merci'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: 'Oui'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: 'Non'),
    ],
  ),
  PuzzleLevel(
    id: 'fr-puzzle-02',
    levelNumber: 2,
    title: 'Numbers',
    courseLanguage: 'fr',
    cefrLevel: 'A1',
    xpReward: 20,
    unlocksAfter: 'fr-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'Un'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'Deux'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'Trois'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'Quatre'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'Cinq'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'Six'),
    ],
  ),
  PuzzleLevel(
    id: 'fr-puzzle-03',
    levelNumber: 3,
    title: 'Colors',
    courseLanguage: 'fr',
    cefrLevel: 'A1',
    xpReward: 25,
    unlocksAfter: 'fr-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Red',    targetWord: 'Rouge'),
      WordPair(id: 'p2', sourceWord: 'Blue',   targetWord: 'Bleu'),
      WordPair(id: 'p3', sourceWord: 'Green',  targetWord: 'Vert'),
      WordPair(id: 'p4', sourceWord: 'Yellow', targetWord: 'Jaune'),
      WordPair(id: 'p5', sourceWord: 'Black',  targetWord: 'Noir'),
      WordPair(id: 'p6', sourceWord: 'White',  targetWord: 'Blanc'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// German A1 vocabulary path
// ---------------------------------------------------------------------------
const kGermanPuzzleLevels = [
  PuzzleLevel(
    id: 'de-puzzle-01',
    levelNumber: 1,
    title: 'Greetings',
    courseLanguage: 'de',
    cefrLevel: 'A1',
    xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: 'Hallo'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: 'Auf Wiedersehen'),
      WordPair(id: 'p3', sourceWord: 'Please',    targetWord: 'Bitte'),
      WordPair(id: 'p4', sourceWord: 'Thank you', targetWord: 'Danke'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: 'Ja'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: 'Nein'),
    ],
  ),
  PuzzleLevel(
    id: 'de-puzzle-02',
    levelNumber: 2,
    title: 'Numbers',
    courseLanguage: 'de',
    cefrLevel: 'A1',
    xpReward: 20,
    unlocksAfter: 'de-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'Eins'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'Zwei'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'Drei'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'Vier'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'Fünf'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'Sechs'),
    ],
  ),
  PuzzleLevel(
    id: 'de-puzzle-03',
    levelNumber: 3,
    title: 'Colors',
    courseLanguage: 'de',
    cefrLevel: 'A1',
    xpReward: 25,
    unlocksAfter: 'de-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Red',    targetWord: 'Rot'),
      WordPair(id: 'p2', sourceWord: 'Blue',   targetWord: 'Blau'),
      WordPair(id: 'p3', sourceWord: 'Green',  targetWord: 'Grün'),
      WordPair(id: 'p4', sourceWord: 'Yellow', targetWord: 'Gelb'),
      WordPair(id: 'p5', sourceWord: 'Black',  targetWord: 'Schwarz'),
      WordPair(id: 'p6', sourceWord: 'White',  targetWord: 'Weiß'),
    ],
  ),
];

const kPuzzleLevelsByLanguage = <String, List<PuzzleLevel>>{
  'es': kPuzzleLevels,
  'fr': kFrenchPuzzleLevels,
  'de': kGermanPuzzleLevels,
};
