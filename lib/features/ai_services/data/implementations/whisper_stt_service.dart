import 'package:moneyai/features/ai_services/domain/services/stt_service.dart';

class WhisperSttService implements SttService {
  @override
  bool get isListening => false;

  @override
  Future<void> startListening({required void Function(String text) onText}) {
    throw const FormatException(
      'Whisper Tiny local aun no esta disponible en esta version. Cambia a Speech to Text en configuracion.',
    );
  }

  @override
  Future<void> stopListening() async {}
}
