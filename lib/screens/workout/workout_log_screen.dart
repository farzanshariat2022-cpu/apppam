import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/workout_log_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class WorkoutLogScreen extends StatelessWidget {
  const WorkoutLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser!.uid;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('تحلیل ورزش')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddLogDialog(context, uid, firestoreService),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<WorkoutLogModel>>(
        stream: firestoreService.streamWorkoutLogs(uid),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('هنوز حرکتی ثبت نکرده‌ای. با دکمه + یک ست ثبت کن (مثلا «پرس سینه»).',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }

          final grouped = <String, List<WorkoutLogModel>>{};
          for (final log in logs) {
            grouped.putIfAbsent(log.exerciseName, () => []).add(log);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) => _buildExerciseSection(context, uid, entry.key, entry.value, firestoreService)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildExerciseSection(BuildContext context, String uid, String name, List<WorkoutLogModel> logs, FirestoreService firestoreService) {
    logs.sort((a, b) => a.date.compareTo(b.date));
    final last = logs.last;

    bool stagnant = false;
    if (logs.length >= 2) {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      final oldLogs = logs.where((l) => l.date.isBefore(twoWeeksAgo)).toList();
      if (oldLogs.isNotEmpty) {
        final oldVolume = oldLogs.last.volume;
        stagnant = last.volume <= oldVolume;
      }
    }

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      borderColor: stagnant ? AppColors.warning.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
            Text('آخرین: ${last.sets}×${last.reps} @ ${last.weightKg}kg', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ]),
          if (stagnant) ...[
            const SizedBox(height: 6),
            const Text('⚠️ ۲ هفته‌ست پیشرفتی نبوده — شاید وقتشه برنامه رو عوض کنی', style: TextStyle(color: AppColors.warning, fontSize: 11)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (int i = 0; i < logs.length; i++) FlSpot(i.toDouble(), logs[i].weightKg)],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLogDialog(BuildContext context, String uid, FirestoreService firestoreService) {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('ثبت ست جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'نام حرکت (مثلا: پرس سینه)'), autofocus: true),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ست'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'تکرار'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'وزنه (kg)'))),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await firestoreService.addWorkoutLog(
                uid,
                WorkoutLogModel(
                  id: '',
                  exerciseName: name,
                  sets: int.tryParse(setsController.text) ?? 0,
                  reps: int.tryParse(repsController.text) ?? 0,
                  weightKg: double.tryParse(weightController.text) ?? 0,
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }
}
