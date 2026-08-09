import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_usage_model.dart';

class ScreenTimeModel {
  final String date;
  final int totalMinutes;
  final List<AppUsageModel> apps;
  final DateTime updatedAt;

  ScreenTimeModel({
    required this.date,
    required this.totalMinutes,
    required this.apps,
    required this.updatedAt,
  });

  factory ScreenTimeModel.empty(String date) =>
      ScreenTimeModel(date: date, totalMinutes: 0, apps: [], updatedAt: DateTime.now());

  factory ScreenTimeModel.fromMap(String date, Map<String, dynamic> map) {
    final appsMap = map['apps'] as Map<String, dynamic>? ?? {};
    final apps = appsMap.entries
        .map((e) => AppUsageModel.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
        .toList()
      ..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));

    return ScreenTimeModel(
      date: date,
      totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
      apps: apps,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMinutes': totalMinutes,
      'apps': {for (final a in apps) a.packageName: a.toMap()},
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUsageModel? get topApp => apps.isEmpty ? null : apps.first;

  String get formattedTotal {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '$m دقیقه';
    if (m == 0) return '$h ساعت';
    return '$h ساعت و $m دقیقه';
  }
}
