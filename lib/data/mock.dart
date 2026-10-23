import 'package:flutter/material.dart';

class Position {
  final int id;
  final String title;
  final int displayOrder;
  const Position(this.id, this.title, this.displayOrder);
}

class Student {
  final int id;
  final String studentNum;
  final String fullName;
  final int gradeLevel;
  bool hasVoted;
  Student(this.id, this.studentNum, this.fullName, this.gradeLevel, {this.hasVoted = false});

  String get initials {
    final p = fullName.split(' ');
    return (p.first[0] + p.last[0]).toUpperCase();
  }
}

class Candidate {
  final int id;
  final int positionId;
  final String name;
  final String partyList;
  final String vision;
  final Color color;
  const Candidate(this.id, this.positionId, this.name, this.partyList, this.vision, this.color);

  String get initials {
    final p = name.split(' ');
    return (p.first[0] + p.last[0]).toUpperCase();
  }
}

class HistoryEntry {
  final String schoolYear;
  final String club;
  final String position;
  final String winner;
  final int voteCount;
  const HistoryEntry(this.schoolYear, this.club, this.position, this.winner, this.voteCount);
}

class AppState extends ChangeNotifier {
  bool isAdmin = false;
  bool hasVoted = false;
  String schoolYear = '2026-2027';
  String club = 'Student Council';
  DateTime startDate = DateTime.now().subtract(const Duration(hours: 6));
  DateTime endDate = DateTime.now().add(const Duration(days: 2, hours: 5, minutes: 30));
  final Map<int, int> selections = {}; // positionId -> candidateId

  final List<String> schoolYears = ['2025-2026', '2026-2027', '2027-2028'];
  final List<String> clubs = ['Student Council', 'Computer Society', 'Business Club'];

  final List<Position> positions = const [
    Position(1, 'President', 1),
    Position(2, 'Vice President', 2),
    Position(3, 'Secretary', 3),
  ];

  final List<Candidate> candidates = [
    const Candidate(1, 1, 'Mika Dela Cruz', 'Team Alab',
        'Free printing hours at the library, a student-run lost and found, and monthly open forums with the administration.', Color(0xFF0A4DA2)),
    const Candidate(2, 1, 'Jericho Ramos', 'Bagong Sigla',
        'Move club fairs to Fridays, expand the tutoring program, and publish the council budget every term.', Color(0xFFB4501E)),
    const Candidate(3, 2, 'Aira Villanueva', 'Team Alab',
        'A mentorship pairing between senior and first-year students, plus a council hotline for concerns.', Color(0xFF1E8E5A)),
    const Candidate(4, 2, 'Paolo Mercado', 'Bagong Sigla',
        'Sports and esports leagues for every department, with equipment sign-out at the council office.', Color(0xFF7A3FB5)),
    const Candidate(5, 3, 'Trisha Reyes', 'Team Alab',
        'Meeting minutes posted within 24 hours and a single calendar for every student event.', Color(0xFFC2185B)),
    const Candidate(6, 3, 'Kenji Santos', 'Bagong Sigla',
        'A digital suggestion box answered weekly and a clear record of every approved proposal.', Color(0xFF00838F)),
  ];

  final List<Student> students = [
    Student(1, '02000123456', 'Juan Dela Cruz', 12),
    Student(2, '02000123457', 'Maria Santos', 12, hasVoted: true),
    Student(3, '02000123458', 'Carlo Bautista', 11, hasVoted: true),
    Student(4, '02000123459', 'Angelica Flores', 11),
    Student(5, '02000123460', 'Rey Navarro', 12, hasVoted: true),
    Student(6, '02000123461', 'Bea Aquino', 11),
    Student(7, '02000123462', 'Migo Castillo', 12, hasVoted: true),
    Student(8, '02000123463', 'Lorna Padilla', 11),
    Student(9, '02000123464', 'Dan Soriano', 12, hasVoted: true),
    Student(10, '02000123465', 'Faye Lim', 11),
  ];

  final Map<int, int> tally = {1: 31, 2: 24, 3: 27, 4: 28, 5: 33, 6: 22};

  final List<HistoryEntry> history = [
    const HistoryEntry('2025-2026', 'Student Council', 'President', 'Andrea Cruz', 142),
    const HistoryEntry('2025-2026', 'Student Council', 'Vice President', 'Luis Garcia', 128),
    const HistoryEntry('2025-2026', 'Computer Society', 'President', 'Noel Tan', 63),
  ];

  Duration get remaining => endDate.difference(DateTime.now());

  List<Candidate> candidatesFor(int positionId) =>
      candidates.where((c) => c.positionId == positionId).toList();

  int votesFor(int candidateId) => tally[candidateId] ?? 0;

  int totalFor(int positionId) =>
      candidatesFor(positionId).fold(0, (s, c) => s + votesFor(c.id));

  Candidate winnerFor(int positionId) {
    final list = candidatesFor(positionId)
      ..sort((a, b) => votesFor(b.id).compareTo(votesFor(a.id)));
    return list.first;
  }

  int get votedCount => students.where((s) => s.hasVoted).length;

  void select(int positionId, int candidateId) {
    selections[positionId] = candidateId;
    notifyListeners();
  }

  void submitVote() {
    for (final cid in selections.values) {
      tally[cid] = votesFor(cid) + 1;
    }
    hasVoted = true;
    students.first.hasVoted = true;
    notifyListeners();
  }

  void setSchedule({DateTime? start, DateTime? end}) {
    if (start != null) startDate = start;
    if (end != null) endDate = end;
    notifyListeners();
  }

  void setElection({String? year, String? clubName}) {
    if (year != null) schoolYear = year;
    if (clubName != null) club = clubName;
    notifyListeners();
  }

  void addCandidate({
    required int positionId,
    required String name,
    required String partyList,
    required String vision,
  }) {
    const palette = [Color(0xFF0A4DA2), Color(0xFFB4501E), Color(0xFF1E8E5A), Color(0xFF7A3FB5), Color(0xFFC2185B), Color(0xFF00838F)];
    final id = candidates.isEmpty ? 1 : candidates.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    candidates.add(Candidate(id, positionId, name, partyList, vision, palette[id % palette.length]));
    notifyListeners();
  }

  void removeCandidate(int id) {
    candidates.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void saveToHistory() {
    for (final p in positions) {
      if (candidatesFor(p.id).isEmpty) continue;
      final w = winnerFor(p.id);
      history.insert(0, HistoryEntry(schoolYear, club, p.title, w.name, votesFor(w.id)));
    }
    notifyListeners();
  }
}

final state = AppState();
