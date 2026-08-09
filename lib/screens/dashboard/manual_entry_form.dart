import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

/// فرم ثبت دستی روزانه. نسخه‌ی اصلاح‌شده: قبلاً سه فیلد جدا برای خواب بود
/// (عدد + دو فیلد متنی HH:mm) که هم گیج‌کننده بود و هم چون کیبورد پیش‌فرض
/// اجازه‌ی تایپ ":" نمی‌داد، دکمه‌ی ذخیره عملاً کار نمی‌کرد. حالا فقط دو
/// دکمه‌ی Time Picker واقعی داریم و ساعت خواب خودش محاسبه می‌شود.
class ManualEntryForm extends StatefulWidget {
  final String uid;
  final FirestoreService firestoreService;
  const ManualEntryForm({super.key, required this.uid, required this.firestoreService});

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _studyController = TextEditingController();
  final _workoutController = TextEditingController();
  TimeOfDay? _bedTime;
  TimeOfDay? _wakeTime;
  int? _moodScore;
  bool _saving = false;

  @override
  void dispose() {
    _studyController.dispose();
    _workoutController.dispose();
    super.dispose();
  }

  double? get _computedSleepHours {
    if (_bedTime == null || _wakeTime == null) return null;
    final bedMinutes = _bedTime!.hour * 60 + _bedTime!.minute;
    var wakeMinutes = _wakeTime!.hour * 60 + _wakeTime!.minute;
    if (wakeMinutes <= bedMinutes) wakeMinutes += 24 * 60;
    return (wakeMinutes - bedMinutes) / 60;
  }

  Future<void> _pickTime(bool isBedTime) async {
    final initial = (isBedTime ? _bedTime : _wakeTime) ?? TimeOfDay(hour: isBedTime ? 23 : 7, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBedTime) {
          _bedTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'studyMinutes': int.tryParse(_studyController.text) ?? 0,
      'workoutMinutes': int.tryParse(_workoutController.text) ?? 0,
    };
    if (_bedTime != null) data['bedTimeHour'] = _bedTime!.hour + (_bedTime!.minute / 60);
    if (_wakeTime != null) data['wakeTimeHour'] = _wakeTime!.hour + (_wakeTime!.minute / 60);
    if (_computedSleepHours != null) data['sleepHours'] = _computedSleepHours;
    if (_moodScore != null) data['moodScore'] = _moodScore;

    try {
      await widget.firestoreService.upsertTodayLog(widget.uid, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ثبت شد ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.danger, content: Text('ثبت نشد: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatTime(TimeOfDay? t) => t == null ? '—' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ثبت دستی امروز', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _studyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'دقایق مطالعه'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _workoutController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'دقایق ورزش'))),
          ]),
          const SizedBox(height: 14),
          const Text('خواب دیشب', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _TimePickerButton(
                    icon: Icons.bedtime_outlined, label: 'ساعت خواب', value: _formatTime(_bedTime), onTap: () => _pickTime(true))),
            const SizedBox(width: 10),
            Expanded(
                child: _TimePickerButton(
                    icon: Icons.wb_sunny_outlined,
                    label: 'ساعت بیداری',
                    value: _formatTime(_wakeTime),
                    onTap: () => _pickTime(false))),
          ]),
          if (_computedSleepHours != null) ...[
            const SizedBox(height: 8),
            Text('مجموع خواب: ${_computedSleepHours!.toStringAsFixed(1)} ساعت',
                style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          const Text('خلق‌وخو امروز', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final score = (i + 1) * 2;
              const emojis = ['😞', '😕', '😐', '🙂', '😄'];
              final selected = _moodScore == score;
              return GestureDetector(
                onTap: () => setState(() => _moodScore = score),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceLight, width: selected ? 2 : 1),
                  ),
                  child: Text(emojis[i], style: const TextStyle(fontSize: 20)),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimePickerButton({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
