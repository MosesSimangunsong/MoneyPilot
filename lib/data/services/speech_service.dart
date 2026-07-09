import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) {
    return _speechToText.initialize(
      onStatus: onStatus,
      onError: (error) => onError?.call(error.errorMsg),
    );
  }

  Future<bool> get hasPermission async => _speechToText.hasPermission;

  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stopListening() {
    return _speechToText.stop();
  }

  Future<void> cancelListening() {
    return _speechToText.cancel();
  }
}
