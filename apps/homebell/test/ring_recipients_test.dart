import 'package:family_core/family_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homebell/gate/gate_controller.dart';
import 'package:homebell/gate/ring_settings.dart';

import 'fakes.dart';

void main() {
  const mama = Member(id: 'mama', displayName: 'Mama', role: MemberRole.parent);
  const others = [papa, mama];

  group('ringRecipientIds', () {
    test('rings everyone (null) when nobody is left out', () {
      expect(ringRecipientIds(others, {}), isNull);
      // Someone who already left the family doesn't count.
      expect(ringRecipientIds(others, {'gone'}), isNull);
    });

    test('lists who is still rung when someone is left out', () {
      expect(ringRecipientIds(others, {'papa'}), ['mama']);
      expect(ringRecipientIds(others, {'papa', 'mama'}), isEmpty);
    });
  });

  test('joinNames reads naturally', () {
    expect(joinNames([]), '');
    expect(joinNames(['Mama']), 'Mama');
    expect(joinNames(['Mama', 'Papa']), 'Mama and Papa');
    expect(joinNames(['Mama', 'Papa', 'Ate']), 'Mama, Papa and Ate');
  });

  group('GateAlert.rings', () {
    test('rings only the chosen members, never the sender', () {
      final a = alert(sender: papa, recipients: const [mama]);
      expect(a.rings('mama'), isTrue);
      expect(a.rings(me.id), isFalse);
      expect(a.rings('papa'), isFalse);
    });

    test('alerts from older versions ring everyone else', () {
      final a = alert(sender: papa);
      expect(a.rings(me.id), isTrue);
      expect(a.rings('papa'), isFalse);
    });
  });

  test('ringing sends the chosen recipients', () async {
    final api = FakeGateApi();
    final gate = GateController(api: api, myMemberId: me.id);
    await gate.ring(recipientIds: ['mama']);
    expect(api.rungRecipients, ['mama']);
    expect(gate.state, isA<Ringing>());
  });
}
