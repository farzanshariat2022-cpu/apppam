import 'package:flutter/material.dart';
import '../../services/ai_planner_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

/// شیت برنامه‌ریزی خودکار روزانه («برنامه‌ریزی خودکار» که در پرامپت خواسته
/// شده بود). چند تسک پیشنهادی برای امروز نشان می‌دهد؛ کاربر می‌تواند هرکدام
/// را تیک بزند/بردارد و بعد یک‌جا به لیست کارهای امروز اضافه کند.
class AiPlannerSheet extends StatefulWidget {
  final String uid;
  final String? geminiApiKey;
  const AiPlannerSheet({super.key, required this.uid, this.geminiApiKey});

  @override
  State<AiPlannerSheet> createState() => _AiPlannerSheetState();
}

class _AiPlannerSheetState extends State<AiPlannerSheet> {
  final _plannerService = AiPlannerService();
  List<SuggestedTask>? _tasks;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tasks = await _plannerService.generateTodayPlan(widget.uid, geminiApiKey: widget.geminiApiKey);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _commit() async {
    if (_tasks == null) return;
    setState(() => _saving = true);
    await _plannerService.commitSelectedTasks(widget.uid, _tasks!);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('برنامه امروز اضافه شد ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Icon(Icons.auto_fix_high, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('برنامه پیشنهادی امروز', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _tasks?.length ?? 0,
                        itemBuilder: (context, i) {
                          final t = _tasks![i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                            child: CheckboxListTile(
                              value: t.selected,
                              onChanged: (v) => setState(() => t.selected = v ?? true),
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
                              subtitle: Text(
                                '${t.xpReward.toStringAsFixed(0)} XP${t.isOptional ? ' • اختیاری' : ''}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: ElevatedButton(
                  onPressed: (_loading || _saving) ? null : _commit,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('اضافه کن به امروز'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
