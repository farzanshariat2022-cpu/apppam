import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntryModel {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? dominantEmotion;
  final String? mainTopic;
  final String? recommendation;
  final bool analyzed;

  JournalEntryModel({
    required this.id,
    required this.text,
    required this.createdAt,
    this.dominantEmotion,
    this.mainTopic,
    this.recommendation,
    this.analyzed = false,
  });

  factory JournalEntryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return JournalEntryModel(
      id: doc.id,
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dominantEmotion: map['dominantEmotion'],
      mainTopic: map['mainTopic'],
      recommendation: map['recommendation'],
      analyzed: map['analyzed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'dominantEmotion': dominantEmotion,
      'mainTopic': mainTopic,
      'recommendation': recommendation,
      'analyzed': analyzed,
    };
  }
}
