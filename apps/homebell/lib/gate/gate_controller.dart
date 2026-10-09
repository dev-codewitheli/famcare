import 'package:family_core/family_core.dart';
import 'package:flutter/foundation.dart';

import 'gate_api.dart';

/// What the home screen shows, derived from the family's active alert.
sealed class GateState {
  const GateState();
}

class Idle extends GateState {
  const Idle();
}

/// I'm at the gate and the family's phones are ringing.
class Ringing extends GateState {
  const Ringing(this.alert);
  final GateAlert alert;
}

/// Someone else is at the gate.
class SomeoneAtGate extends GateState {
  const SomeoneAtGate(this.alert);
  final GateAlert alert;
}

/// How my alert ended: someone's coming, or nobody answered.
class Outcome extends GateState {
  const Outcome(this.alert);
  final GateAlert alert;
}

class GateController extends ChangeNotifier {
  GateController({required this.api, required this.myMemberId});

  final GateApi api;
  final String myMemberId;

  GateState _state = const Idle();
  bool _busy = false;
  String? _error;

  /// My alert that's still ringing; when it stops, we fetch how it ended.
  String? _trackedAlertId;

  GateState get state => _state;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> refresh() => _run(_sync, showBusy: false);

  /// Rings [recipientIds], or everyone else when null.
  Future<void> ring({List<String>? recipientIds}) =>
      _run(() async => _apply(await api.ring(recipientIds: recipientIds)));

  Future<void> coming(String alertId) => _run(() async {
        try {
          await api.acknowledge(alertId);
        } on ApiException catch (e) {
          // Already answered (maybe from the notification) or over: just show where things stand.
          if (e.statusCode != 409) rethrow;
        }
        await _sync();
      });

  Future<void> cancel(String alertId) => _run(() async {
        await api.cancel(alertId);
        _trackedAlertId = null;
        _state = const Idle();
      });

  void dismissOutcome() {
    _state = const Idle();
    notifyListeners();
  }

  Future<void> _sync() async {
    final active = await api.active();
    if (active != null) return _apply(active);

    final tracked = _trackedAlertId;
    if (tracked != null) {
      _trackedAlertId = null;
      final ended = await api.get(tracked);
      _state = ended.status == GateAlertStatus.cancelled ? const Idle() : Outcome(ended);
    } else if (_state is! Outcome) {
      _state = const Idle();
    }
  }

  void _apply(GateAlert alert) {
    if (alert.sender.id == myMemberId) {
      // Also covers re-opening the app while my alert is still ringing.
      _trackedAlertId = alert.id;
      _state = Ringing(alert);
    } else {
      _state = SomeoneAtGate(alert);
    }
  }

  Future<void> _run(Future<void> Function() action, {bool showBusy = true}) async {
    if (showBusy) {
      _busy = true;
      notifyListeners();
    }
    try {
      await action();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = "Can't reach the server. Check your connection.";
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
