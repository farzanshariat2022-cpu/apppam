import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLogModel {
  final String id;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weightKg;
  final DateTime date;
  final DateTime createdAt;

  WorkoutLogModel({
    required this.id,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.date,
    required this.createdAt,
  });

  factory WorkoutLogModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return WorkoutLogModel(
      id: doc.id,
      exerciseName: map['exerciseName'] ?? '',
      sets: ((map['sets'] as num?) ?? 0).toInt(),
      reps: ((map['reps'] as num?) ?? 0).toInt(),
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get volume => sets * reps * weightKg;
}
