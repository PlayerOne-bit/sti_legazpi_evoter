import 'package:flutter/material.dart';

class Position {
  final int id;
  final String title;
  final int displayOrder;
  const Position(this.id, this.title, this.displayOrder);
}

/// Grade 7 to 12, then Tertiary Year 1 to 4. Listed in display order.
class GradeLevel {
  final int id;
  final String name;
  const GradeLevel(this.id, this.name);
}

class Student {
  final int id;
  final String studentNum;
  final String fullName;
  final int gradeLevelId;
  bool hasVoted;
  Student(this.id, this.studentNum, this.fullName, this.gradeLevelId, {this.hasVoted = false});

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
  final String audience; // which grade levels could vote
  Season(this.schoolYear, this.club, this.startDate, this.endDate, this.totalVoters, this.votedCount,
      this.winners, this.audience);

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
  Set<int> levelIds; // grade levels allowed to vote
  Election(this.id, this.schoolYear, this.club, this.startDate, this.endDate, this.levelIds);

  bool allows(Student s) => levelIds.contains(s.gradeLevelId);

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

  final List<GradeLevel> gradeLevels = const [
    GradeLevel(1, 'Grade 7'),
    GradeLevel(2, 'Grade 8'),
    GradeLevel(3, 'Grade 9'),
    GradeLevel(4, 'Grade 10'),
    GradeLevel(5, 'Grade 11'),
    GradeLevel(6, 'Grade 12'),
    GradeLevel(7, 'Tertiary Year 1'),
    GradeLevel(8, 'Tertiary Year 2'),
    GradeLevel(9, 'Tertiary Year 3'),
    GradeLevel(10, 'Tertiary Year 4'),
  ];

  final List<String> schoolYears = ['2025-2026', '2026-2027', '2027-2028'];
  final List<String> clubs = ['Student Council', 'Computer Society', 'Business Club'];

  final List<Election> elections = [
    Election(1, '2026-2027', 'Student Council', DateTime.now().subtract(const Duration(hours: 6)),
        DateTime.now().add(const Duration(days: 2, hours: 5, minutes: 30)), {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}),
    Election(2, '2026-2027', 'Computer Society', DateTime.now().add(const Duration(days: 5, hours: 3)),
        DateTime.now().add(const Duration(days: 7, hours: 3)), {7, 8, 9, 10}),
    Election(3, '2026-2027', 'Business Club', DateTime.now().add(const Duration(days: 12)),
        DateTime.now().add(const Duration(days: 14)), {5, 6, 7, 8}),
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
    Student(1, '02000123456', 'Juan Dela Cruz', 6),
    Student(2, '02000123457', 'Maria Santos', 6, hasVoted: true),
    Student(3, '02000123458', 'Carlo Bautista', 5, hasVoted: true),
    Student(4, '02000123459', 'Angelica Flores', 5),
    Student(5, '02000123460', 'Rey Navarro', 7, hasVoted: true),
    Student(6, '02000123461', 'Bea Aquino', 4),
    Student(7, '02000123462', 'Migo Castillo', 8, hasVoted: true),
    Student(8, '02000123463', 'Lorna Padilla', 3),
    Student(9, '02000123464', 'Dan Soriano', 6, hasVoted: true),
    Student(10, '02000123465', 'Faye Lim', 9),
  ];

  final Map<int, int> tally = {1: 31, 2: 24, 3: 27, 4: 28, 5: 33, 6: 22};

  final List<Season> history = [
    Season('2025-2026', 'Computer Society', DateTime(2026, 3, 2, 8), DateTime(2026, 3, 4, 17), 60, 48, const [
      SeasonWinner('President', 'Noel Tan', 'Team Byte', 31),
      SeasonWinner('Secretary', 'Kris Lopez', 'Team Byte', 27),
    ], 'Tertiary Year 1 to Tertiary Year 4'),
    Season('2025-2026', 'Student Council', DateTime(2026, 2, 10, 8), DateTime(2026, 2, 12, 17), 180, 142, const [
      SeasonWinner('President', 'Andrea Cruz', 'Team Alab', 77),
      SeasonWinner('Vice President', 'Luis Garcia', 'Bagong Sigla', 70),
      SeasonWinner('Secretary', 'Joy Mendoza', 'Team Alab', 81),
    ], 'All grade levels'),
    Season('2024-2025', 'Student Council', DateTime(2025, 2, 11, 8), DateTime(2025, 2, 13, 17), 165, 121, const [
      SeasonWinner('President', 'Rico Velasco', 'Bagong Sigla', 64),
      SeasonWinner('Vice President', 'Ana Robles', 'Bagong Sigla', 59),
    ], 'Grade 9 to Grade 12'),
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

  /// The season admin stats and the Not voted tab refer to.
  Election? get currentElection =>
      activeElection ?? (pendingTally.isNotEmpty ? pendingTally.first : null);

  /// The open season this student is allowed to vote in.
  Election? activeFor(Student? s) {
    if (s == null) return null;
    for (final e in elections) {
      if (e.status == ElectionStatus.open && e.allows(s)) return e;
    }
    return null;
  }

  /// The soonest upcoming season this student is allowed to vote in.
  Election? nextFor(Student? s) {
    if (s == null) return null;
    final list = elections
        .where((e) => e.status == ElectionStatus.upcoming && e.allows(s))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list.isEmpty ? null : list.first;
  }

  bool pendingTallyFor(Student? s) => s != null && pendingTally.any((e) => e.allows(s));

  String gradeName(int id) {
    for (final g in gradeLevels) {
      if (g.id == id) return g.name;
    }
    return 'Unknown';
  }

  /// "All grade levels", or ranges like "Grade 11 to Tertiary Year 2".
  String levelsLabel(Set<int> ids) {
    if (ids.length == gradeLevels.length) return 'All grade levels';
    final sorted = ids.toList()..sort();
    final parts = <String>[];
    int i = 0;
    while (i < sorted.length) {
      int j = i;
      while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
        j++;
      }
      parts.add(i == j ? gradeName(sorted[i]) : '${gradeName(sorted[i])} to ${gradeName(sorted[j])}');
      i = j + 1;
    }
    return parts.join(', ');
  }

  int eligibleCount(Election e) => students.where(e.allows).length;

  int votedIn(Election e) => students.where((s) => e.allows(s) && s.hasVoted).length;

  /// Re-notify listeners (used when a countdown reaches zero and a status changes).
  void touch() => notifyListeners();

  /// Creates a season (id == null) or updates one. Returns an error message, or null on success.
  String? saveElection({
    int? id,
    required String schoolYear,
    required String club,
    required DateTime start,
    required DateTime end,
    required Set<int> levels,
  }) {
    final name = club.trim();
    if (name.isEmpty) return 'Enter a club name.';
    if (levels.isEmpty) return 'Pick at least one grade level that can vote.';
    if (!end.isAfter(start)) return 'The closing time must be after the opening time.';
    final dup = elections.any((e) =>
            e.id != id && e.club.toLowerCase() == name.toLowerCase() && e.schoolYear == schoolYear) ||
        history.any((s) => s.club.toLowerCase() == name.toLowerCase() && s.schoolYear == schoolYear);
    if (dup) return '$name already has a season for $schoolYear.';
    if (id == null) {
      final nextId = elections.isEmpty ? 1 : elections.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      elections.add(Election(nextId, schoolYear, name, start, end, {...levels}));
    } else {
      final e = elections.firstWhere((x) => x.id == id);
      e.schoolYear = schoolYear;
      e.club = name;
      e.startDate = start;
      e.endDate = end;
      e.levelIds = {...levels};
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
    history.insert(
        0,
        Season(e.schoolYear, e.club, e.startDate, e.endDate, eligibleCount(e), votedIn(e), winners,
            levelsLabel(e.levelIds)));
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
  String? addStudent({required String studentNum, required String fullName, required int gradeLevelId}) {
    final num = studentNum.trim();
    final name = fullName.trim();
    if (num.isEmpty || name.isEmpty) return 'Enter the student number and full name.';
    if (students.any((s) => s.studentNum == num)) return 'A student with that number already exists.';
    final id = students.isEmpty ? 1 : students.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    students.add(Student(id, num, name, gradeLevelId));
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
