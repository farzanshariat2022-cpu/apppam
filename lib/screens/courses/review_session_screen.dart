import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/topic_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({super.key});
  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  final _firestoreService = FirestoreService();
  final Set<String> _justReviewedIds = {};
  String? _lastFeedback;

  Future<void> _submitReview(String uid, TopicModel topic, ReviewQuality quality) async {
    final result = await _firestoreService.submitTopicReview(uid, topic, quality);
    if (!mounted) return;
    setState(() {
      _justReviewedIds.add(topic.id);
      _lastFeedback = '«${topic.title}» ثبت شد — مرور بعدی حدود ${result.intervalDays} روز دیگه (+۵ XP)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('مرور امروز')),
      body: StreamBuilder<List<TopicModel>>(
        stream: _firestoreService.streamDueReviews(uid),
        builder: (context, snapshot) {
          final topics = (snapshot.data ?? []).where((t) => !_justReviewedIds.contains(t.id)).toList();

          return Column(
            children: [
              if (_lastFeedback != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(_lastFeedback!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                ),
              Expanded(
                child: topics.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('🎉 هیچ مروری برای امروز نمونده!\nهمه‌چیز تمیزه.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: topics.length,
                        itemBuilder: (context, i) => _buildReviewCard(uid, topics[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(String uid, TopicModel topic) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(topic.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text('دور مرور ${topic.repetitionCount + 1} • این مبحث رو یادت میاد؟', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: ReviewQuality.values.map((q) {
              final color = switch (q) {
                ReviewQuality.again => AppColors.danger,
                ReviewQuality.hard => AppColors.warning,
                ReviewQuality.good => AppColors.primary,
                ReviewQuality.easy => AppColors.success,
              };
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: () => _submitReview(uid, topic, q),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: Text(q.label, style: TextStyle(color: color, fontSize: 11.5), textAlign: TextAlign.center),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
