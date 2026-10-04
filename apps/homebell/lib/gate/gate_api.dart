import 'package:family_core/family_core.dart';

enum GateAlertStatus { ringing, acknowledged, cancelled, expired }

class GateAlert {
  const GateAlert({
    required this.id,
    required this.status,
    required this.sender,
    required this.acknowledgedBy,
    required this.ringCount,
  });

  factory GateAlert.fromJson(Map<String, dynamic> json) => GateAlert(
        id: json['id'] as String,
        status: GateAlertStatus.values.byName((json['status'] as String).toLowerCase()),
        sender: Member.fromJson(json['sender'] as Map<String, dynamic>),
        acknowledgedBy: json['acknowledgedBy'] == null
            ? null
            : Member.fromJson(json['acknowledgedBy'] as Map<String, dynamic>),
        ringCount: json['ringCount'] as int,
      );

  final String id;
  final GateAlertStatus status;
  final Member sender;
  final Member? acknowledgedBy;
  final int ringCount;
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
}
