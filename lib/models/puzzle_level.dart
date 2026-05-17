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
  PuzzleLevel(
    id: 'es-puzzle-06',
    levelNumber: 6,
    title: 'Family',
    courseLanguage: 'es',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'es-puzzle-05',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Mother',  targetWord: 'Madre'),
      WordPair(id: 'p2', sourceWord: 'Father',  targetWord: 'Padre'),
      WordPair(id: 'p3', sourceWord: 'Brother', targetWord: 'Hermano'),
      WordPair(id: 'p4', sourceWord: 'Sister',  targetWord: 'Hermana'),
      WordPair(id: 'p5', sourceWord: 'Son',     targetWord: 'Hijo'),
      WordPair(id: 'p6', sourceWord: 'Daughter', targetWord: 'Hija'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-07',
    levelNumber: 7,
    title: 'Time & Days',
    courseLanguage: 'es',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'es-puzzle-06',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Monday',    targetWord: 'Lunes'),
      WordPair(id: 'p2', sourceWord: 'Friday',    targetWord: 'Viernes'),
      WordPair(id: 'p3', sourceWord: 'Today',     targetWord: 'Hoy'),
      WordPair(id: 'p4', sourceWord: 'Tomorrow',  targetWord: 'Mañana'),
      WordPair(id: 'p5', sourceWord: 'Morning',   targetWord: 'Mañana'),
      WordPair(id: 'p6', sourceWord: 'Evening',   targetWord: 'Tarde'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-08',
    levelNumber: 8,
    title: 'Body',
    courseLanguage: 'es',
    cefrLevel: 'A2',
    xpReward: 35,
    unlocksAfter: 'es-puzzle-07',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Head',  targetWord: 'Cabeza'),
      WordPair(id: 'p2', sourceWord: 'Hand',  targetWord: 'Mano'),
      WordPair(id: 'p3', sourceWord: 'Foot',  targetWord: 'Pie'),
      WordPair(id: 'p4', sourceWord: 'Eye',   targetWord: 'Ojo'),
      WordPair(id: 'p5', sourceWord: 'Mouth', targetWord: 'Boca'),
      WordPair(id: 'p6', sourceWord: 'Nose',  targetWord: 'Nariz'),
    ],
  ),
  // B1 levels
  PuzzleLevel(
    id: 'es-puzzle-09',
    levelNumber: 9,
    title: 'Travel',
    courseLanguage: 'es',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'es-puzzle-08',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Airport',   targetWord: 'Aeropuerto'),
      WordPair(id: 'p2', sourceWord: 'Hotel',     targetWord: 'Hotel'),
      WordPair(id: 'p3', sourceWord: 'Ticket',    targetWord: 'Billete'),
      WordPair(id: 'p4', sourceWord: 'Suitcase',  targetWord: 'Maleta'),
      WordPair(id: 'p5', sourceWord: 'Passport',  targetWord: 'Pasaporte'),
      WordPair(id: 'p6', sourceWord: 'Train',     targetWord: 'Tren'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-10',
    levelNumber: 10,
    title: 'Work & Office',
    courseLanguage: 'es',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'es-puzzle-09',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Job',      targetWord: 'Trabajo'),
      WordPair(id: 'p2', sourceWord: 'Office',   targetWord: 'Oficina'),
      WordPair(id: 'p3', sourceWord: 'Meeting',  targetWord: 'Reunión'),
      WordPair(id: 'p4', sourceWord: 'Project',  targetWord: 'Proyecto'),
      WordPair(id: 'p5', sourceWord: 'Company',  targetWord: 'Empresa'),
      WordPair(id: 'p6', sourceWord: 'Colleague', targetWord: 'Colega'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-11',
    levelNumber: 11,
    title: 'Health',
    courseLanguage: 'es',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'es-puzzle-10',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Doctor',    targetWord: 'Médico'),
      WordPair(id: 'p2', sourceWord: 'Hospital',  targetWord: 'Hospital'),
      WordPair(id: 'p3', sourceWord: 'Medicine',  targetWord: 'Medicina'),
      WordPair(id: 'p4', sourceWord: 'Pain',      targetWord: 'Dolor'),
      WordPair(id: 'p5', sourceWord: 'Appointment', targetWord: 'Cita'),
      WordPair(id: 'p6', sourceWord: 'Illness',   targetWord: 'Enfermedad'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-12',
    levelNumber: 12,
    title: 'Shopping',
    courseLanguage: 'es',
    cefrLevel: 'B1',
    xpReward: 50,
    unlocksAfter: 'es-puzzle-11',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Price',    targetWord: 'Precio'),
      WordPair(id: 'p2', sourceWord: 'Shop',     targetWord: 'Tienda'),
      WordPair(id: 'p3', sourceWord: 'To buy',   targetWord: 'Comprar'),
      WordPair(id: 'p4', sourceWord: 'To pay',   targetWord: 'Pagar'),
      WordPair(id: 'p5', sourceWord: 'Discount', targetWord: 'Descuento'),
      WordPair(id: 'p6', sourceWord: 'Receipt',  targetWord: 'Recibo'),
    ],
  ),
  // B2 levels
  PuzzleLevel(
    id: 'es-puzzle-13',
    levelNumber: 13,
    title: 'Opinion & Debate',
    courseLanguage: 'es',
    cefrLevel: 'B2',
    xpReward: 65,
    unlocksAfter: 'es-puzzle-12',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Opinion',     targetWord: 'Opinión'),
      WordPair(id: 'p2', sourceWord: 'Agreement',   targetWord: 'Acuerdo'),
      WordPair(id: 'p3', sourceWord: 'Argument',    targetWord: 'Argumento'),
      WordPair(id: 'p4', sourceWord: 'Perspective', targetWord: 'Perspectiva'),
      WordPair(id: 'p5', sourceWord: 'Debate',      targetWord: 'Debate'),
      WordPair(id: 'p6', sourceWord: 'Evidence',    targetWord: 'Evidencia'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-14',
    levelNumber: 14,
    title: 'Environment',
    courseLanguage: 'es',
    cefrLevel: 'B2',
    xpReward: 65,
    unlocksAfter: 'es-puzzle-13',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Environment',  targetWord: 'Medioambiente'),
      WordPair(id: 'p2', sourceWord: 'Pollution',     targetWord: 'Contaminación'),
      WordPair(id: 'p3', sourceWord: 'Recycling',     targetWord: 'Reciclaje'),
      WordPair(id: 'p4', sourceWord: 'Energy',        targetWord: 'Energía'),
      WordPair(id: 'p5', sourceWord: 'Climate',       targetWord: 'Clima'),
      WordPair(id: 'p6', sourceWord: 'Sustainable',   targetWord: 'Sostenible'),
    ],
  ),
  PuzzleLevel(
    id: 'es-puzzle-15',
    levelNumber: 15,
    title: 'Culture & Society',
    courseLanguage: 'es',
    cefrLevel: 'B2',
    xpReward: 70,
    unlocksAfter: 'es-puzzle-14',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Tradition',   targetWord: 'Tradición'),
      WordPair(id: 'p2', sourceWord: 'Custom',      targetWord: 'Costumbre'),
      WordPair(id: 'p3', sourceWord: 'Art',         targetWord: 'Arte'),
      WordPair(id: 'p4', sourceWord: 'Literature',  targetWord: 'Literatura'),
      WordPair(id: 'p5', sourceWord: 'History',     targetWord: 'Historia'),
      WordPair(id: 'p6', sourceWord: 'Society',     targetWord: 'Sociedad'),
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
  PuzzleLevel(
    id: 'fr-puzzle-04',
    levelNumber: 4,
    title: 'Food & Drink',
    courseLanguage: 'fr',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'fr-puzzle-03',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Water',  targetWord: 'Eau'),
      WordPair(id: 'p2', sourceWord: 'Bread',  targetWord: 'Pain'),
      WordPair(id: 'p3', sourceWord: 'Cheese', targetWord: 'Fromage'),
      WordPair(id: 'p4', sourceWord: 'Fruit',  targetWord: 'Fruit'),
      WordPair(id: 'p5', sourceWord: 'Milk',   targetWord: 'Lait'),
      WordPair(id: 'p6', sourceWord: 'Wine',   targetWord: 'Vin'),
    ],
  ),
  PuzzleLevel(
    id: 'fr-puzzle-05',
    levelNumber: 5,
    title: 'Family',
    courseLanguage: 'fr',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'fr-puzzle-04',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Mother',  targetWord: 'Mère'),
      WordPair(id: 'p2', sourceWord: 'Father',  targetWord: 'Père'),
      WordPair(id: 'p3', sourceWord: 'Brother', targetWord: 'Frère'),
      WordPair(id: 'p4', sourceWord: 'Sister',  targetWord: 'Sœur'),
      WordPair(id: 'p5', sourceWord: 'Son',     targetWord: 'Fils'),
      WordPair(id: 'p6', sourceWord: 'Daughter', targetWord: 'Fille'),
    ],
  ),
  PuzzleLevel(
    id: 'fr-puzzle-06',
    levelNumber: 6,
    title: 'Travel',
    courseLanguage: 'fr',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'fr-puzzle-05',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Airport',  targetWord: 'Aéroport'),
      WordPair(id: 'p2', sourceWord: 'Hotel',    targetWord: 'Hôtel'),
      WordPair(id: 'p3', sourceWord: 'Ticket',   targetWord: 'Billet'),
      WordPair(id: 'p4', sourceWord: 'Suitcase', targetWord: 'Valise'),
      WordPair(id: 'p5', sourceWord: 'Passport', targetWord: 'Passeport'),
      WordPair(id: 'p6', sourceWord: 'Train',    targetWord: 'Train'),
    ],
  ),
  PuzzleLevel(
    id: 'fr-puzzle-07',
    levelNumber: 7,
    title: 'Work & Office',
    courseLanguage: 'fr',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'fr-puzzle-06',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Job',      targetWord: 'Travail'),
      WordPair(id: 'p2', sourceWord: 'Office',   targetWord: 'Bureau'),
      WordPair(id: 'p3', sourceWord: 'Meeting',  targetWord: 'Réunion'),
      WordPair(id: 'p4', sourceWord: 'Project',  targetWord: 'Projet'),
      WordPair(id: 'p5', sourceWord: 'Company',  targetWord: 'Entreprise'),
      WordPair(id: 'p6', sourceWord: 'Colleague', targetWord: 'Collègue'),
    ],
  ),
  PuzzleLevel(
    id: 'fr-puzzle-08',
    levelNumber: 8,
    title: 'Opinion & Debate',
    courseLanguage: 'fr',
    cefrLevel: 'B2',
    xpReward: 65,
    unlocksAfter: 'fr-puzzle-07',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Opinion',     targetWord: 'Opinion'),
      WordPair(id: 'p2', sourceWord: 'Agreement',   targetWord: 'Accord'),
      WordPair(id: 'p3', sourceWord: 'Argument',    targetWord: 'Argument'),
      WordPair(id: 'p4', sourceWord: 'Perspective', targetWord: 'Perspective'),
      WordPair(id: 'p5', sourceWord: 'Debate',      targetWord: 'Débat'),
      WordPair(id: 'p6', sourceWord: 'Evidence',    targetWord: 'Preuve'),
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
  PuzzleLevel(
    id: 'de-puzzle-04',
    levelNumber: 4,
    title: 'Food & Drink',
    courseLanguage: 'de',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'de-puzzle-03',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Water',  targetWord: 'Wasser'),
      WordPair(id: 'p2', sourceWord: 'Bread',  targetWord: 'Brot'),
      WordPair(id: 'p3', sourceWord: 'Meat',   targetWord: 'Fleisch'),
      WordPair(id: 'p4', sourceWord: 'Fruit',  targetWord: 'Obst'),
      WordPair(id: 'p5', sourceWord: 'Milk',   targetWord: 'Milch'),
      WordPair(id: 'p6', sourceWord: 'Cheese', targetWord: 'Käse'),
    ],
  ),
  PuzzleLevel(
    id: 'de-puzzle-05',
    levelNumber: 5,
    title: 'Family',
    courseLanguage: 'de',
    cefrLevel: 'A2',
    xpReward: 30,
    unlocksAfter: 'de-puzzle-04',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Mother',  targetWord: 'Mutter'),
      WordPair(id: 'p2', sourceWord: 'Father',  targetWord: 'Vater'),
      WordPair(id: 'p3', sourceWord: 'Brother', targetWord: 'Bruder'),
      WordPair(id: 'p4', sourceWord: 'Sister',  targetWord: 'Schwester'),
      WordPair(id: 'p5', sourceWord: 'Son',     targetWord: 'Sohn'),
      WordPair(id: 'p6', sourceWord: 'Daughter', targetWord: 'Tochter'),
    ],
  ),
  PuzzleLevel(
    id: 'de-puzzle-06',
    levelNumber: 6,
    title: 'Travel',
    courseLanguage: 'de',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'de-puzzle-05',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Airport',  targetWord: 'Flughafen'),
      WordPair(id: 'p2', sourceWord: 'Hotel',    targetWord: 'Hotel'),
      WordPair(id: 'p3', sourceWord: 'Ticket',   targetWord: 'Fahrkarte'),
      WordPair(id: 'p4', sourceWord: 'Suitcase', targetWord: 'Koffer'),
      WordPair(id: 'p5', sourceWord: 'Passport', targetWord: 'Reisepass'),
      WordPair(id: 'p6', sourceWord: 'Train',    targetWord: 'Zug'),
    ],
  ),
  PuzzleLevel(
    id: 'de-puzzle-07',
    levelNumber: 7,
    title: 'Work & Office',
    courseLanguage: 'de',
    cefrLevel: 'B1',
    xpReward: 45,
    unlocksAfter: 'de-puzzle-06',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Job',      targetWord: 'Arbeit'),
      WordPair(id: 'p2', sourceWord: 'Office',   targetWord: 'Büro'),
      WordPair(id: 'p3', sourceWord: 'Meeting',  targetWord: 'Besprechung'),
      WordPair(id: 'p4', sourceWord: 'Project',  targetWord: 'Projekt'),
      WordPair(id: 'p5', sourceWord: 'Company',  targetWord: 'Unternehmen'),
      WordPair(id: 'p6', sourceWord: 'Colleague', targetWord: 'Kollege'),
    ],
  ),
  PuzzleLevel(
    id: 'de-puzzle-08',
    levelNumber: 8,
    title: 'Opinion & Debate',
    courseLanguage: 'de',
    cefrLevel: 'B2',
    xpReward: 65,
    unlocksAfter: 'de-puzzle-07',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Opinion',     targetWord: 'Meinung'),
      WordPair(id: 'p2', sourceWord: 'Agreement',   targetWord: 'Einigung'),
      WordPair(id: 'p3', sourceWord: 'Argument',    targetWord: 'Argument'),
      WordPair(id: 'p4', sourceWord: 'Perspective', targetWord: 'Perspektive'),
      WordPair(id: 'p5', sourceWord: 'Debate',      targetWord: 'Debatte'),
      WordPair(id: 'p6', sourceWord: 'Evidence',    targetWord: 'Beweis'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Italian A1/A2 vocabulary path
// ---------------------------------------------------------------------------
const kItalianPuzzleLevels = [
  PuzzleLevel(
    id: 'it-puzzle-01', levelNumber: 1, title: 'Greetings',
    courseLanguage: 'it', cefrLevel: 'A1', xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: 'Ciao'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: 'Arrivederci'),
      WordPair(id: 'p3', sourceWord: 'Please',    targetWord: 'Per favore'),
      WordPair(id: 'p4', sourceWord: 'Thank you', targetWord: 'Grazie'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: 'Sì'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: 'No'),
    ],
  ),
  PuzzleLevel(
    id: 'it-puzzle-02', levelNumber: 2, title: 'Numbers',
    courseLanguage: 'it', cefrLevel: 'A1', xpReward: 20,
    unlocksAfter: 'it-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'Uno'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'Due'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'Tre'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'Quattro'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'Cinque'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'Sei'),
    ],
  ),
  PuzzleLevel(
    id: 'it-puzzle-03', levelNumber: 3, title: 'Colors',
    courseLanguage: 'it', cefrLevel: 'A1', xpReward: 25,
    unlocksAfter: 'it-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Red',    targetWord: 'Rosso'),
      WordPair(id: 'p2', sourceWord: 'Blue',   targetWord: 'Blu'),
      WordPair(id: 'p3', sourceWord: 'Green',  targetWord: 'Verde'),
      WordPair(id: 'p4', sourceWord: 'Yellow', targetWord: 'Giallo'),
      WordPair(id: 'p5', sourceWord: 'Black',  targetWord: 'Nero'),
      WordPair(id: 'p6', sourceWord: 'White',  targetWord: 'Bianco'),
    ],
  ),
  PuzzleLevel(
    id: 'it-puzzle-04', levelNumber: 4, title: 'Food & Drink',
    courseLanguage: 'it', cefrLevel: 'A2', xpReward: 30,
    unlocksAfter: 'it-puzzle-03',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Water',  targetWord: 'Acqua'),
      WordPair(id: 'p2', sourceWord: 'Bread',  targetWord: 'Pane'),
      WordPair(id: 'p3', sourceWord: 'Cheese', targetWord: 'Formaggio'),
      WordPair(id: 'p4', sourceWord: 'Coffee', targetWord: 'Caffè'),
      WordPair(id: 'p5', sourceWord: 'Wine',   targetWord: 'Vino'),
      WordPair(id: 'p6', sourceWord: 'Pizza',  targetWord: 'Pizza'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Portuguese A1/A2 vocabulary path
// ---------------------------------------------------------------------------
const kPortuguesePuzzleLevels = [
  PuzzleLevel(
    id: 'pt-puzzle-01', levelNumber: 1, title: 'Greetings',
    courseLanguage: 'pt', cefrLevel: 'A1', xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: 'Olá'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: 'Tchau'),
      WordPair(id: 'p3', sourceWord: 'Please',    targetWord: 'Por favor'),
      WordPair(id: 'p4', sourceWord: 'Thank you', targetWord: 'Obrigado'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: 'Sim'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: 'Não'),
    ],
  ),
  PuzzleLevel(
    id: 'pt-puzzle-02', levelNumber: 2, title: 'Numbers',
    courseLanguage: 'pt', cefrLevel: 'A1', xpReward: 20,
    unlocksAfter: 'pt-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'Um'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'Dois'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'Três'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'Quatro'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'Cinco'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'Seis'),
    ],
  ),
  PuzzleLevel(
    id: 'pt-puzzle-03', levelNumber: 3, title: 'Colors',
    courseLanguage: 'pt', cefrLevel: 'A1', xpReward: 25,
    unlocksAfter: 'pt-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Red',    targetWord: 'Vermelho'),
      WordPair(id: 'p2', sourceWord: 'Blue',   targetWord: 'Azul'),
      WordPair(id: 'p3', sourceWord: 'Green',  targetWord: 'Verde'),
      WordPair(id: 'p4', sourceWord: 'Yellow', targetWord: 'Amarelo'),
      WordPair(id: 'p5', sourceWord: 'Black',  targetWord: 'Preto'),
      WordPair(id: 'p6', sourceWord: 'White',  targetWord: 'Branco'),
    ],
  ),
  PuzzleLevel(
    id: 'pt-puzzle-04', levelNumber: 4, title: 'Food & Drink',
    courseLanguage: 'pt', cefrLevel: 'A2', xpReward: 30,
    unlocksAfter: 'pt-puzzle-03',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Water',  targetWord: 'Água'),
      WordPair(id: 'p2', sourceWord: 'Bread',  targetWord: 'Pão'),
      WordPair(id: 'p3', sourceWord: 'Meat',   targetWord: 'Carne'),
      WordPair(id: 'p4', sourceWord: 'Fruit',  targetWord: 'Fruta'),
      WordPair(id: 'p5', sourceWord: 'Milk',   targetWord: 'Leite'),
      WordPair(id: 'p6', sourceWord: 'Coffee', targetWord: 'Café'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Japanese A1 vocabulary path
// ---------------------------------------------------------------------------
const kJapanesePuzzleLevels = [
  PuzzleLevel(
    id: 'ja-puzzle-01', levelNumber: 1, title: 'Greetings',
    courseLanguage: 'ja', cefrLevel: 'A1', xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',        targetWord: 'こんにちは'),
      WordPair(id: 'p2', sourceWord: 'Good morning', targetWord: 'おはよう'),
      WordPair(id: 'p3', sourceWord: 'Good evening', targetWord: 'こんばんは'),
      WordPair(id: 'p4', sourceWord: 'Thank you',    targetWord: 'ありがとう'),
      WordPair(id: 'p5', sourceWord: 'Yes',          targetWord: 'はい'),
      WordPair(id: 'p6', sourceWord: 'No',           targetWord: 'いいえ'),
    ],
  ),
  PuzzleLevel(
    id: 'ja-puzzle-02', levelNumber: 2, title: 'Numbers',
    courseLanguage: 'ja', cefrLevel: 'A1', xpReward: 20,
    unlocksAfter: 'ja-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'いち'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'に'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'さん'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'し'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'ご'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'ろく'),
    ],
  ),
  PuzzleLevel(
    id: 'ja-puzzle-03', levelNumber: 3, title: 'Food',
    courseLanguage: 'ja', cefrLevel: 'A1', xpReward: 25,
    unlocksAfter: 'ja-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Rice',   targetWord: 'ごはん'),
      WordPair(id: 'p2', sourceWord: 'Sushi',  targetWord: 'すし'),
      WordPair(id: 'p3', sourceWord: 'Water',  targetWord: 'みず'),
      WordPair(id: 'p4', sourceWord: 'Bread',  targetWord: 'パン'),
      WordPair(id: 'p5', sourceWord: 'Ramen',  targetWord: 'ラーメン'),
      WordPair(id: 'p6', sourceWord: 'Tea',    targetWord: 'おちゃ'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Korean A1 vocabulary path
// ---------------------------------------------------------------------------
const kKoreanPuzzleLevels = [
  PuzzleLevel(
    id: 'ko-puzzle-01', levelNumber: 1, title: 'Greetings',
    courseLanguage: 'ko', cefrLevel: 'A1', xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: '안녕하세요'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: '안녕히 가세요'),
      WordPair(id: 'p3', sourceWord: 'Thank you', targetWord: '감사합니다'),
      WordPair(id: 'p4', sourceWord: 'Please',    targetWord: '주세요'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: '네'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: '아니요'),
    ],
  ),
  PuzzleLevel(
    id: 'ko-puzzle-02', levelNumber: 2, title: 'Numbers',
    courseLanguage: 'ko', cefrLevel: 'A1', xpReward: 20,
    unlocksAfter: 'ko-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: '일'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: '이'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: '삼'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: '사'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: '오'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: '육'),
    ],
  ),
  PuzzleLevel(
    id: 'ko-puzzle-03', levelNumber: 3, title: 'Food',
    courseLanguage: 'ko', cefrLevel: 'A1', xpReward: 25,
    unlocksAfter: 'ko-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Rice',   targetWord: '밥'),
      WordPair(id: 'p2', sourceWord: 'Water',  targetWord: '물'),
      WordPair(id: 'p3', sourceWord: 'Kimchi', targetWord: '김치'),
      WordPair(id: 'p4', sourceWord: 'Bread',  targetWord: '빵'),
      WordPair(id: 'p5', sourceWord: 'Meat',   targetWord: '고기'),
      WordPair(id: 'p6', sourceWord: 'Fruit',  targetWord: '과일'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Mandarin Chinese A1 vocabulary path
// ---------------------------------------------------------------------------
const kMandarinPuzzleLevels = [
  PuzzleLevel(
    id: 'zh-puzzle-01', levelNumber: 1, title: 'Greetings',
    courseLanguage: 'zh', cefrLevel: 'A1', xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: '你好'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: '再见'),
      WordPair(id: 'p3', sourceWord: 'Thank you', targetWord: '谢谢'),
      WordPair(id: 'p4', sourceWord: 'Please',    targetWord: '请'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: '是'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: '不是'),
    ],
  ),
  PuzzleLevel(
    id: 'zh-puzzle-02', levelNumber: 2, title: 'Numbers',
    courseLanguage: 'zh', cefrLevel: 'A1', xpReward: 20,
    unlocksAfter: 'zh-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: '一'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: '二'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: '三'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: '四'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: '五'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: '六'),
    ],
  ),
  PuzzleLevel(
    id: 'zh-puzzle-03', levelNumber: 3, title: 'Food',
    courseLanguage: 'zh', cefrLevel: 'A1', xpReward: 25,
    unlocksAfter: 'zh-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Rice',     targetWord: '米饭'),
      WordPair(id: 'p2', sourceWord: 'Water',    targetWord: '水'),
      WordPair(id: 'p3', sourceWord: 'Noodles',  targetWord: '面条'),
      WordPair(id: 'p4', sourceWord: 'Tea',      targetWord: '茶'),
      WordPair(id: 'p5', sourceWord: 'Bread',    targetWord: '面包'),
      WordPair(id: 'p6', sourceWord: 'Dumpling', targetWord: '饺子'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Russian A1 vocabulary path
// ---------------------------------------------------------------------------
const kRussianPuzzleLevels = [
  PuzzleLevel(
    id: 'ru-puzzle-01', levelNumber: 1, title: 'Greetings',
    courseLanguage: 'ru', cefrLevel: 'A1', xpReward: 20,
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Hello',     targetWord: 'Привет'),
      WordPair(id: 'p2', sourceWord: 'Goodbye',   targetWord: 'До свидания'),
      WordPair(id: 'p3', sourceWord: 'Thank you', targetWord: 'Спасибо'),
      WordPair(id: 'p4', sourceWord: 'Please',    targetWord: 'Пожалуйста'),
      WordPair(id: 'p5', sourceWord: 'Yes',       targetWord: 'Да'),
      WordPair(id: 'p6', sourceWord: 'No',        targetWord: 'Нет'),
    ],
  ),
  PuzzleLevel(
    id: 'ru-puzzle-02', levelNumber: 2, title: 'Numbers',
    courseLanguage: 'ru', cefrLevel: 'A1', xpReward: 20,
    unlocksAfter: 'ru-puzzle-01',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'One',   targetWord: 'Один'),
      WordPair(id: 'p2', sourceWord: 'Two',   targetWord: 'Два'),
      WordPair(id: 'p3', sourceWord: 'Three', targetWord: 'Три'),
      WordPair(id: 'p4', sourceWord: 'Four',  targetWord: 'Четыре'),
      WordPair(id: 'p5', sourceWord: 'Five',  targetWord: 'Пять'),
      WordPair(id: 'p6', sourceWord: 'Six',   targetWord: 'Шесть'),
    ],
  ),
  PuzzleLevel(
    id: 'ru-puzzle-03', levelNumber: 3, title: 'Colors',
    courseLanguage: 'ru', cefrLevel: 'A1', xpReward: 25,
    unlocksAfter: 'ru-puzzle-02',
    pairs: [
      WordPair(id: 'p1', sourceWord: 'Red',    targetWord: 'Красный'),
      WordPair(id: 'p2', sourceWord: 'Blue',   targetWord: 'Синий'),
      WordPair(id: 'p3', sourceWord: 'Green',  targetWord: 'Зелёный'),
      WordPair(id: 'p4', sourceWord: 'Yellow', targetWord: 'Жёлтый'),
      WordPair(id: 'p5', sourceWord: 'Black',  targetWord: 'Чёрный'),
      WordPair(id: 'p6', sourceWord: 'White',  targetWord: 'Белый'),
    ],
  ),
];

const kPuzzleLevelsByLanguage = <String, List<PuzzleLevel>>{
  'es': kPuzzleLevels,
  'fr': kFrenchPuzzleLevels,
  'de': kGermanPuzzleLevels,
  'it': kItalianPuzzleLevels,
  'pt': kPortuguesePuzzleLevels,
  'ja': kJapanesePuzzleLevels,
  'ko': kKoreanPuzzleLevels,
  'zh': kMandarinPuzzleLevels,
  'ru': kRussianPuzzleLevels,
};
