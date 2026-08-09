import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/journal_entry_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/journal_analysis_service.dart';
import '../../theme/app_theme.dart';
import 'journal_entry_card.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _firestoreService = FirestoreService();
  final _analysisService = JournalAnalysisService();
  final _textController = TextEditingController();
  bool _saving = false;

  Future<void> _saveEntry(String uid) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    final profile = await _firestoreService.streamUserProfile(uid).first;
    final entryId = await _firestoreService.addJournalEntry(uid, text);
    _textController.clear();
    setState(() => _saving = false);

    unawaited(_analysisService.analyzeEntry(uid, entryId, text, geminiApiKey: profile?.geminiApiKey));
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('ژورنال')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PremiumCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    minLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: 'امروز چطور گذشت؟ آزادانه بنویس...'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : () => _saveEntry(uid),
                    icon: _saving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_saving ? 'در حال ذخیره...' : 'ذخیره و تحلیل'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<JournalEntryModel>>(
              stream: _firestoreService.streamJournalEntries(uid),
              builder: (context, snapshot) {
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(child: Text('هنوز چیزی ننوشته‌ای', style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: entries.map((e) => JournalEntryCard(uid: uid, entry: e, firestoreService: _firestoreService)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
