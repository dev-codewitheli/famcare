import 'package:family_core/family_core.dart';

enum GateAlertStatus { ringing, acknowledged, cancelled, expired }

class GateAlert {
  const GateAlert({
    required this.id,
    required this.status,
    required this.sender,
    required this.acknowledgedBy,
    required this.ringCount,
    required this.createdAt,
    this.resolvedAt,
  });

  factory GateAlert.fromJson(Map<String, dynamic> json) => GateAlert(
        id: json['id'] as String,
        status: GateAlertStatus.values.byName((json['status'] as String).toLowerCase()),
        sender: Member.fromJson(json['sender'] as Map<String, dynamic>),
        acknowledgedBy: json['acknowledgedBy'] == null
            ? null
            : Member.fromJson(json['acknowledgedBy'] as Map<String, dynamic>),
        ringCount: json['ringCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'] as String).toLocal(),
      );

  final String id;
  final GateAlertStatus status;
  final Member sender;
  final Member? acknowledgedBy;
  final int ringCount;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// How long the person waited for a "Coming!", when someone answered.
  Duration? get answeredAfter =>
      status == GateAlertStatus.acknowledged && resolvedAt != null ? resolvedAt!.difference(createdAt) : null;
}

/// "On my way, about N minutes."
class Arrival {
  const Arrival({
    required this.id,
    required this.member,
    required this.etaMinutes,
    required this.expectedAt,
    this.seenBy = const [],
    this.notified = const [],
  });

  factory Arrival.fromJson(Map<String, dynamic> json) => Arrival(
        id: json['id'] as String,
        member: Member.fromJson(json['member'] as Map<String, dynamic>),
        etaMinutes: json['etaMinutes'] as int,
        expectedAt: DateTime.parse(json['expectedAt'] as String).toLocal(),
        seenBy: _members(json['seenBy']),
        notified: _members(json['notified']),
      );

  static List<Member> _members(Object? json) => [
        for (final m in (json as List<dynamic>? ?? const [])) Member.fromJson(m as Map<String, dynamic>),
      ];

  final String id;
  final Member member;
  final int etaMinutes;
  final DateTime expectedAt;

  /// Who tapped "Got it".
  final List<Member> seenBy;

  /// Who the heads-up was sent to (only right after announcing).
  final List<Member> notified;

  /// The expected time has come: "are you at the gate?"
  bool isDue(DateTime now) => !now.isBefore(expectedAt);

  /// The server drops a heads-up this long after the expected arrival.
  static const grace = Duration(minutes: 10);

  /// When the heads-up disappears on its own if nobody rings or cancels.
  DateTime get hidesAt => expectedAt.add(grace);

  bool seenByMember(String memberId) => seenBy.any((m) => m.id == memberId);

  /// Whole minutes until the expected arrival; 0 once it's due.
  int minutesLeft(DateTime now) {
    final left = expectedAt.difference(now).inSeconds;
    return left <= 0 ? 0 : (left / 60).ceil();
  }
}

class GateApi {
  const GateApi(this._api);

  final ApiClient _api;

  /// "I'm at the gate". Returns the already-ringing alert if someone tapped first.
  Future<GateAlert> ring() async => GateAlert.fromJson(await _api.post('/api/gate-alerts'));

  /// The family's ringing alert, or null when nobody is at the gate.
  Future<GateAlert?> active() async {
    final json = await _api.get('/api/gate-alerts/active');
    return json == null ? null : GateAlert.fromJson(json);
  }

  Future<GateAlert> get(String id) async => GateAlert.fromJson(await _api.get('/api/gate-alerts/$id'));

  /// "Coming!"
  Future<GateAlert> acknowledge(String id) async =>
      GateAlert.fromJson(await _api.post('/api/gate-alerts/$id/acknowledge'));

  Future<GateAlert> cancel(String id) async =>
      GateAlert.fromJson(await _api.post('/api/gate-alerts/$id/cancel'));

  /// Newest first.
  Future<List<GateAlert>> recent({int limit = 5}) async => [
        for (final json in await _api.get('/api/gate-alerts/recent?limit=$limit') as List<dynamic>)
          GateAlert.fromJson(json as Map<String, dynamic>),
      ];

  Future<Arrival> announceArrival(int etaMinutes) async =>
      Arrival.fromJson(await _api.post('/api/arrivals', {'etaMinutes': etaMinutes}));

  /// "I'm not coming after all": removes my heads-up for everyone.
  Future<void> cancelArrival() => _api.delete('/api/arrivals/mine');

  /// "Got it": tells the person on their way that I saw their heads-up.
  Future<Arrival> markArrivalSeen(String noticeId) async =>
      Arrival.fromJson(await _api.post('/api/arrivals/$noticeId/seen'));

  /// Who's on their way, soonest first.
  Future<List<Arrival>> arrivals() async => [
        for (final json in await _api.get('/api/arrivals/active') as List<dynamic>)
          Arrival.fromJson(json as Map<String, dynamic>),
      ];
}
