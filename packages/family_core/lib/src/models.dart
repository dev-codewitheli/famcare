enum MemberRole { parent, member }

class Member {
  const Member({required this.id, required this.displayName, required this.role});

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        role: MemberRole.values.byName((json['role'] as String).toLowerCase()),
      );

  final String id;
  final String displayName;
  final MemberRole role;
}

class Family {
  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.me,
    required this.members,
  });

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['inviteCode'] as String,
        me: Member.fromJson(json['me'] as Map<String, dynamic>),
        members: [
          for (final m in json['members'] as List<dynamic>) Member.fromJson(m as Map<String, dynamic>),
        ],
      );

  final String id;
  final String name;
  final String inviteCode;
  final Member me;
  final List<Member> members;
}
