import 'package:moneyai/features/ai_services/domain/services/nlu_service.dart';

class LlamaNluService implements NluService {
  @override
  Future<Map<String, Object>> extractMovement(String text) {
    throw const FormatException(
      'El modelo Llama local aun no esta disponible en esta version. Cambia a Regex Local en configuracion.',
    );
  }
}
