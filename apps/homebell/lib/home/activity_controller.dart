import 'package:family_core/family_core.dart';
import 'package:flutter/foundation.dart';

import '../gate/gate_api.dart';

/// Everything on the home screen besides the gate button: who's on their way, and what
/// happened at the gate recently. Refreshed alongside the gate state.
class ActivityController extends ChangeNotifier {
  ActivityController({required this.api, required this.myMemberId});

  final GateApi api;
  final String myMemberId;

  List<Arrival> _arrivals = const [];
  List<GateAlert> _recent = const [];
  bool _announcing = false;

  /// Other people on their way (mine is shown separately as "you told the family").
  List<Arrival> get othersOnTheWay => _arrivals.where((a) => a.member.id != myMemberId).toList();

  Arrival? get myArrival => _arrivals.where((a) => a.member.id == myMemberId).firstOrNull;

  /// Finished alerts only; the ringing one is the main card.
  List<GateAlert> get recent => _recent.where((a) => a.status != GateAlertStatus.ringing).toList();

  bool get announcing => _announcing;

  Future<void> refresh() async {
    try {
      final results = await Future.wait([api.arrivals(), api.recent()]);
      _arrivals = results[0] as List<Arrival>;
      _recent = results[1] as List<GateAlert>;
      notifyListeners();
    } catch (e) {
      // The gate state shows connection problems; activity just keeps its last values.
      debugPrint('Activity refresh failed: $e');
    }
  }

  /// Returns an error message, or null on success.
  Future<String?> announce(int etaMinutes) async {
    _announcing = true;
    notifyListeners();
    try {
      final arrival = await api.announceArrival(etaMinutes);
      _arrivals = [..._arrivals.where((a) => a.member.id != myMemberId), arrival];
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
}
