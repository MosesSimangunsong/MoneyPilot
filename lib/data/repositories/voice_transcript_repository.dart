import 'package:isar/isar.dart';

import '../../core/utils/date_time_utils.dart';
import '../../core/utils/id_generator.dart';
import '../models/voice_transcript.dart';

class VoiceTranscriptRepository {
  VoiceTranscriptRepository(this._isar);

  final Isar _isar;

  Future<VoiceTranscript> createTranscript({
    required String rawText,
    String? parsedType,
    double? parsedAmount,
    String? parsedCategoryUuid,
    required double confidenceScore,
  }) async {
    final VoiceTranscript transcript = VoiceTranscript(
      uuid: IdGenerator.newUuid(),
      rawText: rawText.trim(),
      parsedType: _normalizeNullable(parsedType),
      parsedAmount: parsedAmount,
      parsedCategoryUuid: _normalizeNullable(parsedCategoryUuid),
      confidenceScore: confidenceScore,
      createdAt: DateTimeUtils.utcNow(),
    );

    await _isar.writeTxn(() async {
      await _isar.voiceTranscripts.put(transcript);
    });

    transcript.createdAt = DateTimeUtils.normalizeUtc(transcript.createdAt);
    return transcript;
  }

  Future<VoiceTranscript?> getByUuid(String uuid) {
    return _isar.voiceTranscripts.filter().uuidEqualTo(uuid).findFirst().then((
      VoiceTranscript? transcript,
    ) {
      if (transcript == null) {
        return null;
      }
      transcript.createdAt = DateTimeUtils.normalizeUtc(transcript.createdAt);
      return transcript;
    });
  }

  Future<void> markConverted({
    required String transcriptUuid,
    required String transactionUuid,
  }) async {
    final VoiceTranscript? transcript = await getByUuid(transcriptUuid);
    if (transcript == null) {
      return;
    }

    transcript.convertedToTransaction = true;
    transcript.transactionUuid = transactionUuid;

    await _isar.writeTxn(() async {
      await _isar.voiceTranscripts.put(transcript);
    });
  }

  String? _normalizeNullable(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
