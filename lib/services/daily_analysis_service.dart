import 'package:intl/intl.dart';
import '../models/daily_log_model.dart';
import '../models/briefing_model.dart';
import '../models/habit_model.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';

/// معادل سمت‌کلاینت Cloud Function analyzeDayAndPlanTomorrow (بخش ۱ پرامپت).
class DailyAnalysisService {
  final FirestoreService _firestore = FirestoreService();
  final GeminiService _gemini = GeminiService();

  Future<BriefingModel> ensureTodayBriefing(String uid, {String? geminiApiKey}) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existing = await _firestore.getBriefing(uid, today);
    if (existing != null) return existing;
    return regenerateTodayBriefing(uid, geminiApiKey: geminiApiKey);
  }

  Future<BriefingModel> regenerateTodayBriefing(String uid, {String? geminiApiKey}) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday =
        DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    final yesterdayLog = await _firestore.getLogForDate(uid, yesterday);
    final prevLogs = await _firestore.getPreviousDaysLogs(uid, yesterday, 7);
    final yesterdayScreenTime = await _firestore.getScreenTimeForDate(uid, yesterday);
    final habits = await _firestore.getAllHabitsOnce(uid);
    final failedHabits = habits.where((h) => h.failedLast3Days).toList();

    final analysis =
        _computeDeviations(yesterdayLog, prevLogs, yesterdayScreenTime?.topApp?.appName);
    final templateText = _buildTemplateText(analysis, failedHabits);

    String finalText = templateText;
    bool aiGenerated = false;

    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      final aiText =
          await _gemini.generateText(apiKey: geminiApiKey, prompt: _buildPrompt(analysis, failedHabits));
      if (aiText != null && aiText.isNotEmpty) {
        finalText = aiText;
        aiGenerated = true;
      }
    }

    final briefing = BriefingModel(
      date: today,
      summaryText: finalText,
      generatedAt: DateTime.now(),
      isAiGenerated: aiGenerated,
    );

    await _firestore.saveBriefing(uid, briefing);
    return briefing;
  }

  _DeviationAnalysis _computeDeviations(
    DailyLogModel yesterday,
    List<DailyLogModel> prevLogs,
    String? topAppName,
  ) {
    double avg(int Function(DailyLogModel) field) {
      if (prevLogs.isEmpty) return 0;
      final sum = prevLogs.fold<int>(0, (acc, l) => acc + field(l));
      return sum / prevLogs.length;
    }

    final avgStudy = avg((l) => l.studyMinutes);
    final avgWorkout = avg((l) => l.workoutMinutes);
    final avgInstagram = avg((l) => l.instagramMinutes);
    final avgScreenTime = avg((l) => l.totalScreenTimeMinutes);

    double? screenTimeChangePercent;
    if (avgScreenTime > 0) {
      screenTimeChangePercent =
          ((yesterday.totalScreenTimeMinutes - avgScreenTime) / avgScreenTime) * 100;
    }

    return _DeviationAnalysis(
      yesterday: yesterday,
      avgStudyMinutes: avgStudy,
      avgWorkoutMinutes: avgWorkout,
      avgInstagramMinutes: avgInstagram,
      avgScreenTimeMinutes: avgScreenTime,
      screenTimeChangePercent: screenTimeChangePercent,
      topAppName: topAppName,
      studyDropped: avgStudy > 0 && yesterday.studyMinutes < avgStudy * 0.7,
      workoutMissed: yesterday.workoutMinutes < 10,
      instagramSpiked: avgInstagram > 0 && yesterday.instagramMinutes > avgInstagram * 1.3,
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m دقیقه';
    if (m == 0) return '$h ساعت';
    return '$h ساعت و $m دقیقه';
  }

  String _buildPrompt(_DeviationAnalysis a, List<HabitModel> failedHabits) {
    final habitWarning = failedHabits.isEmpty
        ? ''
        : '\nهشدار عادت: فرزان این عادت‌ها را ۳ روز پشت‌سرهم انجام نداده: '
            '${failedHabits.map((h) => h.title).join('، ')}. حتما در پیامت به این هم اشاره کن.';

    final screenTimeLine = a.screenTimeChangePercent == null
        ? '- استفاده کل از گوشی: ${_formatMinutes(a.yesterday.totalScreenTimeMinutes)}'
        : '- استفاده کل از گوشی: ${_formatMinutes(a.yesterday.totalScreenTimeMinutes)} '
            '(${a.screenTimeChangePercent!.abs().toStringAsFixed(0)}٪ '
            '${a.screenTimeChangePercent! >= 0 ? 'بیشتر' : 'کمتر'} از میانگین ۷ روز اخیرش)'
            '${a.topAppName != null ? '، بیشترین استفاده از ${a.topAppName}' : ''}';

    return '''
تو دستیار شخصی و کوچ سخت‌گیر ولی دلسوز «فرزان» هستی، دانشجوی دامپزشکی ۲۲ ساله با شخصیت ENTP.
داده‌های دیروز فرزان:
- مطالعه: ${a.yesterday.studyMinutes} دقیقه (میانگین ۷ روز قبل: ${a.avgStudyMinutes.toStringAsFixed(0)} دقیقه)
- ورزش: ${a.yesterday.workoutMinutes} دقیقه (میانگین: ${a.avgWorkoutMinutes.toStringAsFixed(0)} دقیقه)
- اینستاگرام: ${a.yesterday.instagramMinutes} دقیقه (میانگین: ${a.avgInstagramMinutes.toStringAsFixed(0)} دقیقه)
$screenTimeLine
$habitWarning

یک پیام کوتاه (حداکثر ۴ جمله)، صادقانه، مستقیم و تاکتیکی به فارسی برای امروز فرزان بنویس.
حتماً استفاده کل از گوشی رو نسبت به میانگین هفته‌اش مقایسه کن (دقیقاً با فرمتی مثل: «امروز ۵
ساعت و ۲۰ دقیقه از گوشی استفاده کردی. ۴۰ درصد بیشتر از میانگین هفته بوده.»). اگر افت مطالعه
مربوط به اینستاگرام بود، صریح بگو. یک اقدام مشخص و عملی برای امروز پیشنهاد بده (مثلا گذاشتن
گوشی جای خاص، یا یک جلسه کوتاه ورزش سبک). لحن باید مثل یک مربی واقعی باشد، نه یک ربات مهربان
بی‌خاصیت. مستقیم خطاب به او صحبت کن.
''';
  }

  String _buildTemplateText(_DeviationAnalysis a, List<HabitModel> failedHabits) {
    final buffer = StringBuffer();

    buffer.write('دیروز ${a.yesterday.studyMinutes} دقیقه مطالعه کردی');
    if (a.avgStudyMinutes > 0) {
      buffer.write(' (میانگین هفته‌ات ${a.avgStudyMinutes.toStringAsFixed(0)} دقیقه بود). ');
    } else {
      buffer.write('. ');
    }

    if (a.screenTimeChangePercent != null) {
      final direction = a.screenTimeChangePercent! >= 0 ? 'بیشتر' : 'کمتر';
      buffer.write(
        'امروز ${_formatMinutes(a.yesterday.totalScreenTimeMinutes)} از گوشی استفاده کردی. '
        '${a.screenTimeChangePercent!.abs().toStringAsFixed(0)} درصد $direction از میانگین هفته بوده'
        '${a.topAppName != null ? '، بیشترینش هم ${a.topAppName}' : ''}. ',
      );
    } else if (a.yesterday.totalScreenTimeMinutes > 0) {
      buffer.write('امروز ${_formatMinutes(a.yesterday.totalScreenTimeMinutes)} از گوشی استفاده کردی. ');
    }

    if (a.instagramSpiked && a.studyDropped) {
      buffer.write(
        'اینستاگرامت (${a.yesterday.instagramMinutes} دقیقه) خیلی بالاتر از حد معمول بود؛ '
        'به‌احتمال زیاد همین باعث افت مطالعه شده. ',
      );
    }

    if (a.workoutMissed) {
      buffer.write('ورزش هم امروز اصلا نبود یا خیلی کم بود. ');
    }

    buffer.write('برای امروز: ');
    if (a.studyDropped) {
      buffer.write('گوشی رو یه جای دور از دسترس بذار تا حداقل ${a.avgStudyMinutes.toStringAsFixed(0)} '
          'دقیقه بدون وقفه مطالعه کنی. ');
    }
    if (a.workoutMissed) {
      buffer.write('یه جلسه ۱۵ دقیقه‌ای سبک ورزش هم برنامه امروزت باشه.');
    }

    if (failedHabits.isNotEmpty) {
      buffer.write(
        '\n⚠️ عادت${failedHabits.length > 1 ? '‌های' : ''} '
        '${failedHabits.map((h) => '«${h.title}»').join('، ')} '
        'رو ۳ روز پشت‌سرهم جا انداختی. امروز همین رو بشکن.',
      );
    }

    return buffer.toString().trim();
  }
}

class _DeviationAnalysis {
  final DailyLogModel yesterday;
  final double avgStudyMinutes;
  final double avgWorkoutMinutes;
  final double avgInstagramMinutes;
  final double avgScreenTimeMinutes;
  final double? screenTimeChangePercent;
  final String? topAppName;
  final bool studyDropped;
  final bool workoutMissed;
  final bool instagramSpiked;

  _DeviationAnalysis({
    required this.yesterday,
    required this.avgStudyMinutes,
    required this.avgWorkoutMinutes,
    required this.avgInstagramMinutes,
    required this.avgScreenTimeMinutes,
    required this.screenTimeChangePercent,
    required this.topAppName,
    required this.studyDropped,
    required this.workoutMissed,
    required this.instagramSpiked,
  });
}
