import 'package:flutter/material.dart';
import 'api.dart';

class Position {
  final int id;
  final String title;
  final int displayOrder;
  const Position(this.id, this.title, this.displayOrder);
}

class GradeLevel {
  final int id;
  final String name;
  final bool tertiary;
  const GradeLevel(this.id, this.name, {this.tertiary = false});
}

class Program {
  final int id;
  final String code;
  final String name;
  const Program(this.id, this.code, this.name);
}

const _palette = [
  Color(0xFF0A4DA2),
  Color(0xFFB4501E),
  Color(0xFF1E8E5A),
  Color(0xFF7A3FB5),
  Color(0xFFC2185B),
  Color(0xFF00838F),
];
Color colorFor(int id) => _palette[id % _palette.length];

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  return (p.first[0] + p.last[0]).toUpperCase();
}

class Student {
  final int id;
  final String studentNum;
  final String fullName;
  final int gradeLevelId;
  final bool hasVoted;
  final bool canDelete;
  final int? programId;
  final String? programCode;
  const Student(this.id, this.studentNum, this.fullName, this.gradeLevelId,
      {this.hasVoted = false,
      this.canDelete = true,
      this.programId,
      this.programCode});
  String get initials => _initials(fullName);
}

class Candidate {
  final int id;
  final int positionId;
  final String name;
  final String partyList;
  final Color color;
  final String motto;
  final String? imageUrl;
  final String studentNum;
  const Candidate(
      this.id, this.positionId, this.name, this.partyList, this.color,
      {this.motto = '', this.imageUrl, this.studentNum = ''});
  String get initials => _initials(name);
}

class TallyEntry {
  final int candidateId;
  final String name;
  final String partyList;
  final int votes;
  const TallyEntry(this.candidateId, this.name, this.partyList, this.votes);
  String get initials => _initials(name);
  Color get color => colorFor(candidateId);
}

class PositionTally {
  final int positionId;
  final String title;
  final int total;
  final List<TallyEntry> entries;
  const PositionTally(this.positionId, this.title, this.total, this.entries);

  /// Everyone with the top vote count (a tie gives several). Empty when nobody got a vote.
  List<TallyEntry> get winners {
    var max = 0;
    for (final e in entries) {
      if (e.votes > max) max = e.votes;
    }
    return max == 0 ? [] : entries.where((e) => e.votes == max).toList();
  }
}

class SeasonWinner {
  final String position;
  final String name;
  final String partyList;
  final int votes;
  const SeasonWinner(this.position, this.name, this.partyList, this.votes);
}

/// One finished voting season (shown in History). Winners load when it is opened.
class Season {
  final int id;
  final String schoolYear;
  final String club;
  final DateTime startDate;
  final DateTime endDate;
  final int totalVoters;
  final int votedCount;
  final String audience;
  List<SeasonWinner> winners;
  Season(this.id, this.schoolYear, this.club, this.startDate, this.endDate,
      this.totalVoters, this.votedCount, this.audience,
      [List<SeasonWinner>? winners])
      : winners = winners ?? [];

  double get turnout => totalVoters == 0 ? 0 : votedCount / totalVoters;
}

enum ElectionStatus { upcoming, open, ended }

/// Admin view of a season that is not closed yet.
class Election {
  final int id;
  String schoolYear;
  String club;
  DateTime startDate;
  DateTime endDate;
  Set<int> levelIds;
  Election(this.id, this.schoolYear, this.club, this.startDate, this.endDate,
      this.levelIds);

  bool allows(Student s) => levelIds.contains(s.gradeLevelId);

  ElectionStatus get status {
    final now = Api.now; // server-corrected clock
    if (now.isBefore(startDate)) return ElectionStatus.upcoming;
    if (now.isBefore(endDate)) return ElectionStatus.open;
    return ElectionStatus.ended;
  }
}

/// Student view of a season (the server sends the audience as text).
class ClientElection {
  final int id;
  final String club;
  final String schoolYear;
  final DateTime startDate;
  final DateTime endDate;
  final String audience;
  const ClientElection(this.id, this.club, this.schoolYear, this.startDate,
      this.endDate, this.audience);
}

ClientElection? _clientElection(dynamic j) => j == null
    ? null
    : ClientElection(j['id'], j['club'], j['schoolYear'],
        parseUtc(j['startDate']), parseUtc(j['endDate']), j['audience']);

Candidate _candidate(dynamic c, {String studentNum = ''}) => Candidate(c['id'],
    c['positionId'], c['name'], c['partyList'] ?? '', colorFor(c['id']),
    motto: c['motto'] ?? '',
    imageUrl: Api.absUrl(c['imageUrl']),
    studentNum: studentNum);

List<PositionTally> _parseTally(dynamic j) => [
      for (final p in j)
        PositionTally(p['positionId'], p['position'], p['totalVotes'], [
          for (final c in p['candidates'])
            TallyEntry(c['candidateId'], c['name'], c['partyList'], c['votes']),
        ]),
    ];

class AppState extends ChangeNotifier {
  bool isAdmin = false;

  final List<GradeLevel> gradeLevels = const [
    GradeLevel(1, 'Grade 7'),
    GradeLevel(2, 'Grade 8'),
    GradeLevel(3, 'Grade 9'),
    GradeLevel(4, 'Grade 10'),
    GradeLevel(5, 'Grade 11'),
    GradeLevel(6, 'Grade 12'),
    GradeLevel(7, 'Tertiary Year 1', tertiary: true),
    GradeLevel(8, 'Tertiary Year 2', tertiary: true),
    GradeLevel(9, 'Tertiary Year 3', tertiary: true),
    GradeLevel(10, 'Tertiary Year 4', tertiary: true),
  ];
  final List<String> schoolYears = ['2025-2026', '2026-2027', '2027-2028'];
  final List<String> clubs = [
    'Student Council',
    'Computer Society',
    'Business Club'
  ];

  // ================= student side =================
  Student? me;
  bool homeLoaded = false;
  String? homeError;
  ClientElection? homeActive; // open season this student may vote in
  ClientElection?
      homeOpenForOthers; // a season is open, but not for this grade level
  ClientElection? homeNext; // next season this student may vote in
  bool homeWaiting = false; // voting ended, tally pending
  bool hasVoted = false; // in the active season
  int? ballotElectionId;
  List<Position> positions = [];
  List<Candidate> candidates = [];
  final Map<int, int> selections = {}; // positionId -> candidateId

  String get electionLabel {
    final e = homeActive;
    return e == null ? '' : '${e.club}, ${e.schoolYear}';
  }

  Future<void> loadHome() async {
    try {
      final j = await Api.get('/api/client/home');
      Api.syncFrom(j['serverTime']);
      final m = j['me'];
      me = Student(m['id'], m['studentNum'], m['fullName'], m['gradeLevelId']);
      homeActive = _clientElection(j['active']);
      homeOpenForOthers = _clientElection(j['openForOtherLevels']);
      homeNext = _clientElection(j['next']);
      homeWaiting = j['waitingForTally'] as bool;
      hasVoted = j['hasVoted'] as bool;
      final cid = j['candidatesElectionId'] as int?;
      if (cid != null) {
        await loadBallot(cid);
      } else {
        positions = [];
        candidates = [];
        ballotElectionId = null;
      }
      homeLoaded = true;
      homeError = null;
    } on ApiException catch (e) {
      homeError = e.message;
    }
    notifyListeners();
  }

  Future<void> loadBallot(int electionId) async {
    try {
      final j = await Api.get('/api/client/elections/$electionId/ballot');
      if (ballotElectionId != electionId) selections.clear();
      ballotElectionId = electionId;
      positions = [
        for (final p in j['positions'])
          Position(p['id'], p['title'], p['displayOrder'])
      ];
      candidates = [
        for (final p in j['positions'])
          for (final c in p['candidates']) _candidate(c),
      ];
    } on ApiException {
      positions = [];
      candidates = [];
      ballotElectionId = null;
    }
  }

  List<Candidate> candidatesFor(int positionId) =>
      candidates.where((c) => c.positionId == positionId).toList();

  void select(int positionId, int candidateId) {
    selections[positionId] = candidateId;
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> submitVote() async {
    final id = homeActive?.id;
    if (id == null) return 'Voting is not open right now.';
    try {
      await Api.post('/api/client/elections/$id/vote', {
        'choices': [
          for (final e in selections.entries)
            {'positionId': e.key, 'candidateId': e.value},
        ],
      });
      selections.clear();
      await loadHome();
      return null;
    } on ApiException catch (e) {
      if (e.status == 409 || e.status == 403) await loadHome();
      return e.message;
    }
  }

  Future<List<PositionTally>> fetchStudentTally() async {
    final id = homeActive?.id;
    if (id == null) throw ApiException(0, 'There is no open election.');
    return _parseTally(await Api.get('/api/client/elections/$id/tally'));
  }

  // ================= admin side =================
  bool adminLoaded = false;
  String? adminError;
  List<Election> elections = [];
  List<Season> history = [];
  List<Student> students = [];
  List<Program> programs = [];
  int dashEligible = 0;
  int dashVoted = 0;

  // candidate manager (one season at a time)
  int? adminCandElectionId;
  List<Position> adminPositions = [];
  List<Candidate> adminCandidates = [];

  Future<void> loadAdmin() async {
    try {
      final r = await Future.wait([
        Api.get('/api/admin/dashboard'),
        Api.get('/api/admin/elections'),
        Api.get('/api/admin/history'),
        Api.get('/api/admin/clubs'),
        Api.get('/api/admin/programs'),
      ]);
      final d = r[0];
      Api.syncFrom(d['serverTime']);
      dashEligible = d['eligibleCount'];
      dashVoted = d['votedCount'];
      programs = [for (final p in r[4]) Program(p['id'], p['code'], p['name'])];
      elections = [
        for (final e in r[1])
          if (e['status'] != 'closed')
            Election(
                e['id'],
                e['schoolYear'],
                e['club'],
                parseUtc(e['startDate']),
                parseUtc(e['endDate']),
                <int>{...(e['gradeLevelIds'] as List).cast<int>()}),
      ];
      history = [
        for (final h in r[2])
          Season(
              h['id'],
              h['schoolYear'],
              h['club'],
              parseUtc(h['startDate']),
              parseUtc(h['endDate']),
              h['totalVoters'],
              h['votedCount'],
              h['audience']),
      ];
      for (final c in r[3]) {
        final name = c['name'] as String;
        if (!clubs.any((x) => x.toLowerCase() == name.toLowerCase()))
          clubs.add(name);
      }
      adminLoaded = true;
      adminError = null;
    } on ApiException catch (e) {
      adminError = e.message;
    }
    notifyListeners();
  }

  /// All students, in pages of 200. hasVoted refers to the current season when there is one.
  Future<void> loadStudents() async {
    try {
      final eid = currentElection?.id;
      final all = <Student>[];
      var page = 1;
      while (true) {
        final r = await Api.get(
            '/api/admin/students?page=$page&pageSize=200${eid == null ? '' : '&electionId=$eid'}');
        final items = r['items'] as List;
        for (final s in items) {
          all.add(Student(
              s['id'], s['studentNum'], s['fullName'], s['gradeLevelId'],
              hasVoted: s['hasVoted'],
              canDelete: s['canDelete'],
              programId: s['programId'],
              programCode: s['programCode']));
        }
        if (items.isEmpty || all.length >= (r['total'] as int)) break;
        page++;
      }
      students = all;
    } on ApiException catch (e) {
      adminError = e.message;
    }
    notifyListeners();
  }

  Future<void> refreshAdmin() async {
    await loadAdmin();
    await loadStudents();
  }

  // ---- seasons ----
  Election? get activeElection {
    for (final e in elections) {
      if (e.status == ElectionStatus.open) return e;
    }
    return null;
  }

  List<Election> get pendingTally =>
      elections.where((e) => e.status == ElectionStatus.ended).toList();

  Election? get nextElection {
    final list = elections
        .where((e) => e.status == ElectionStatus.upcoming)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list.isEmpty ? null : list.first;
  }

  Election? get currentElection =>
      activeElection ?? (pendingTally.isNotEmpty ? pendingTally.first : null);

  Future<String?> saveElection({
    int? id,
    required String schoolYear,
    required String club,
    required DateTime start,
    required DateTime end,
    required Set<int> levels,
  }) async {
    final body = {
      'club': club.trim(),
      'schoolYear': schoolYear,
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
      'gradeLevelIds': levels.toList()..sort(),
    };
    try {
      if (id == null) {
        await Api.post('/api/admin/elections', body);
      } else {
        await Api.put('/api/admin/elections/$id', body);
      }
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteElection(int id) async {
    try {
      await Api.delete('/api/admin/elections/$id');
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<List<PositionTally>> fetchAdminTally(int electionId) async =>
      _parseTally(await Api.get('/api/admin/elections/$electionId/tally'));

  /// Counts the votes on the server and moves the season to History.
  Future<String?> closeSeason(Election e) async {
    try {
      await Api.post('/api/admin/elections/${e.id}/close');
      await refreshAdmin();
      return null;
    } on ApiException catch (x) {
      return x.message;
    }
  }

  Future<String?> loadSeasonWinners(Season s) async {
    try {
      final j = await Api.get('/api/admin/history/${s.id}');
      s.winners = [
        for (final w in j['winners'])
          SeasonWinner(
              w['position'], w['name'], w['partyList'], w['voteCount']),
      ];
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // ---- students ----
  Future<String?> addStudent({
    required String studentNum,
    required String fullName,
    required int gradeLevelId,
    required String password,
    int? programId,
  }) async {
    try {
      await Api.post('/api/admin/students', {
        'studentNum': studentNum.trim(),
        'fullName': fullName.trim(),
        'gradeLevelId': gradeLevelId,
        'password': password,
        'programId': programId,
      });
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteStudent(int id) async {
    try {
      await Api.delete('/api/admin/students/$id');
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // ---- candidates (admin) ----
  Future<void> loadAdminCandidates(int electionId) async {
    adminCandElectionId =
        electionId; // set first so the screen does not retry in a loop
    try {
      final p = await Api.get('/api/admin/elections/$electionId/positions');
      final c = await Api.get('/api/admin/elections/$electionId/candidates');
      adminPositions = [
        for (final x in p) Position(x['id'], x['title'], x['displayOrder'])
      ];
      adminCandidates = [
        for (final x in c) _candidate(x, studentNum: x['studentNum'])
      ];
    } on ApiException {
      adminPositions = [];
      adminCandidates = [];
    }
    notifyListeners();
  }

  Future<String?> addCandidate({
    required int electionId,
    required String studentNum,
    required int positionId,
    required String partyList,
    required String motto,
  }) async {
    final num = studentNum.trim();
    if (num.isEmpty) return 'Enter the student number.';
    try {
      final r = await Api.get(
          '/api/admin/students?search=${Uri.encodeQueryComponent(num)}&pageSize=20');
      final match =
          (r['items'] as List).where((s) => s['studentNum'] == num).toList();
      if (match.isEmpty)
        return 'No student has the number $num. Add the student first.';
      await Api.post('/api/admin/elections/$electionId/candidates', {
        'studentId': match.first['id'],
        'positionId': positionId,
        'partyList': partyList.trim(),
        'motto': motto.trim(),
      });
      await loadAdminCandidates(electionId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> removeCandidate(int id, int electionId) async {
    try {
      await Api.delete('/api/admin/candidates/$id');
      await loadAdminCandidates(electionId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // ================= shared =================
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
      parts.add(i == j
          ? gradeName(sorted[i])
          : '${gradeName(sorted[i])} to ${gradeName(sorted[j])}');
      i = j + 1;
    }
    return parts.join(', ');
  }

  void touch() => notifyListeners();

  /// Called when a countdown hits zero: ask the server what changed.
  void refreshSoon() => Future.delayed(const Duration(seconds: 1), () {
        if (Api.token == null) return;
        if (isAdmin) {
          refreshAdmin();
        } else {
          loadHome();
        }
      });

  void logout() {
    Api.logout();
    isAdmin = false;
    me = null;
    homeLoaded = false;
    homeError = null;
    homeActive = homeOpenForOthers = homeNext = null;
    homeWaiting = hasVoted = false;
    ballotElectionId = null;
    positions = [];
    candidates = [];
    selections.clear();
    adminLoaded = false;
    adminError = null;
    elections = [];
    history = [];
    students = [];
    dashEligible = dashVoted = 0;
    adminCandElectionId = null;
    adminPositions = [];
    adminCandidates = [];
  }
}

final state = AppState();
