import 'package:cloud_firestore/cloud_firestore.dart';

enum SkillCategory { knowledge, body, mind, relationships }

extension SkillCategoryLabel on SkillCategory {
  String get label {
    switch (this) {
      case SkillCategory.knowledge:
        return 'دانش';
      case SkillCategory.body:
        return 'بدن';
      case SkillCategory.mind:
        return 'ذهن';
      case SkillCategory.relationships:
        return 'روابط';
    }
  }
}

class SkillModel {
  final String id;
  final String name;
  final SkillCategory category;
  final int level;
  final double xp;
  final double xpPerUnit;
  final String unitLabel;
  final DateTime createdAt;

  SkillModel({
    required this.id,
    required this.name,
    required this.category,
    this.level = 1,
    this.xp = 0,
    required this.xpPerUnit,
    required this.unitLabel,
    required this.createdAt,
  });

  double get xpThreshold => 100.0 * level;
  double get progress => (xp / xpThreshold).clamp(0, 1);

  factory SkillModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return SkillModel(
      id: doc.id,
      name: map['name'] ?? '',
      category: SkillCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => SkillCategory.knowledge,
      ),
      level: ((map['level'] as num?) ?? 1).toInt(),
      xp: (map['xp'] as num?)?.toDouble() ?? 0,
      xpPerUnit: (map['xpPerUnit'] as num?)?.toDouble() ?? 1,
      unitLabel: map['unitLabel'] ?? 'دقیقه',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'level': level,
      'xp': xp,
      'xpPerUnit': xpPerUnit,
      'unitLabel': unitLabel,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
