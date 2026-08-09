import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalNodeType { goal, project, milestone, week, day }

extension GoalNodeTypeLabel on GoalNodeType {
  String get label {
    switch (this) {
      case GoalNodeType.goal:
        return 'هدف اصلی';
      case GoalNodeType.project:
        return 'پروژه';
      case GoalNodeType.milestone:
        return 'نقطه عطف';
      case GoalNodeType.week:
        return 'هفته';
      case GoalNodeType.day:
        return 'روز';
    }
  }

  GoalNodeType? get childType {
    switch (this) {
      case GoalNodeType.goal:
        return GoalNodeType.project;
      case GoalNodeType.project:
        return GoalNodeType.milestone;
      case GoalNodeType.milestone:
        return GoalNodeType.week;
      case GoalNodeType.week:
        return GoalNodeType.day;
      case GoalNodeType.day:
        return null;
    }
  }
}

class GoalModel {
  final String id;
  final String title;
  final String description;
  final GoalNodeType type;
  final String? parentId;
  final int order;
  final DateTime createdAt;
  final int? manualProgress;

  GoalModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    this.parentId,
    this.order = 0,
    required this.createdAt,
    this.manualProgress,
  });

  factory GoalModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return GoalModel(
      id: doc.id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: GoalNodeType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => GoalNodeType.goal,
      ),
      parentId: map['parentId'],
      order: ((map['order'] as num?) ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      manualProgress: (map['manualProgress'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'parentId': parentId,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'manualProgress': manualProgress,
    };
  }
}
