import 'package:family_core/family_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homebell/gate/gate_api.dart';
import 'package:homebell/gate/gate_controller.dart';

const me = Member(id: 'me', displayName: 'Ate', role: MemberRole.member);
const papa = Member(id: 'papa', displayName: 'Papa', role: MemberRole.parent);

GateAlert alert({
  required Member sender,
  GateAlertStatus status = GateAlertStatus.ringing,
  Member? acknowledgedBy,
}) =>
    GateAlert(id: 'a1', status: status, sender: sender, acknowledgedBy: acknowledgedBy, ringCount: 1);

/// In-memory stand-in for the server.
class FakeGateApi implements GateApi {
  GateAlert? activeAlert;
  final ended = <String, GateAlert>{};
  final acknowledged = <String>[];

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
}

void main() {
  late FakeGateApi api;
  late GateController gate;

  setUp(() {
    api = FakeGateApi();
    gate = GateController(api: api, myMemberId: me.id);
  });

  test('starts idle when nobody is at the gate', () async {
    await gate.refresh();
    expect(gate.state, isA<Idle>());
  });

  test('ringing shows my alert as ringing', () async {
    await gate.ring();
    expect(gate.state, isA<Ringing>());
  });

  test("someone else's alert offers \"Coming!\" and answering clears it", () async {
    api.activeAlert = alert(sender: papa);
    await gate.refresh();
    expect(gate.state, isA<SomeoneAtGate>());

    await gate.coming('a1');
    expect(api.acknowledged, ['a1']);
    expect(gate.state, isA<Idle>());
  });

  test('when my alert is answered, I see who is coming', () async {
    await gate.ring();
    api.activeAlert = null;
    api.ended['a1'] = alert(sender: me, status: GateAlertStatus.acknowledged, acknowledgedBy: papa);

    await gate.refresh();

    final state = gate.state;
    expect(state, isA<Outcome>());
    expect((state as Outcome).alert.acknowledgedBy?.displayName, 'Papa');

    // The outcome stays until dismissed, even though polling continues.
    await gate.refresh();
    expect(gate.state, isA<Outcome>());
    gate.dismissOutcome();
    expect(gate.state, isA<Idle>());
  });

  test('reopening the app while my alert rings resumes tracking it', () async {
    api.activeAlert = alert(sender: me);
    await gate.refresh();
    expect(gate.state, isA<Ringing>());

    api.activeAlert = null;
    api.ended['a1'] = alert(sender: me, status: GateAlertStatus.expired);
    await gate.refresh();
    expect((gate.state as Outcome).alert.status, GateAlertStatus.expired);
  });

  test('cancelling returns to idle', () async {
    await gate.ring();
    await gate.cancel('a1');
    expect(gate.state, isA<Idle>());
  });
}
