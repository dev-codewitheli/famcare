import 'dart:convert';

import 'package:family_core/family_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ApiClient client(MockClientHandler handler) => ApiClient(
        baseUrl: Uri.parse('http://server.test'),
        token: () async => 'papa',
        client: MockClient(handler),
      );

  test('sends the bearer token and parses the family', () async {
    final api = FamilyApi(client((request) async {
      expect(request.headers['Authorization'], 'Bearer papa');
      expect(request.url.path, '/api/families/mine');
      return http.Response(
        jsonEncode({
          'id': 'f1',
          'name': 'Centeno',
          'inviteCode': 'ABC234',
          'me': {'id': 'm1', 'displayName': 'Papa', 'role': 'PARENT'},
          'members': [
            {'id': 'm1', 'displayName': 'Papa', 'role': 'PARENT'},
            {'id': 'm2', 'displayName': 'Ate', 'role': 'MEMBER'},
          ],
        }),
        200,
      );
    }));

    final family = await api.mine();

    expect(family.inviteCode, 'ABC234');
    expect(family.me.role, MemberRole.parent);
    expect(family.members.map((m) => m.displayName), ['Papa', 'Ate']);
  });

  test('turns problem details into an ApiException with a code', () async {
    final api = FamilyApi(client((_) async => http.Response(
          jsonEncode({'status': 409, 'detail': 'Create or join a family first', 'code': 'NOT_IN_FAMILY'}),
          409,
        )));

    expect(
      api.mine(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOT_IN_FAMILY')),
    );
  });

  test('treats 204 as no content', () async {
    final api = client((_) async => http.Response('', 204));
    expect(await api.get('/api/gate-alerts/active'), isNull);
  });
}
