import 'package:todo_list/domain/entities/planner_member.dart';

class PlannerMemberModel {
  final String uid;
  final String email;
  final String? displayName;

  const PlannerMemberModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory PlannerMemberModel.fromMap(Map<String, dynamic> map) {
    return PlannerMemberModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
    );
  }

  PlannerMemberEntity toEntity() {
    return PlannerMemberEntity(
      uid: uid,
      email: email,
      displayName: displayName,
    );
  }
}
