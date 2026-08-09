import 'package:cloud_firestore/cloud_firestore.dart';

enum TopicStatus { notStarted, inProgress, completed }

extension TopicStatusLabel on TopicStatus {
  String get label {
    switch (this) {
      case TopicStatus.notStarted:
        return 'شروع‌نشده';
      case TopicStatus.inProgress:
        return 'در حال انجام';
      case TopicStatus.completed:
        return 'تکمیل‌شده';
    }
  }
}

/// درجه‌ی سختی که کاربر بعد از هر مرور انتخاب می‌کند - معیار الگوریتم SM-2
/// (همان الگوریتمی که Anki و بیشتر اپ‌های مرور فاصله‌دار حرفه‌ای دنیا دارند).
enum ReviewQuality { again, hard, good, easy }

extension ReviewQualityScore on ReviewQuality {
  int get score {
    switch (this) {
      case ReviewQuality.again:
        return 1;
      case ReviewQuality.hard:
        return 3;
      case ReviewQuality.good:
        return 4;
      case ReviewQuality.easy:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case ReviewQuality.again:
        return 'دوباره';
      case ReviewQuality.hard:
        return 'سخت بود';
      case ReviewQuality.good:
        return 'خوب بود';
      case ReviewQuality.easy:
        return 'آسون بود';
    }
  }
}

/// مدل مبحث با سیستم مرور هوشمند SM-2 (بر پایه‌ی سختی + عملکرد + منحنی فراموشی،
/// نه فاصله‌های ثابت).
class TopicModel {
  final String id;
  final String courseId;
  final String chapterId;
  final String title;
  final TopicStatus status;
  final int order;
  final DateTime? completedAt;

  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final DateTime? nextReviewDate;
  final int totalReviews;
  final DateTime createdAt;

  TopicModel({
    required this.id,
    required this.courseId,
    required this.chapterId,
    required this.title,
    this.status = TopicStatus.notStarted,
    this.order = 0,
    this.completedAt,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitionCount = 0,
    this.nextReviewDate,
    this.totalReviews = 0,
    required this.createdAt,
  });

  bool get isDueForReview =>
      nextReviewDate != null && !nextReviewDate!.isAfter(DateTime.now());

  factory TopicModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return TopicModel(
      id: doc.id,
      courseId: map['courseId'] ?? '',
      chapterId: map['chapterId'] ?? '',
      title: map['title'] ?? '',
      status: TopicStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TopicStatus.notStarted,
      ),
      order: ((map['order'] as num?) ?? 0).toInt(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      easeFactor: ((map['easeFactor'] as num?) ?? 2.5).toDouble(),
      intervalDays: ((map['intervalDays'] as num?) ?? 0).toInt(),
      repetitionCount: ((map['repetitionCount'] as num?) ?? 0).toInt(),
      nextReviewDate: (map['nextReviewDate'] as Timestamp?)?.toDate(),
      totalReviews: ((map['totalReviews'] as num?) ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'chapterId': chapterId,
      'title': title,
      'status': status.name,
      'order': order,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'repetitionCount': repetitionCount,
      'nextReviewDate': nextReviewDate != null ? Timestamp.fromDate(nextReviewDate!) : null,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
