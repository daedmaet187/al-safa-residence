enum HouseholdAccess { full, limited }

class HouseholdMember {
  final String id;
  final String primaryUserId;
  final String phone;
  final String name;
  final String relationship;
  final HouseholdAccess accessLevel;
  final bool isActive;
  final DateTime createdAt;

  const HouseholdMember({
    required this.id,
    required this.primaryUserId,
    required this.phone,
    required this.name,
    required this.relationship,
    required this.accessLevel,
    required this.isActive,
    required this.createdAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) => HouseholdMember(
        id: json['id'] as String,
        primaryUserId: json['primaryUserId'] as String,
        phone: json['phone'] as String,
        name: json['name'] as String,
        relationship: json['relationship'] as String,
        accessLevel: (json['accessLevel'] as String?)?.toLowerCase() == 'full'
            ? HouseholdAccess.full
            : HouseholdAccess.limited,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'primaryUserId': primaryUserId,
        'phone': phone,
        'name': name,
        'relationship': relationship,
        'accessLevel': accessLevel == HouseholdAccess.full ? 'FULL' : 'LIMITED',
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
