import 'dart:convert';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:moneyai/features/ai_services/data/datasources/ai_runtime_config_local_datasource.dart';
import 'package:moneyai/features/ai_services/domain/services/nlu_service.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';

class LlamaNluService implements NluService {
  LlamaNluService(this._runtimeConfig);

  final AiRuntimeConfigLocalDataSource _runtimeConfig;
  LlamaParent? _llamaParent;

  @override
  Future<Map<String, Object>> extractMovement(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Debes ingresar un texto para procesar.');
    }

    try {
      await _ensureLoaded();
      final String prompt = _buildPrompt(trimmed);
      final String raw = await _llamaParent!.sendPrompt(prompt);
      return _parseAndValidate(raw);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'No se pudo ejecutar Llama local. Revisa la ruta del modelo GGUF y la libreria nativa.',
      );
    }
  }

  Future<void> _ensureLoaded() async {
    if (_llamaParent != null) {
      return;
    }

    final String? modelPath = await _runtimeConfig.getModelPath(AiTask.nlu);
    if (modelPath == null || modelPath.trim().isEmpty) {
      throw const FormatException(
        'Configura la ruta del modelo GGUF en Ajustes para usar Llama local.',
      );
    }

    final String? nativeLibPath = await _runtimeConfig.getNativeLibPath(AiTask.nlu);
    if (nativeLibPath != null && nativeLibPath.trim().isNotEmpty) {
      Llama.libraryPath = nativeLibPath;
    }

    final LlamaLoad load = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      contextParams: ContextParams()..nPredict = 256,
      samplingParams: SamplerParams(),
    );

    final LlamaParent parent = LlamaParent(load);
    await parent.init();
    _llamaParent = parent;
  }

  String _buildPrompt(String userText) {
    return '''
Eres MoneyAI.
Extrae un JSON con esta estructura exacta y sin texto adicional:
{"amount": number, "currency": "PEN|USD|EUR", "description": string, "type": "expense|income", "category": string, "timestamp": "ISO8601"}

Reglas:
- Si no hay moneda clara, usa PEN.
- Tipos validos: expense, income.
- Categorias gasto: Comida, Transporte, Ropa, Salud, Entretenimiento, Hogar, Otros.
- Categorias ingreso: Salario, Freelance, Inversiones, Reembolsos, Regalos, Otros.
- timestamp debe estar en formato UTC ISO8601.

Texto del usuario: "$userText"
''';
  }

  Map<String, Object> _parseAndValidate(String raw) {
    final RegExp jsonObjectExp = RegExp(r'\{[\s\S]*\}');
    final RegExpMatch? match = jsonObjectExp.firstMatch(raw);
    if (match == null) {
      throw const FormatException('La respuesta del modelo no contiene JSON valido.');
    }

    final dynamic decoded = jsonDecode(match.group(0)!);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del modelo no tiene el formato esperado.');
    }

    final num? amountNum = decoded['amount'] as num?;
    final String? currency = decoded['currency'] as String?;
    final String? description = decoded['description'] as String?;
    final String? type = decoded['type'] as String?;
    final String? category = decoded['category'] as String?;
    final String? timestamp = decoded['timestamp'] as String?;

    if (amountNum == null ||
        currency == null ||
        description == null ||
        type == null ||
        category == null ||
        timestamp == null) {
      throw const FormatException('La respuesta del modelo esta incompleta.');
    }

    if (type != 'expense' && type != 'income') {
      throw const FormatException('La respuesta del modelo tiene un tipo invalido.');
    }

    DateTime.parse(timestamp);

    return <String, Object>{
      'amount': amountNum.toDouble(),
      'currency': currency,
      'description': description,
      'type': type,
      'category': category,
      'timestamp': timestamp,
    };
  }
}
