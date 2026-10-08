import 'package:family_core/family_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homebell/gate/gate_api.dart';
import 'package:homebell/home/activity_controller.dart';
import 'package:homebell/setup/phone_setup.dart';

import 'fakes.dart';

void main() {
  group('ActivityController', () {
    late FakeGateApi api;
    late ActivityController activity;

    setUp(() {
      api = FakeGateApi();
      activity = ActivityController(api: api, myMemberId: me.id);
    });

    test('separates my heads-up from others on the way', () async {
      api.activeArrivals = [arrival(papa, 10), arrival(me, 5)];
      await activity.refresh();

      expect(activity.othersOnTheWay.map((a) => a.member.displayName), ['Papa']);
      expect(activity.myArrival?.etaMinutes, 5);
    });

    test('announcing replaces my previous heads-up and says who was told', () async {
      await activity.announce(15);
      final result = await activity.announce(5);

      expect(result.error, isNull);
      expect(result.arrival?.notified.map((m) => m.displayName), ['Papa']);
      expect(activity.myArrival?.etaMinutes, 5);
    });

    test('announcing reports server errors instead of throwing', () async {
      api.failWith = const ApiException(400, 'BAD_REQUEST', 'ETA must be between 1 and 60 minutes');
      final result = await activity.announce(99);
      expect(result.arrival, isNull);
      expect(result.error, 'ETA must be between 1 and 60 minutes');
      expect(activity.announcing, isFalse);
    });

    test('"Got it" marks someone else\'s heads-up as seen by me', () async {
      api.activeArrivals = [arrival(papa, 10)];
      await activity.refresh();

      expect(await activity.markSeen('n-papa'), isNull);
      expect(activity.othersOnTheWay.single.seenByMember(me.id), isTrue);
    });

    test('recent activity hides the ringing alert and shows at most 5', () async {
      api.recentAlerts = [
        alert(id: 'now', sender: papa),
        for (var i = 0; i < 7; i++) alert(id: 'old$i', sender: papa, status: GateAlertStatus.expired),
      ];
      await activity.refresh();

      expect(activity.recent.map((a) => a.id), ['old0', 'old1', 'old2', 'old3', 'old4']);
    });
  });

  test('answeredAfter measures how long the person waited', () {
    final answered = alert(
      sender: papa,
      status: GateAlertStatus.acknowledged,
      acknowledgedBy: me,
      resolvedAt: t0.add(const Duration(seconds: 40)),
    );
    expect(answered.answeredAfter, const Duration(seconds: 40));
    expect(alert(sender: papa, status: GateAlertStatus.expired).answeredAfter, isNull);
  });

  test('minutesLeft rounds up and stops at zero; isDue flips at the expected time', () {
    final a = arrival(papa, 10);
    expect(a.minutesLeft(t0.add(const Duration(minutes: 3, seconds: 30))), 7);
    expect(a.minutesLeft(t0.add(const Duration(minutes: 12))), 0);
    expect(a.isDue(t0.add(const Duration(minutes: 9, seconds: 59))), isFalse);
    expect(a.isDue(t0.add(const Duration(minutes: 10))), isTrue);
  });

  group('PhoneBrand', () {
    test('groups sub-brands with their parent software', () {
      expect(PhoneBrand.fromManufacturer('Xiaomi'), PhoneBrand.xiaomi);
      expect(PhoneBrand.fromManufacturer('POCO'), PhoneBrand.xiaomi);
      expect(PhoneBrand.fromManufacturer('OnePlus'), PhoneBrand.oppo);
      expect(PhoneBrand.fromManufacturer('realme'), PhoneBrand.realme);
      expect(PhoneBrand.fromManufacturer('INFINIX'), PhoneBrand.transsion);
      expect(PhoneBrand.fromManufacturer('TECNO'), PhoneBrand.transsion);
      expect(PhoneBrand.fromManufacturer('samsung'), PhoneBrand.samsung);
      expect(PhoneBrand.fromManufacturer('Google'), PhoneBrand.other);
    });
  });

  group('setupStepsFor', () {
    List<String> ids(PhoneBrand brand) => setupStepsFor(brand).map((s) => s.id).toList();

    test('every brand gets the core Android steps first', () {
      for (final brand in PhoneBrand.values) {
        expect(ids(brand).take(5), ['notifications', 'fullscreen', 'battery', 'alarm_volume', 'ring_channel']);
      }
    });

    test('autostart only for brands with a separate autostart screen', () {
      for (final brand in [PhoneBrand.xiaomi, PhoneBrand.vivo, PhoneBrand.transsion]) {
        expect(ids(brand), contains('autostart'), reason: brand.name);
      }
      for (final brand in [PhoneBrand.oppo, PhoneBrand.realme, PhoneBrand.samsung, PhoneBrand.other]) {
        expect(ids(brand), isNot(contains('autostart')), reason: brand.name);
      }
    });

    test('ColorOS background activity and auto launch are a single step', () {
      for (final brand in [PhoneBrand.oppo, PhoneBrand.realme]) {
        expect(ids(brand).where((id) => id.startsWith('oem_')), ['oem_background'], reason: brand.name);
      }
    });

    test('no brand battery step that duplicates Android battery optimization', () {
      for (final brand in [PhoneBrand.xiaomi, PhoneBrand.samsung, PhoneBrand.transsion, PhoneBrand.other]) {
        expect(ids(brand).where((id) => id.startsWith('oem_')), isEmpty, reason: brand.name);
      }
    });

    test('Xiaomi checks its hidden settings automatically', () {
      final steps = setupStepsFor(PhoneBrand.xiaomi);
      expect(ids(PhoneBrand.xiaomi), contains('xiaomi_lock_screen'));
      for (final id in ['autostart', 'xiaomi_lock_screen', 'ring_channel']) {
        expect(steps.firstWhere((s) => s.id == id).check, isNotNull, reason: id);
      }
    });

    test('Samsung and stock Android have no required brand steps', () {
      for (final brand in [PhoneBrand.samsung, PhoneBrand.other]) {
        expect(setupStepsFor(brand).skip(5).where((s) => !s.optional), isEmpty, reason: brand.name);
      }
    });

    test('locking in recents is recommended, not required', () {
      final lock = setupStepsFor(PhoneBrand.xiaomi).firstWhere((s) => s.id == 'lock_recents');
      expect(lock.optional, isTrue);
      expect(lock.check, isNull);
    });

    test('step ids are unique per brand', () {
      for (final brand in PhoneBrand.values) {
        expect(ids(brand).toSet().length, ids(brand).length, reason: brand.name);
      }
    });
  });
}
