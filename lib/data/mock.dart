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
  final String motto;
  final String? imageUrl; // later: photo URL from the backend
  const Candidate(this.id, this.positionId, this.name, this.partyList, this.vision, this.color,
      {this.motto = '', this.imageUrl});

  String get initials {
    final p = name.split(' ');
    return (p.first[0] + p.last[0]).toUpperCase();
  }
}

class SeasonWinner {
  final String position;
  final String name;
  final String partyList;
  final int votes;
  const SeasonWinner(this.position, this.name, this.partyList, this.votes);
}

/// One finished voting season (an Election that has been closed).
class Season {
  final String schoolYear;
  final String club;
  final DateTime startDate;
  final DateTime endDate;
  final int totalVoters;
  final int votedCount;
  final List<SeasonWinner> winners;
  Season(this.schoolYear, this.club, this.startDate, this.endDate, this.totalVoters, this.votedCount, this.winners);

  double get turnout => totalVoters == 0 ? 0 : votedCount / totalVoters;
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
        'Free printing hours at the library, a student-run lost and found, and monthly open forums with the administration.', Color(0xFF0A4DA2), motto: 'Your voice, our campus.'),
    const Candidate(2, 1, 'Jericho Ramos', 'Bagong Sigla',
        'Move club fairs to Fridays, expand the tutoring program, and publish the council budget every term.', Color(0xFFB4501E), motto: 'Open books, open doors.'),
    const Candidate(3, 2, 'Aira Villanueva', 'Team Alab',
        'A mentorship pairing between senior and first-year students, plus a council hotline for concerns.', Color(0xFF1E8E5A), motto: 'No one walks alone.'),
    const Candidate(4, 2, 'Paolo Mercado', 'Bagong Sigla',
        'Sports and esports leagues for every department, with equipment sign-out at the council office.', Color(0xFF7A3FB5), motto: 'Every department plays.'),
    const Candidate(5, 3, 'Trisha Reyes', 'Team Alab',
        'Meeting minutes posted within 24 hours and a single calendar for every student event.', Color(0xFFC2185B), motto: 'Clear records, clear minds.'),
    const Candidate(6, 3, 'Kenji Santos', 'Bagong Sigla',
        'A digital suggestion box answered weekly and a clear record of every approved proposal.', Color(0xFF00838F), motto: 'Every idea gets an answer.'),
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

  final List<Season> history = [
    Season('2025-2026', 'Computer Society', DateTime(2026, 3, 2, 8), DateTime(2026, 3, 4, 17), 60, 48, const [
      SeasonWinner('President', 'Noel Tan', 'Team Byte', 31),
      SeasonWinner('Secretary', 'Kris Lopez', 'Team Byte', 27),
    ]),
    Season('2025-2026', 'Student Council', DateTime(2026, 2, 10, 8), DateTime(2026, 2, 12, 17), 180, 142, const [
      SeasonWinner('President', 'Andrea Cruz', 'Team Alab', 77),
      SeasonWinner('Vice President', 'Luis Garcia', 'Bagong Sigla', 70),
      SeasonWinner('Secretary', 'Joy Mendoza', 'Team Alab', 81),
    ]),
    Season('2024-2025', 'Student Council', DateTime(2025, 2, 11, 8), DateTime(2025, 2, 13, 17), 165, 121, const [
      SeasonWinner('President', 'Rico Velasco', 'Bagong Sigla', 64),
      SeasonWinner('Vice President', 'Ana Robles', 'Bagong Sigla', 59),
    ]),
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
    String motto = '',
  }) {
    const palette = [Color(0xFF0A4DA2), Color(0xFFB4501E), Color(0xFF1E8E5A), Color(0xFF7A3FB5), Color(0xFFC2185B), Color(0xFF00838F)];
    final id = candidates.isEmpty ? 1 : candidates.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    candidates.add(Candidate(id, positionId, name, partyList, vision, palette[id % palette.length], motto: motto));
    notifyListeners();
  }

  void removeCandidate(int id) {
    candidates.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Closes the current election and stores it as a finished season.
  void saveToHistory() {
    final winners = <SeasonWinner>[];
    for (final p in positions) {
      if (candidatesFor(p.id).isEmpty) continue;
      final w = winnerFor(p.id);
      winners.add(SeasonWinner(p.title, w.name, w.partyList, votesFor(w.id)));
    }
    history.insert(0, Season(schoolYear, club, startDate, endDate, students.length, votedCount, winners));
    notifyListeners();
  }
}

final state = AppState();
