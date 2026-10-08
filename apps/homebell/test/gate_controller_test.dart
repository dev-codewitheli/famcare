import 'package:flutter_test/flutter_test.dart';
import 'package:homebell/gate/gate_api.dart';
import 'package:homebell/gate/gate_controller.dart';

import 'fakes.dart';

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
