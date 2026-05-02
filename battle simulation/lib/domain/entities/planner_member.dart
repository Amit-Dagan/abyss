class PlannerMemberEntity {
  final String uid;
  final String email;
  final String? displayName;

  const PlannerMemberEntity({
    required this.uid,
    required this.email,
    this.displayName,
  });

  String get label {
    final String? trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return '$trimmedName ($email)';
    }
    return email;
  }

  String get compactLabel {
    final String? trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return email;
  }
}
