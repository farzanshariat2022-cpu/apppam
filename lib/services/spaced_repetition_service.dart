import '../models/topic_model.dart';

class SpacedRepetitionResult {
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final DateTime nextReviewDate;

  SpacedRepetitionResult({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    required this.nextReviewDate,
  });
}

/// پیاده‌سازی خالص الگوریتم SM-2 - همان الگوریتمی که Anki و اکثر اپ‌های
/// مرور فاصله‌دار حرفه‌ای دنیا استفاده می‌کنند. بر پایه‌ی سه معیار واقعی کار
/// می‌کند: سختی (کیفیت مروری که کاربر انتخاب می‌کند)، عملکرد قبلی (ease
/// factor که با مرورهای موفق بالا می‌رود)، و فراموشی (اگر «دوباره» بزنی،
/// شمارنده صفر می‌شود - دقیقاً مدل‌سازی منحنی فراموشی ابینگهاوس).
class SpacedRepetitionService {
  static const double _minEaseFactor = 1.3;

  static SpacedRepetitionResult computeNext(TopicModel topic, ReviewQuality quality) {
    final q = quality.score;

    int repetitions = topic.repetitionCount;
    int interval = topic.intervalDays;
    double easeFactor = topic.easeFactor;

    if (q < 3) {
      repetitions = 0;
      interval = 1;
    } else {
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions += 1;
    }

    easeFactor = easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (easeFactor < _minEaseFactor) easeFactor = _minEaseFactor;

    final nextDate = DateTime.now().add(Duration(days: interval));

    return SpacedRepetitionResult(
      easeFactor: double.parse(easeFactor.toStringAsFixed(2)),
      intervalDays: interval,
      repetitionCount: repetitions,
      nextReviewDate: nextDate,
    );
  }

  static SpacedRepetitionResult initial() {
    return SpacedRepetitionResult(
      easeFactor: 2.5,
      intervalDays: 1,
      repetitionCount: 0,
      nextReviewDate: DateTime.now().add(const Duration(days: 1)),
    );
  }
}
