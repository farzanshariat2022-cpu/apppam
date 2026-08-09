import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogModel {
  final String date;
  final int studyMinutes;
  final int workoutMinutes;
  final int totalScreenTimeMinutes;
  final int instagramMinutes;
  final int youtubeMinutes;
  final double? sleepHours;
  final double? bedTimeHour;
  final double? wakeTimeHour;
  final int? moodScore;
  final double xpEarned;
  final bool journalWritten;

  DailyLogModel({
    required this.date,
    this.studyMinutes = 0,
    this.workoutMinutes = 0,
    this.totalScreenTimeMinutes = 0,
    this.instagramMinutes = 0,
    this.youtubeMinutes = 0,
    this.sleepHours,
    this.bedTimeHour,
    this.wakeTimeHour,
    this.moodScore,
    this.xpEarned = 0,
    this.journalWritten = false,
  });

  factory DailyLogModel.empty(String date) => DailyLogModel(date: date);

  factory DailyLogModel.fromMap(String date, Map<String, dynamic> map) {
    return DailyLogModel(
      date: date,
      studyMinutes: ((map['studyMinutes'] as num?) ?? 0).toInt(),
      workoutMinutes: ((map['workoutMinutes'] as num?) ?? 0).toInt(),
      totalScreenTimeMinutes: ((map['totalScreenTimeMinutes'] as num?) ?? 0).toInt(),
      instagramMinutes: ((map['instagramMinutes'] as num?) ?? 0).toInt(),
      youtubeMinutes: ((map['youtubeMinutes'] as num?) ?? 0).toInt(),
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      bedTimeHour: (map['bedTimeHour'] as num?)?.toDouble(),
      wakeTimeHour: (map['wakeTimeHour'] as num?)?.toDouble(),
      moodScore: (map['moodScore'] as num?)?.toInt(),
      xpEarned: (map['xpEarned'] as num?)?.toDouble() ?? 0,
      journalWritten: map['journalWritten'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studyMinutes': studyMinutes,
      'workoutMinutes': workoutMinutes,
      'totalScreenTimeMinutes': totalScreenTimeMinutes,
      'instagramMinutes': instagramMinutes,
      'youtubeMinutes': youtubeMinutes,
      'sleepHours': sleepHours,
      'bedTimeHour': bedTimeHour,
      'wakeTimeHour': wakeTimeHour,
      'moodScore': moodScore,
      'xpEarned': xpEarned,
      'journalWritten': journalWritten,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
