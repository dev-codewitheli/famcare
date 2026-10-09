import 'api_client.dart';
import 'models.dart';

class FamilyApi {
  const FamilyApi(this._api);

  final ApiClient _api;

  /// Throws [ApiException] with code `NOT_IN_FAMILY` if the user hasn't joined one yet.
  Future<Family> mine() async => Family.fromJson(await _api.get('/api/families/mine'));

  Future<Family> create({required String familyName, required String displayName}) async =>
      Family.fromJson(await _api.post('/api/families', {'familyName': familyName, 'displayName': displayName}));

  Future<Family> join({required String inviteCode, required String displayName}) async =>
      Family.fromJson(await _api.post('/api/families/join', {'inviteCode': inviteCode, 'displayName': displayName}));

  Future<void> registerDevice(String pushToken) => _api.put('/api/devices', {'pushToken': pushToken});

  Future<void> unregisterDevice(String pushToken) => _api.post('/api/devices/unregister', {'pushToken': pushToken});

  Future<void> leave() => _api.post('/api/families/mine/leave');

  Future<Family> resetInviteCode() async => Family.fromJson(await _api.post('/api/families/mine/invite-code'));

  /// Deletes the account and everything stored about it (and the Firebase sign-in).
  Future<void> deleteAccount() => _api.delete('/api/account');

  /// Changes my nickname and/or icon; a null field stays as it is, an empty [avatar] removes it.
  Future<Family> updateMe({String? displayName, String? avatar}) async =>
      Family.fromJson(await _api.patch('/api/families/mine/me', {'displayName': ?displayName, 'avatar': ?avatar}));

  Future<Family> renameFamily(String familyName) async =>
      Family.fromJson(await _api.patch('/api/families/mine', {'familyName': familyName}));

  Future<Family> removeMember(String memberId) async =>
      Family.fromJson(await _api.delete('/api/families/mine/members/$memberId'));
}
