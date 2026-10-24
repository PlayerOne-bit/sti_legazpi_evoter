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
    final p = fullName.trim().split(RegExp(r'\s+'));
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
    final p = name.trim().split(RegExp(r'\s+'));
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

enum ElectionStatus { upcoming, open, ended }

/// A scheduled or running voting season. Admins can create as many as they need.
class Election {
  final int id;
  String schoolYear;
  String club;
  DateTime startDate;
  DateTime endDate;
  Election(this.id, this.schoolYear, this.club, this.startDate, this.endDate);

  ElectionStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return ElectionStatus.upcoming;
    if (now.isBefore(endDate)) return ElectionStatus.open;
    return ElectionStatus.ended;
  }
}

class AppState extends ChangeNotifier {
  /// The signed-in student in this prototype.
  static const meId = 1;

  bool isAdmin = false;
  bool hasVoted = false;
  final Map<int, int> selections = {}; // positionId -> candidateId

  final List<String> schoolYears = ['2025-2026', '2026-2027', '2027-2028'];
  final List<String> clubs = ['Student Council', 'Computer Society', 'Business Club'];

  final List<Election> elections = [
    Election(1, '2026-2027', 'Student Council', DateTime.now().subtract(const Duration(hours: 6)),
        DateTime.now().add(const Duration(days: 2, hours: 5, minutes: 30))),
    Election(2, '2026-2027', 'Computer Society', DateTime.now().add(const Duration(days: 5, hours: 3)),
        DateTime.now().add(const Duration(days: 7, hours: 3))),
    Election(3, '2026-2027', 'Business Club', DateTime.now().add(const Duration(days: 12)),
        DateTime.now().add(const Duration(days: 14))),
  ];

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

  // ---------- seasons ----------

  /// The season voters can vote in right now.
  Election? get activeElection {
    for (final e in elections) {
      if (e.status == ElectionStatus.open) return e;
    }
    return null;
  }

  /// Seasons whose voting time is over but have not been tallied and closed yet.
  List<Election> get pendingTally =>
      elections.where((e) => e.status == ElectionStatus.ended).toList();

  /// The soonest season that has not started yet.
  Election? get nextElection {
    final list = elections.where((e) => e.status == ElectionStatus.upcoming).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list.isEmpty ? null : list.first;
  }

  Election? get focusElection =>
      activeElection ?? (pendingTally.isNotEmpty ? pendingTally.first : nextElection);

  String get electionLabel {
    final e = focusElection;
    return e == null ? '' : '${e.club}, ${e.schoolYear}';
  }

  /// Re-notify listeners (used when a countdown reaches zero and a status changes).
  void touch() => notifyListeners();

  /// Creates a season (id == null) or updates one. Returns an error message, or null on success.
  String? saveElection({
    int? id,
    required String schoolYear,
    required String club,
    required DateTime start,
    required DateTime end,
  }) {
    final name = club.trim();
    if (name.isEmpty) return 'Enter a club name.';
    if (!end.isAfter(start)) return 'The closing time must be after the opening time.';
    final dup = elections.any((e) =>
            e.id != id && e.club.toLowerCase() == name.toLowerCase() && e.schoolYear == schoolYear) ||
        history.any((s) => s.club.toLowerCase() == name.toLowerCase() && s.schoolYear == schoolYear);
    if (dup) return '$name already has a season for $schoolYear.';
    if (id == null) {
      final nextId = elections.isEmpty ? 1 : elections.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      elections.add(Election(nextId, schoolYear, name, start, end));
    } else {
      final e = elections.firstWhere((x) => x.id == id);
      e.schoolYear = schoolYear;
      e.club = name;
      e.startDate = start;
      e.endDate = end;
    }
    if (!clubs.any((c) => c.toLowerCase() == name.toLowerCase())) clubs.add(name);
    notifyListeners();
    return null;
  }

  /// Only seasons that have not started can be deleted.
  String? deleteElection(int id) {
    final e = elections.firstWhere((x) => x.id == id);
    if (e.status != ElectionStatus.upcoming) return 'Only upcoming seasons can be deleted.';
    elections.remove(e);
    notifyListeners();
    return null;
  }

  /// Saves the season's winners to history, removes it, and clears the ballot box for the next season.
  void closeSeason(Election e) {
    final winners = <SeasonWinner>[];
    for (final p in positions) {
      if (candidatesFor(p.id).isEmpty) continue;
      final w = winnerFor(p.id);
      winners.add(SeasonWinner(p.title, w.name, w.partyList, votesFor(w.id)));
    }
    history.insert(0, Season(e.schoolYear, e.club, e.startDate, e.endDate, students.length, votedCount, winners));
    elections.removeWhere((x) => x.id == e.id);
    tally.clear();
    selections.clear();
    hasVoted = false;
    for (final s in students) {
      s.hasVoted = false;
    }
    notifyListeners();
  }

  // ---------- students ----------

  Student? get me {
    for (final s in students) {
      if (s.id == meId) return s;
    }
    return null;
  }

  int get votedCount => students.where((s) => s.hasVoted).length;

  /// Returns an error message, or null on success.
  String? addStudent({required String studentNum, required String fullName, required int gradeLevel}) {
    final num = studentNum.trim();
    final name = fullName.trim();
    if (num.isEmpty || name.isEmpty) return 'Enter the student number and full name.';
    if (students.any((s) => s.studentNum == num)) return 'A student with that number already exists.';
    final id = students.isEmpty ? 1 : students.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    students.add(Student(id, num, name, gradeLevel));
    notifyListeners();
    return null;
  }

  /// Students who already voted cannot be deleted. Returns an error message, or null on success.
  String? deleteStudent(int id) {
    final s = students.firstWhere((x) => x.id == id);
    if (s.hasVoted) return 'Students who already voted cannot be deleted.';
    students.remove(s);
    notifyListeners();
    return null;
  }

  // ---------- candidates and voting ----------

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

  void select(int positionId, int candidateId) {
    selections[positionId] = candidateId;
    notifyListeners();
  }

  void submitVote() {
    for (final cid in selections.values) {
      tally[cid] = votesFor(cid) + 1;
    }
    hasVoted = true;
    me?.hasVoted = true;
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
}

final state = AppState();
