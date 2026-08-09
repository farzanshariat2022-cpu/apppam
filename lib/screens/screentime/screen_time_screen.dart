import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_usage_model.dart';
import '../../models/daily_log_model.dart';
import '../../models/screen_time_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_theme.dart';

/// صفحه اسکرین‌تایم خودکار: خواندن مستقیم از Android UsageStatsManager،
/// بدون هیچ ورود دستی. اگر مجوز Usage Access فعال نباشد، کاربر را به همان
/// صفحه‌ی تنظیمات اندروید هدایت می‌کند.
class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});
  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> with WidgetsBindingObserver {
  final _screenTimeService = ScreenTimeService();
  final _firestoreService = FirestoreService();

  bool? _hasPermission;
  ScreenTimeModel? _screenTime;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAndSync();
  }

  Future<void> _checkAndSync() async {
    final granted = await _screenTimeService.checkPermission();
    if (!mounted) return;
    setState(() => _hasPermission = granted);
    if (granted) await _syncNow();
  }

  Future<void> _syncNow() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    setState(() => _syncing = true);
    try {
      final result = await _screenTimeService.syncToday(uid);
      if (mounted && result != null) setState(() => _screenTime = result);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اسکرین‌تایم'),
        actions: [
          if (_hasPermission == true)
            IconButton(
              icon: _syncing
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: _syncing ? null : _syncNow,
            ),
        ],
      ),
      body: _buildBody(uid),
    );
  }

  Widget _buildBody(String uid) {
    if (_hasPermission == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_hasPermission == false) return _buildPermissionRequest();

    return RefreshIndicator(
      onRefresh: _syncNow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTodaySummary(),
          const SizedBox(height: 20),
          const Text('روند ۷ روز اخیر', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<List<DailyLogModel>>(
            stream: _firestoreService.streamLast7DaysLogs(uid),
            builder: (context, snapshot) => _buildTrendChart(snapshot.data ?? []),
          ),
          const SizedBox(height: 20),
          const Text('روند ۳۰ روز اخیر', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<DailyLogModel>>(
            future: _firestoreService.getLastNDaysLogsIncludingToday(uid, 30),
            builder: (context, snapshot) => _buildTrendChart(snapshot.data ?? [], compact: true),
          ),
          const SizedBox(height: 20),
          const Text('استفاده از هر اپ (امروز)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._buildAppList(),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phonelink_lock, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            const Text('برای خواندن خودکار اسکرین‌تایم، معمار به مجوز «Usage Access» نیاز دارد',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'این یک مجوز ویژه‌ی اندرویدی است که فقط از صفحه‌ی تنظیمات سیستم قابل‌فعال‌سازی است. '
              'روی دکمه بزن، از لیست اپ‌ها «معمار» را پیدا کن و روشنش کن، بعد به اینجا برگرد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.7),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => _screenTimeService.openUsageAccessSettings(), child: const Text('رفتن به تنظیمات Usage Access')),
            const SizedBox(height: 12),
            TextButton(onPressed: _checkAndSync, child: const Text('بررسی دوباره', style: TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    final st = _screenTime;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مجموع امروز', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(st?.formattedTotal ?? 'در حال خواندن...', style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
          if (st?.topApp != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('بیشترین استفاده: ${st!.topApp!.appName} (${st.topApp!.formattedDuration})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<DailyLogModel> logs, {bool compact = false}) {
    if (logs.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: const Text('داده‌ای موجود نیست', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final maxY = logs.map((l) => l.totalScreenTimeMinutes).fold<int>(60, (a, b) => a > b ? a : b);

    return Container(
      height: compact ? 140 : 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: !compact, reservedSize: 30)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !compact,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= logs.length) return const SizedBox.shrink();
                  final date = DateFormat('yyyy-MM-dd').parse(logs[i].date);
                  return Text(DateFormat('MM/dd').format(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9));
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < logs.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                    toY: logs[i].totalScreenTimeMinutes.toDouble(),
                    color: AppColors.primary,
                    width: compact ? 4 : 12,
                    borderRadius: BorderRadius.circular(4)),
              ]),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppList() {
    final apps = _screenTime?.apps ?? [];
    if (apps.isEmpty) {
      return [const Padding(padding: EdgeInsets.all(16), child: Text('هنوز داده‌ای برای امروز نیست', style: TextStyle(color: AppColors.textSecondary)))];
    }
    return apps.map((app) => _buildAppRow(app)).toList();
  }

  Widget _buildAppRow(AppUsageModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.appName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${app.launchCount} بار باز شده${app.lastUsed != null ? ' • آخرین بار ${DateFormat('HH:mm').format(app.lastUsed!)}' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Text(app.formattedDuration, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
