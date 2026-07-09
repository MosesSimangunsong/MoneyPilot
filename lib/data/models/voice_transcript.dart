import 'package:isar/isar.dart';

part 'voice_transcript.g.dart';

@collection
class VoiceTranscript {
  VoiceTranscript({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.rawText,
    this.parsedType,
    this.parsedAmount,
    this.parsedCategoryUuid,
    required this.confidenceScore,
    this.convertedToTransaction = false,
    this.transactionUuid,
    required this.createdAt,
  });

  Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String rawText;
  String? parsedType;
  double? parsedAmount;
  String? parsedCategoryUuid;
  late double confidenceScore;
  bool convertedToTransaction;
  String? transactionUuid;

  @Index()
  late DateTime createdAt;
}
