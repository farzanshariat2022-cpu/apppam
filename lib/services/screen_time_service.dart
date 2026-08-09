import 'package:usage_stats/usage_stats.dart';
import 'package:intl/intl.dart';
import '../models/app_usage_model.dart';
import '../models/screen_time_model.dart';
import 'firestore_service.dart';

/// خواندن کاملاً خودکار اسکرین‌تایم از UsageStatsManager اندروید.
class ScreenTimeService {
  final FirestoreService _firestore = FirestoreService();

  static const Map<String, String> _knownApps = {
    'com.instagram.android': 'Instagram',
    'org.telegram.messenger': 'Telegram',
    'com.google.android.youtube': 'YouTube',
    'com.android.chrome': 'Chrome',
    'com.whatsapp': 'WhatsApp',
    'com.twitter.android': 'X (Twitter)',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.snapchat.android': 'Snapchat',
    'com.spotify.music': 'Spotify',
    'com.google.android.gm': 'Gmail',
    'com.google.android.apps.maps': 'Google Maps',
    'com.android.vending': 'Play Store',
    'com.google.android.googlequicksearchbox': 'Google',
    'com.facebook.katana': 'Facebook',
    'com.discord': 'Discord',
    'com.linkedin.android': 'LinkedIn',
    'com.reddit.frontpage': 'Reddit',
    'com.google.android.apps.docs': 'Google Docs',
    'com.microsoft.office.outlook': 'Outlook',
  };

  Future<bool> checkPermission() async {
    final granted = await UsageStats.checkUsagePermission();
    return granted ?? false;
  }

  Future<void> openUsageAccessSettings() async {
    await UsageStats.grantUsagePermission();
  }

  String _resolveAppName(String packageName) {
    if (_knownApps.containsKey(packageName)) return _knownApps[packageName]!;
    return _prettifyPackageName(packageName);
  }

  String _prettifyPackageName(String packageName) {
    final parts = packageName.split('.');
    if (parts.isEmpty) return packageName;
    final last = parts.last;
    if (last.isEmpty) return packageName;
    return last[0].toUpperCase() + last.substring(1);
  }

  Future<ScreenTimeModel> fetchUsageForRange(DateTime start, DateTime end) async {
    final usageStats = await UsageStats.queryUsageStats(start, end);
    final events = await UsageStats.queryEvents(start, end);

    final launchCounts = <String, int>{};
    for (final e in events) {
      if (e.packageName == null) continue;
      if (e.eventType == '1' || e.eventType == 'MOVE_TO_FOREGROUND') {
        launchCounts[e.packageName!] = (launchCounts[e.packageName!] ?? 0) + 1;
      }
    }

    final apps = <AppUsageModel>[];
    int totalMinutes = 0;

    for (final info in usageStats) {
      final packageName = info.packageName;
      if (packageName == null) continue;

      final durationMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      final durationMinutes = durationMs ~/ 60000;
      if (durationMinutes <= 0) continue;

      final lastUsedMs = int.tryParse(info.lastTimeUsed ?? '0') ?? 0;

      apps.add(AppUsageModel(
        packageName: packageName,
        appName: _resolveAppName(packageName),
        durationMinutes: durationMinutes,
        launchCount: launchCounts[packageName] ?? 0,
        lastUsed: lastUsedMs > 0 ? DateTime.fromMillisecondsSinceEpoch(lastUsedMs) : null,
      ));

      totalMinutes += durationMinutes;
    }

    apps.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));

    return ScreenTimeModel(
      date: DateFormat('yyyy-MM-dd').format(start),
      totalMinutes: totalMinutes,
      apps: apps,
      updatedAt: DateTime.now(),
    );
  }

  Future<ScreenTimeModel> fetchTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return fetchUsageForRange(startOfDay, now);
  }

  Future<ScreenTimeModel?> syncToday(String uid) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    final screenTime = await fetchTodayUsage();
    await _firestore.saveScreenTimeDocument(uid, screenTime);

    int findMinutesFor(String packageName) {
      final match = screenTime.apps.where((a) => a.packageName == packageName);
      return match.isEmpty ? 0 : match.first.durationMinutes;
    }

    await _firestore.upsertTodayLog(uid, {
      'totalScreenTimeMinutes': screenTime.totalMinutes,
      'instagramMinutes': findMinutesFor('com.instagram.android'),
      'youtubeMinutes': findMinutesFor('com.google.android.youtube'),
    });

    return screenTime;
  }
}
