import 'package:family_core/family_core.dart';
import 'package:flutter/foundation.dart';

import '../gate/gate_api.dart';

/// The outcome of "On my way": the heads-up that was sent, or why it couldn't be.
typedef AnnounceResult = ({Arrival? arrival, String? error});

/// Everything on the home screen besides the gate button: who's on their way, and what
/// happened at the gate recently. Refreshed alongside the gate state.
class ActivityController extends ChangeNotifier {
  ActivityController({required this.api, required this.myMemberId});

  final GateApi api;
  final String myMemberId;

  /// The home screen shows only the latest few, so it stays short.
  static const recentLimit = 5;

  List<Arrival> _arrivals = const [];
  List<GateAlert> _recent = const [];
  bool _announcing = false;

  /// Other people on their way (mine is shown separately as "you told the family").
  List<Arrival> get othersOnTheWay => _arrivals.where((a) => a.member.id != myMemberId).toList();

  Arrival? get myArrival => _arrivals.where((a) => a.member.id == myMemberId).firstOrNull;

  /// Finished alerts only (the ringing one is the main card), newest first, at most [recentLimit].
  List<GateAlert> get recent =>
      _recent.where((a) => a.status != GateAlertStatus.ringing).take(recentLimit).toList();

  bool get announcing => _announcing;

  Future<void> refresh() async {
    try {
      // One extra, in case the newest one is still ringing and gets filtered out.
      final results = await Future.wait([api.arrivals(), api.recent(limit: recentLimit + 1)]);
      _arrivals = results[0] as List<Arrival>;
      _recent = results[1] as List<GateAlert>;
      notifyListeners();
    } catch (e) {
      // The gate state shows connection problems; activity just keeps its last values.
      debugPrint('Activity refresh failed: $e');
    }
  }

  /// "On my way, about [etaMinutes] min." Replaces my previous heads-up.
  Future<AnnounceResult> announce(int etaMinutes) async {
    _announcing = true;
    notifyListeners();
    try {
      final arrival = await api.announceArrival(etaMinutes);
      _arrivals = [..._arrivals.where((a) => a.member.id != myMemberId), arrival];
      return (arrival: arrival, error: null);
    } on ApiException catch (e) {
      return (arrival: null, error: e.message);
    } catch (_) {
      return (arrival: null, error: "Can't reach the server. Check your connection.");
    } finally {
      _announcing = false;
      notifyListeners();
    }
  }

  /// "I'm not coming": removes my heads-up for everyone. Returns an error message, or null.
  Future<String?> cancelMine() async {
    _announcing = true;
    notifyListeners();
    try {
      await api.cancelArrival();
      _arrivals = _arrivals.where((a) => a.member.id != myMemberId).toList();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return "Can't reach the server. Check your connection.";
    } finally {
      _announcing = false;
      notifyListeners();
    }
  }

  /// "Got it" on someone else's heads-up. Returns an error message, or null on success.
  Future<String?> markSeen(String noticeId) async {
    try {
      final updated = await api.markArrivalSeen(noticeId);
      _arrivals = [for (final a in _arrivals) a.id == noticeId ? updated : a];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      await refresh(); // e.g. the heads-up already ended
      return e.message;
    } catch (_) {
      return "Can't reach the server. Check your connection.";
    }
  }
}
