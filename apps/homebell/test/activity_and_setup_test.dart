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

    test('announcing replaces my previous heads-up', () async {
      await activity.announce(15);
      final error = await activity.announce(5);

      expect(error, isNull);
      expect(activity.myArrival?.etaMinutes, 5);
    });

    test('announcing reports server errors instead of throwing', () async {
      api.failWith = const ApiException(400, 'BAD_REQUEST', 'ETA must be between 1 and 60 minutes');
      expect(await activity.announce(99), 'ETA must be between 1 and 60 minutes');
      expect(activity.announcing, isFalse);
    });

    test('recent activity hides the alert that is still ringing', () async {
      api.recentAlerts = [
        alert(id: 'now', sender: papa),
        alert(id: 'before', sender: papa, status: GateAlertStatus.expired),
      ];
      await activity.refresh();

      expect(activity.recent.map((a) => a.id), ['before']);
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

  test('minutesLeft rounds up and stops at zero', () {
    final a = arrival(papa, 10);
    expect(a.minutesLeft(t0.add(const Duration(minutes: 3, seconds: 30))), 7);
    expect(a.minutesLeft(t0.add(const Duration(minutes: 12))), 0);
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

    test('autostart only for brands that have it', () {
      for (final brand in [PhoneBrand.xiaomi, PhoneBrand.oppo, PhoneBrand.realme, PhoneBrand.vivo, PhoneBrand.transsion]) {
        expect(ids(brand), contains('autostart'), reason: brand.name);
      }
      expect(ids(PhoneBrand.samsung), isNot(contains('autostart')));
      expect(ids(PhoneBrand.other), isNot(contains('autostart')));
    });

    test('Xiaomi includes the hidden lock-screen permission', () {
      expect(ids(PhoneBrand.xiaomi), contains('xiaomi_lock_screen'));
    });

    test('locking in recents is recommended, not required', () {
      final lock = setupStepsFor(PhoneBrand.xiaomi).firstWhere((s) => s.id == 'lock_recents');
      expect(lock.optional, isTrue);
      expect(lock.isManual, isTrue);
    });

    test('step ids are unique per brand', () {
      for (final brand in PhoneBrand.values) {
        expect(ids(brand).toSet().length, ids(brand).length, reason: brand.name);
      }
    });
  });
}
