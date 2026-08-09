import 'dart:math';
import 'package:intl/intl.dart';
import 'firestore_service.dart';

class DailyChecksResult {
  final bool isInSlump;
  final String? newAchievementTitle;
  final String? punishmentMessage;

  DailyChecksResult({required this.isInSlump, this.newAchievementTitle, this.punishmentMessage});
}

/// سیستم ضد اهمال‌کاری + Reward & Punishment (بخش‌های ۱۱ و ۱۴ پرامپت).
class GamificationService {
  final FirestoreService _firestore = FirestoreService();
  static const int _studyStreakGoalDays = 20;

  Future<DailyChecksResult> runDailyChecks(String uid) async {
    final isInSlump = await _checkSlump(uid);
    final achievement = await _checkStudyStreakAchievement(uid);
    final punishment = isInSlump ? await _applyPunishmentIfNeeded(uid) : null;

    return DailyChecksResult(
      isInSlump: isInSlump,
      newAchievementTitle: achievement,
      punishmentMessage: punishment,
    );
  }

  Future<bool> _checkSlump(String uid) async {
    final logs = await _firestore.getLastNDaysLogsIncludingToday(uid, 3);
    if (logs.length < 3) return false;
    return logs.every((l) => l.studyMinutes < 30 && l.workoutMinutes < 10);
  }

  Future<String?> _checkStudyStreakAchievement(String uid) async {
    final logs = await _firestore.getLastNDaysLogsIncludingToday(uid, _studyStreakGoalDays);
    if (logs.length < _studyStreakGoalDays) return null;
    final allStudied = logs.every((l) => l.studyMinutes > 0);
    if (!allStudied) return null;

    const achievementId = 'streak_20_study';
    const title = '۲۰ روز مطالعه‌ی پشت‌سرهم 🔥';
    final isNew = await _firestore.unlockAchievementIfNew(
      uid,
      achievementId,
      title,
      'بیست روز پشت‌سرهم حداقل کمی مطالعه کرده‌ای. همینطوری ادامه بده.',
    );
    return isNew ? title : null;
  }

  Future<String?> _applyPunishmentIfNeeded(String uid) async {
    final profile = await _firestore.streamUserProfile(uid).first;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (profile?.lastPunishmentDate != null) {
      final last = DateTime.tryParse(profile!.lastPunishmentDate!);
      if (last != null && DateTime.now().difference(last).inDays < 3) {
        return null; // اخیراً یک‌بار تنبیه شده، دوباره تکرار نمی‌کنیم
      }
    }

    final skills = await _firestore.getAllSkillsOnce(uid);
    if (skills.isEmpty) return null;

    final randomSkill = skills[Random().nextInt(skills.length)];
    final penalty = randomSkill.xp * 0.2;
    if (penalty <= 0) return null;

    await _firestore.applyXpDeltaToSkill(uid, randomSkill.id, -penalty);
    await _firestore.setLastPunishmentDate(uid, today);

    return '۳ روزه به اهداف اصلی نرسیدی — ۲۰٪ از XP «${randomSkill.name}» کم شد.';
  }
}
