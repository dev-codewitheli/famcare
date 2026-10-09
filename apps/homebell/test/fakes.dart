import 'package:family_core/family_core.dart';
import 'package:homebell/gate/gate_api.dart';

const me = Member(id: 'me', displayName: 'Ate', role: MemberRole.member);
const papa = Member(id: 'papa', displayName: 'Papa', role: MemberRole.parent);

final t0 = DateTime(2026, 10, 9, 18, 0);

GateAlert alert({
  String id = 'a1',
  required Member sender,
  GateAlertStatus status = GateAlertStatus.ringing,
  Member? acknowledgedBy,
  DateTime? resolvedAt,
}) =>
    GateAlert(
      id: id,
      status: status,
      sender: sender,
      acknowledgedBy: acknowledgedBy,
      ringCount: 1,
      createdAt: t0,
      resolvedAt: resolvedAt,
    );

Arrival arrival(Member member, int minutes, {List<Member> notified = const []}) => Arrival(
    id: 'n-${member.id}',
    member: member,
    etaMinutes: minutes,
    expectedAt: t0.add(Duration(minutes: minutes)),
    notified: notified);

/// In-memory stand-in for the server.
class FakeGateApi implements GateApi {
  GateAlert? activeAlert;
  final ended = <String, GateAlert>{};
  final acknowledged = <String>[];
  List<GateAlert> recentAlerts = [];
  List<Arrival> activeArrivals = [];
  Object? failWith;

  @override
  Future<GateAlert?> active() async => activeAlert;

  @override
  Future<GateAlert> ring() async => activeAlert ??= alert(sender: me);

  @override
  Future<GateAlert> get(String id) async => ended[id]!;

  @override
  Future<GateAlert> acknowledge(String id) async {
    acknowledged.add(id);
    activeAlert = null;
    return alert(sender: papa, status: GateAlertStatus.acknowledged, acknowledgedBy: me);
  }

  @override
  Future<GateAlert> cancel(String id) async {
    activeAlert = null;
    return alert(sender: me, status: GateAlertStatus.cancelled);
  }

  @override
  Future<List<GateAlert>> recent({int limit = 5}) async => recentAlerts;

  @override
  Future<List<Arrival>> arrivals() async => activeArrivals;

  @override
  Future<Arrival> announceArrival(int etaMinutes) async {
    if (failWith != null) throw failWith!;
    final sent = arrival(me, etaMinutes, notified: const [papa]);
    activeArrivals = [...activeArrivals.where((a) => a.member.id != me.id), sent];
    return sent;
  }

  @override
  Future<void> cancelArrival() async {
    if (failWith != null) throw failWith!;
    activeArrivals = activeArrivals.where((a) => a.member.id != me.id).toList();
  }

  @override
  Future<Arrival> markArrivalSeen(String noticeId) async {
    if (failWith != null) throw failWith!;
    final a = activeArrivals.firstWhere((a) => a.id == noticeId);
    final seen = Arrival(
        id: a.id, member: a.member, etaMinutes: a.etaMinutes, expectedAt: a.expectedAt, seenBy: [...a.seenBy, me]);
    activeArrivals = [for (final x in activeArrivals) x.id == noticeId ? seen : x];
    return seen;
  }
}
