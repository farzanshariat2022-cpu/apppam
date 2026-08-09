class AppUsageModel {
  final String packageName;
  final String appName;
  final int durationMinutes;
  final int launchCount;
  final DateTime? lastUsed;

  AppUsageModel({
    required this.packageName,
    required this.appName,
    required this.durationMinutes,
    required this.launchCount,
    this.lastUsed,
  });

  factory AppUsageModel.fromMap(String packageName, Map<String, dynamic> map) {
    return AppUsageModel(
      packageName: packageName,
      appName: map['appName'] ?? packageName,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      launchCount: (map['launchCount'] as num?)?.toInt() ?? 0,
      lastUsed: map['lastUsed'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['lastUsed'] as num).toInt())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'durationMinutes': durationMinutes,
      'launchCount': launchCount,
      'lastUsed': lastUsed?.millisecondsSinceEpoch,
    };
  }

  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
