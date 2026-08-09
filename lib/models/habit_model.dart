import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HabitModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final Map<String, bool> completedDates;

  HabitModel({
    required this.id,
    required this.title,
    required this.createdAt,
    Map<String, bool>? completedDates,
  }) : completedDates = completedDates ?? {};

  factory HabitModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    final rawDates = map['completedDates'] as Map<String, dynamic>? ?? {};
    return HabitModel(
      id: doc.id,
      title: map['title'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedDates: rawDates.map((k, v) => MapEntry(k, v == true)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates': completedDates,
    };
  }

  bool isCompletedOn(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return completedDates[key] == true;
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  int get currentStreak {
    int streak = 0;
    DateTime cursor = DateTime.now();
    if (!isCompletedOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (isCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get successRatePercent {
    final totalDays = DateTime.now().difference(createdAt).inDays + 1;
    if (totalDays <= 0) return 0;
    final doneDays = completedDates.values.where((v) => v).length;
    return (doneDays / totalDays) * 100;
  }

  bool get failedLast3Days {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    if (createdAt.isAfter(threeDaysAgo)) return false;
    for (int i = 1; i <= 3; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      if (isCompletedOn(day)) return false;
    }
    return true;
  }

  Map<DateTime, int> get heatmapDatasets {
    final result = <DateTime, int>{};
    completedDates.forEach((key, done) {
      if (!done) return;
      try {
        final d = DateFormat('yyyy-MM-dd').parse(key);
        result[DateTime(d.year, d.month, d.day)] = 1;
      } catch (_) {}
    });
    return result;
  }
}
