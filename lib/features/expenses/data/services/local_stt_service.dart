import 'package:moneyai/features/ai_services/domain/services/stt_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class LocalSttService implements SttService {
  final SpeechToText _speechToText = SpeechToText();

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<void> startListening({
    required void Function(String text) onText,
  }) async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw const FormatException(
        'Debes habilitar el permiso de microfono para usar voz.',
      );
    }

    final bool available = await _speechToText.initialize();
    if (!available) {
      throw const FormatException(
        'No se pudo iniciar el reconocimiento de voz en el dispositivo.',
      );
    }

    await _speechToText.listen(
      localeId: 'es_PE',
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          onText(result.recognizedWords);
        }
      },
    );
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}
