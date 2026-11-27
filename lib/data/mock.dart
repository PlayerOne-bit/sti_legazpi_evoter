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

String personName(String raw) {
  final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  final comma = text.indexOf(',');
  if (comma >= 0) {
    final last = text.substring(0, comma).trim();
    final rest = text.substring(comma + 1).replaceAll(',', ' ').trim();
    return rest.isEmpty ? last : '$last, $rest';
  }
  final words = text.split(' ');
  if (words.length < 2) return text;
  return '${words.last}, ${words.sublist(0, words.length - 1).join(' ')}';
}

String personInitials(String raw) {
  final name = personName(raw);
  if (name.isEmpty) return '?';
  final comma = name.indexOf(',');
  if (comma < 0) return name[0].toUpperCase();
  final last = name.substring(0, comma).trim();
  final given = name.substring(comma + 1).trim();
  final first = given.isEmpty ? '' : given[0];
  return (first + (last.isEmpty ? '' : last[0])).toUpperCase();
}

int byName(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

const independent = 'Independent';

bool isIndependent(String party) {
  final t = party.trim().toLowerCase();
  return t.isEmpty || t == 'independent';
}

String partyLabel(String? party) =>
    party == null || isIndependent(party) ? independent : party.trim();

class Student {
  final int id;
  final String studentNum;
  final String fullName;
  final int gradeLevelId;
  final bool hasVoted;
  final bool canDelete;
  final int? programId;
  final String? programCode;
  final bool isActive;
  final String schoolYear;
  final String section;
  const Student(this.id, this.studentNum, this.fullName, this.gradeLevelId,
      {this.hasVoted = false,
      this.canDelete = true,
      this.programId,
      this.programCode,
      this.isActive = true,
      this.schoolYear = '',
      this.section = ''});
  String get initials => personInitials(fullName);
}

class SeasonVoter {
  final int studentId;
  final String studentNum;
  final String fullName;
  final int gradeLevelId;
  final String gradeLevel;
  final String? programCode;
  final String section;
  final bool isActive;
  final String? password;
  final bool hasVoted;
  final DateTime? votedAt;
  final String? email;
  final DateTime? passwordSentAt;
  const SeasonVoter(
      this.studentId,
      this.studentNum,
      this.fullName,
      this.gradeLevelId,
      this.gradeLevel,
      this.programCode,
      this.section,
      this.isActive,
      this.password,
      this.hasVoted,
      this.votedAt,
      [this.email,
      this.passwordSentAt]);
  String get initials => personInitials(fullName);
}

class SeasonVoters {
  final String status;
  final int total;
  final int voted;
  final List<SeasonVoter> items;
  final bool emailReady;
  const SeasonVoters(this.status, this.total, this.voted, this.items,
      [this.emailReady = false]);
  bool get closed => status == 'closed';
}

class MailJob {
  final bool running;
  final int total;
  final int sent;
  final int failed;
  final int skipped;
  final DateTime? finishedAt;
  final String? lastError;
  final DateTime? nextAvailableAt;
  const MailJob(this.running, this.total, this.sent, this.failed, this.skipped,
      this.finishedAt, this.lastError, this.nextAvailableAt);
  int get done => sent + failed + skipped;
  factory MailJob.fromJson(Map<String, dynamic> j) => MailJob(
        j['running'] == true,
        j['total'] ?? 0,
        j['sent'] ?? 0,
        j['failed'] ?? 0,
        j['skipped'] ?? 0,
        j['finishedAt'] == null ? null : parseUtc(j['finishedAt']),
        j['lastError'],
        j['nextAvailableAt'] == null ? null : parseUtc(j['nextAvailableAt']),
      );
}

String currentSchoolYear([DateTime? now]) {
  final local =
      (now ?? DateTime.now().toUtc()).toUtc().add(const Duration(hours: 8));
  final start = local.month >= 6 ? local.year : local.year - 1;
  return '$start-${start + 1}';
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
  String get initials => personInitials(name);
}

class TallyEntry {
  final int candidateId;
  final String name;
  final String partyList;
  final int votes;
  const TallyEntry(this.candidateId, this.name, this.partyList, this.votes);
  String get initials => personInitials(name);
  Color get color => colorFor(candidateId);
}

class PositionTally {
  final int positionId;
  final String title;
  final int total;
  final List<TallyEntry> entries;
  const PositionTally(this.positionId, this.title, this.total, this.entries);

  List<TallyEntry> get winners {
    var max = 0;
    for (final e in entries) {
      if (e.votes > max) max = e.votes;
    }
    return max == 0 ? [] : entries.where((e) => e.votes == max).toList();
  }
}

class Club {
  final int id;
  final String name;
  const Club(this.id, this.name);
}

class PartyList {
  final int id;
  final String name;
  final String? logoUrl;
  final String? color;
  const PartyList(this.id, this.name, this.logoUrl, [this.color]);
  String get initials => _initials(name);
}

class PartyMember {
  final int candidateId;
  final String name;
  final String studentNum;
  final String position;
  final int positionOrder;
  final String? imageUrl;
  final String gradeLevel;
  final String section;
  const PartyMember(this.candidateId, this.name, this.studentNum, this.position,
      this.positionOrder, this.imageUrl, this.gradeLevel, this.section);
  String get initials => personInitials(name);
}

class PartyGroup {
  final int? id;
  final String name;
  final String? logoUrl;
  final String? color;
  final List<PartyMember> members;
  const PartyGroup(this.id, this.name, this.logoUrl, this.color, this.members);
  String get initials => _initials(name);
}

class SeasonWinner {
  final String position;
  final String name;
  final String partyList;
  final int votes;
  const SeasonWinner(this.position, this.name, this.partyList, this.votes);
}

class Season {
  final int id;
  final int electionId;
  final String schoolYear;
  final String club;
  final DateTime startDate;
  final DateTime endDate;
  final int totalVoters;
  final int votedCount;
  final String audience;
  List<SeasonWinner> winners;
  Season(this.id, this.electionId, this.schoolYear, this.club, this.startDate,
      this.endDate, this.totalVoters, this.votedCount, this.audience,
      [List<SeasonWinner>? winners])
      : winners = winners ?? [];

  double get turnout => totalVoters == 0 ? 0 : votedCount / totalVoters;
}

enum ElectionStatus { upcoming, open, ended }

class Election {
  final int id;
  String schoolYear;
  String club;
  DateTime startDate;
  DateTime endDate;
  Set<int> levelIds;
  int positionCount;
  int candidateCount;
  int eligibleCount;
  int votedCount;
  Election(this.id, this.schoolYear, this.club, this.startDate, this.endDate,
      this.levelIds,
      {this.positionCount = 0,
      this.candidateCount = 0,
      this.eligibleCount = 0,
      this.votedCount = 0});

  bool allows(Student s) => levelIds.contains(s.gradeLevelId);

  ElectionStatus get status {
    final now = Api.now;
    if (now.isBefore(startDate)) return ElectionStatus.upcoming;
    if (now.isBefore(endDate)) return ElectionStatus.open;
    return ElectionStatus.ended;
  }
}

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

Candidate _candidate(dynamic c, {String studentNum = ''}) => Candidate(
    c['id'],
    c['positionId'],
    personName(c['name']),
    partyLabel(c['partyList']),
    colorFor(c['id']),
    motto: c['motto'] ?? '',
    imageUrl: Api.absUrl(c['imageUrl']),
    studentNum: studentNum);

List<PositionTally> _parseTally(dynamic j) => [
      for (final p in j)
        PositionTally(p['positionId'], p['position'], p['totalVotes'], [
          for (final c in p['candidates'])
            TallyEntry(c['candidateId'], personName(c['name']),
                partyLabel(c['partyList']), c['votes']),
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

  List<Club> clubs = [];

  Student? me;
  bool homeLoaded = false;
  String? homeError;
  ClientElection? homeActive;
  ClientElection? homeOpenForOthers;
  ClientElection? homeNext;
  bool homeWaiting = false;
  bool hasVoted = false;
  int? ballotElectionId;
  List<Position> positions = [];
  List<Candidate> candidates = [];
  final Map<int, int> selections = {};

  String get electionLabel {
    final e = homeActive;
    return e == null ? '' : '${e.club}, ${e.schoolYear}';
  }

  Future<void> loadHome() async {
    try {
      final j = await Api.get('/api/client/home');
      Api.syncFrom(j['serverTime']);
      final m = j['me'];
      me = Student(m['id'], m['studentNum'], personName(m['fullName']),
          m['gradeLevelId']);
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
      ]..sort((a, b) => byName(a.name, b.name));
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

  bool adminLoaded = false;
  String? adminError;
  List<Election> elections = [];
  List<Season> history = [];
  List<Student> students = [];
  List<String> studentSchoolYears = [];
  List<Program> programs = [];
  List<PartyList> partyLists = [];
  int dashEligible = 0;
  int dashVoted = 0;

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
                <int>{...(e['gradeLevelIds'] as List).cast<int>()},
                positionCount: e['positionCount'] ?? 0,
                candidateCount: e['candidateCount'] ?? 0,
                eligibleCount: e['eligibleCount'] ?? 0,
                votedCount: e['votedCount'] ?? 0),
      ];
      history = [
        for (final h in r[2])
          Season(
              h['id'],
              h['electionId'],
              h['schoolYear'],
              h['club'],
              parseUtc(h['startDate']),
              parseUtc(h['endDate']),
              h['totalVoters'],
              h['votedCount'],
              h['audience']),
      ];
      clubs = [for (final c in r[3]) Club(c['id'], c['name'])];
      adminLoaded = true;
      adminError = null;
    } on ApiException catch (e) {
      adminError = e.message;
    }
    await loadPartyLists(notify: false);
    notifyListeners();
  }

  Future<String?> deleteClub(int id) async {
    try {
      await Api.delete('/api/admin/clubs/$id');
      clubs.removeWhere((c) => c.id == id);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> loadPartyLists({bool notify = true}) async {
    try {
      final r = await Api.get('/api/admin/party-lists');
      partyLists = [
        for (final p in r)
          PartyList(p['id'], p['name'], Api.absUrl(p['logoUrl']), p['color'])
      ];
    } on ApiException {}
    if (notify) notifyListeners();
  }

  Future<PartyList> ensurePartyList(String name) async {
    final j = await Api.post('/api/admin/party-lists', {'name': name.trim()});
    await loadPartyLists();
    return partyLists.firstWhere((p) => p.id == j['id'],
        orElse: () => PartyList(
            j['id'], j['name'], Api.absUrl(j['logoUrl']), j['color']));
  }

  Future<String?> deletePartyList(int id) async {
    try {
      await Api.delete('/api/admin/party-lists/$id');
      await loadPartyLists();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> setPartyColor(int id, String? color) async {
    try {
      await Api.put('/api/admin/party-lists/$id/color', {'color': color});
      await loadPartyLists();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<List<PartyGroup>> fetchPartyGroups(int electionId) async {
    final r = await Api.get('/api/admin/elections/$electionId/party-lists');
    return [
      for (final g in r)
        PartyGroup(g['id'], g['name'], Api.absUrl(g['logoUrl']), g['color'], [
          for (final m in g['members'])
            PartyMember(
              m['candidateId'],
              personName(m['name']),
              m['studentNum'],
              m['position'],
              m['positionOrder'],
              Api.absUrl(m['imageUrl']),
              m['gradeLevel'],
              m['section'] ?? '',
            ),
        ]),
    ];
  }

  Future<String?> removePartyLogo(int id) async {
    try {
      await Api.delete('/api/admin/party-lists/$id/logo');
      await loadPartyLists();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> loadStudents() async {
    try {
      final all = <Student>[];
      var page = 1;
      while (true) {
        final r = await Api.get('/api/admin/students?page=$page&pageSize=200');
        final items = r['items'] as List;
        for (final s in items) {
          all.add(Student(s['id'], s['studentNum'], personName(s['fullName']),
              s['gradeLevelId'],
              hasVoted: s['hasVoted'],
              canDelete: s['canDelete'],
              programId: s['programId'],
              programCode: s['programCode'],
              isActive: s['isActive'] ?? true,
              schoolYear: s['schoolYear'] ?? '',
              section: s['section'] ?? ''));
        }
        if (items.isEmpty || all.length >= (r['total'] as int)) break;
        page++;
      }
      students = all..sort((a, b) => byName(a.fullName, b.fullName));
      studentSchoolYears = {
        for (final s in all)
          if (s.schoolYear.isNotEmpty) s.schoolYear
      }.toList()
        ..sort((a, b) => b.compareTo(a));
    } on ApiException catch (e) {
      adminError = e.message;
    }
    notifyListeners();
  }

  Future<void> refreshAdmin() async {
    await loadAdmin();
    await loadStudents();
  }

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

  int? savedElectionId;

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
        final j = await Api.post('/api/admin/elections', body);
        savedElectionId = j is Map ? j['id'] as int? : null;
      } else {
        await Api.put('/api/admin/elections/$id', body);
        savedElectionId = id;
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

  Future<String?> closeSeason(Election e) async {
    try {
      await Api.post('/api/admin/elections/${e.id}/close');
      await refreshAdmin();
      return null;
    } on ApiException catch (x) {
      return x.message;
    }
  }

  Future<Map<int, String>> fetchCandidatePhotos(int electionId) async {
    final c = await Api.get('/api/admin/elections/$electionId/candidates');
    return {
      for (final x in c)
        if (Api.absUrl(x['imageUrl']) case final String url)
          x['id'] as int: url,
    };
  }

  Future<String?> loadSeasonWinners(Season s) async {
    try {
      final j = await Api.get('/api/admin/history/${s.id}');
      s.winners = [
        for (final w in j['winners'])
          SeasonWinner(w['position'], personName(w['name']),
              partyLabel(w['partyList']), w['voteCount']),
      ];
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> addStudent({
    required String studentNum,
    required String fullName,
    required int gradeLevelId,
    required String schoolYear,
    String section = '',
    int? programId,
  }) async {
    try {
      await Api.post('/api/admin/students', {
        'studentNum': studentNum.trim(),
        'fullName': fullName.trim(),
        'gradeLevelId': gradeLevelId,
        'schoolYear': schoolYear,
        'section': section.trim(),
        'programId': programId,
      });
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Super admin only; the server refuses other admins.
  Future<String?> updateStudent({
    required int id,
    required String studentNum,
    required String fullName,
    required int gradeLevelId,
    required String schoolYear,
    String section = '',
    int? programId,
  }) async {
    try {
      await Api.put('/api/admin/students/$id', {
        'studentNum': studentNum.trim(),
        'fullName': fullName.trim(),
        'gradeLevelId': gradeLevelId,
        'schoolYear': schoolYear,
        'section': section.trim(),
        'programId': programId,
      });
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> setStudentActive(int id, bool active) async {
    try {
      await Api.put('/api/admin/students/$id/status', {'isActive': active});
      await refreshAdmin();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<SeasonVoters> fetchSeasonVoters(int electionId) async {
    final j = await Api.get('/api/admin/elections/$electionId/voters');
    return SeasonVoters(
        j['status'],
        j['total'],
        j['voted'],
        [
          for (final v in j['items'])
            SeasonVoter(
              v['studentId'],
              v['studentNum'],
              personName(v['fullName']),
              v['gradeLevelId'],
              v['gradeLevel'],
              v['programCode'],
              v['section'] ?? '',
              v['isActive'],
              v['password'],
              v['hasVoted'],
              v['votedAt'] == null ? null : parseUtc(v['votedAt']),
              v['email'],
              v['passwordSentAt'] == null
                  ? null
                  : parseUtc(v['passwordSentAt']),
            ),
        ],
        j['emailReady'] == true);
  }

  Future<String> emailSeasonPassword(int electionId, int studentId) async {
    final j = await Api.post(
        '/api/admin/elections/$electionId/voters/$studentId/password/email');
    return j['email'] as String;
  }

  Future<MailJob> emailAllSeasonPasswords(int electionId,
      {required bool onlyUnsent}) async {
    final j = await Api.post(
        '/api/admin/elections/$electionId/voters/password/email-all',
        {'onlyUnsent': onlyUnsent});
    return MailJob.fromJson(j);
  }

  Future<MailJob> emailAllStatus(int electionId) async {
    final j = await Api.get(
        '/api/admin/elections/$electionId/voters/password/email-all');
    return MailJob.fromJson(j);
  }

  Future<String> resetSeasonPassword(int electionId, int studentId) async {
    final j = await Api.post(
        '/api/admin/elections/$electionId/voters/$studentId/password/reset');
    return j['password'] as String;
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

  Future<void> loadAdminCandidates(int electionId) async {
    adminCandElectionId = electionId;
    try {
      final p = await Api.get('/api/admin/elections/$electionId/positions');
      final c = await Api.get('/api/admin/elections/$electionId/candidates');
      adminPositions = [
        for (final x in p) Position(x['id'], x['title'], x['displayOrder'])
      ];
      adminCandidates = [
        for (final x in c) _candidate(x, studentNum: x['studentNum'])
      ]..sort((a, b) => byName(a.name, b.name));
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

  Future<List<Student>> searchStudents(String query, {int limit = 8}) async {
    final term = query.trim();
    if (term.isEmpty) return [];
    final r = await Api.get(
        '/api/admin/students?search=${Uri.encodeQueryComponent(term)}&pageSize=$limit');
    return [
      for (final s in r['items'] as List)
        Student(s['id'], s['studentNum'], personName(s['fullName']),
            s['gradeLevelId'],
            programId: s['programId'], programCode: s['programCode']),
    ];
  }

  Future<String?> addCandidateFor({
    required int electionId,
    required int studentId,
    required int positionId,
    String partyList = '',
    String motto = '',
  }) async {
    try {
      await Api.post('/api/admin/elections/$electionId/candidates', {
        'studentId': studentId,
        'positionId': positionId,
        'partyList': partyList.trim(),
        'motto': motto.trim(),
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> addPosition(int electionId, String title, int rank) async {
    try {
      await Api.post('/api/admin/elections/$electionId/positions',
          {'title': title.trim(), 'rank': rank});
      await loadAdminCandidates(electionId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updatePosition(
      int electionId, int positionId, String title, int rank) async {
    try {
      await Api.put('/api/admin/elections/$electionId/positions/$positionId',
          {'title': title.trim(), 'rank': rank});
      await loadAdminCandidates(electionId);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deletePosition(int electionId, int positionId) async {
    try {
      await Api.delete(
          '/api/admin/elections/$electionId/positions/$positionId');
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

  String gradeName(int id) {
    for (final g in gradeLevels) {
      if (g.id == id) return g.name;
    }
    return 'Unknown';
  }

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
    studentSchoolYears = [];
    partyLists = [];
    clubs = [];
    dashEligible = dashVoted = 0;
    adminCandElectionId = null;
    adminPositions = [];
    adminCandidates = [];
  }
}

final state = AppState();
