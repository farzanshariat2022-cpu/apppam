import 'dart:convert';
import '../models/task_model.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';

class SuggestedTask {
  final String title;
  final double xpReward;
  final bool isOptional;
  bool selected;

  SuggestedTask({required this.title, required this.xpReward, this.isOptional = false, this.selected = true});
}

/// برنامه‌ریزی خودکار روزانه («برنامه‌ریزی خودکار» که در پرامپت خواسته شده
/// بود). با دسترسی به اهداف، درس‌های نزدیک به امتحان، مرورهای سررسیدشده و
/// عادت‌های جامانده، یک پیشنهاد ۳ تا ۶ تسکی برای امروز می‌سازد که کاربر
/// می‌تواند تایید/رد کند.
class AiPlannerService {
  final FirestoreService _firestore = FirestoreService();
  final GeminiService _gemini = GeminiService();

  Future<List<SuggestedTask>> generateTodayPlan(String uid, {String? geminiApiKey}) async {
    final rootGoals = await _firestore.streamGoalChildren(uid, null).first;
    final courses = await _firestore.streamCourses(uid).first;
    final dueReviewsCount = await _firestore.getDueReviewsCountOnce(uid);
    final habits = await _firestore.getAllHabitsOnce(uid);
    final laggingHabits = habits.where((h) => h.currentStreak == 0).map((h) => h.title).toList();

    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      return _ruleBasedPlan(dueReviewsCount, laggingHabits, courses.isNotEmpty);
    }

    final goalsText = rootGoals.isEmpty ? 'هنوز ثبت نشده' : rootGoals.map((g) => g.title).join('، ');
    final coursesText = courses.isEmpty
        ? 'هیچ درسی ثبت نشده'
        : courses.map((c) {
            final days = c.daysUntilExam;
            return '${c.title}${days != null ? ' (${days} روز تا امتحان)' : ''}';
          }).join('، ');

    final prompt = '''
تو برنامه‌ریز شخصی «فرزان» هستی، دانشجوی دامپزشکی ۲۲ ساله (ENTP).
اهداف بلندمدتش: $goalsText
درس‌هایش: $coursesText
تعداد مبحث‌های آماده‌ی مرور امروز: $dueReviewsCount
عادت‌هایی که استریکشان صفر است (جامانده): ${laggingHabits.isEmpty ? 'هیچ‌کدام' : laggingHabits.join('، ')}

بر اساس این اطلاعات، ۴ تا ۶ تسک مشخص و عملی برای *امروز* فرزان پیشنهاد بده.
فقط یک JSON array خام برگردان (بدون توضیح اضافه، بدون بک‌تیک)، دقیقاً با این ساختار:
[{"title": "عنوان کوتاه تسک به فارسی", "xpReward": 10, "optional": false}]
اگر مرور سررسیدشده دارد، حتماً یکی از تسک‌ها مرورش باشد. اگر عادت جامانده دارد،
یکی برای برگرداندنش باشد. حداقل یک تسک باید optional:true باشد (یعنی در روزهای
شلوغ می‌شود حذفش کرد).
''';

    final response = await _gemini.generateText(apiKey: geminiApiKey, prompt: prompt);
    if (response == null) return _ruleBasedPlan(dueReviewsCount, laggingHabits, courses.isNotEmpty);

    try {
      final cleaned = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(cleaned) as List;
      final tasks = list.map((item) {
        final map = item as Map<String, dynamic>;
        return SuggestedTask(
          title: (map['title'] ?? 'تسک').toString(),
          xpReward: (map['xpReward'] as num?)?.toDouble() ?? 10,
          isOptional: map['optional'] == true,
        );
      }).toList();
      return tasks.isEmpty ? _ruleBasedPlan(dueReviewsCount, laggingHabits, courses.isNotEmpty) : tasks;
    } catch (_) {
      return _ruleBasedPlan(dueReviewsCount, laggingHabits, courses.isNotEmpty);
    }
  }

  /// برنامه‌ی قالبی بدون AI - وقتی کلید Gemini تنظیم نشده
  List<SuggestedTask> _ruleBasedPlan(int dueReviews, List<String> laggingHabits, bool hasCourses) {
    final tasks = <SuggestedTask>[
      SuggestedTask(title: 'حداقل ۴۵ دقیقه مطالعه‌ی متمرکز', xpReward: 20),
      SuggestedTask(title: '۲۰ دقیقه ورزش سبک', xpReward: 15),
    ];

    if (dueReviews > 0) {
      tasks.add(SuggestedTask(title: 'مرور $dueReviews مبحث سررسیدشده', xpReward: 15));
    }
    for (final habit in laggingHabits.take(2)) {
      tasks.add(SuggestedTask(title: 'برگرداندن عادت «$habit»', xpReward: 10, isOptional: true));
    }
    tasks.add(SuggestedTask(title: '۱۰ دقیقه نوشتن ژورنال', xpReward: 10, isOptional: true));

    return tasks;
  }

  /// افزودن تسک‌های تایید‌شده به عنوان تسک‌های واقعی امروز
  Future<void> commitSelectedTasks(String uid, List<SuggestedTask> tasks) async {
    for (final t in tasks.where((t) => t.selected)) {
      await _firestore.addTask(
        uid,
        TaskModel(
          id: '',
          title: t.title,
          date: DateTime.now(),
          xpReward: t.xpReward,
          isOptional: t.isOptional,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}
