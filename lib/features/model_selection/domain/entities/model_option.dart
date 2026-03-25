enum AiTask { stt, nlu }

extension AiTaskX on AiTask {
  String get key => name;
}

class ModelOption {
  const ModelOption({
    required this.id,
    required this.title,
    required this.description,
    this.available = true,
  });

  final String id;
  final String title;
  final String description;
  final bool available;
}

const List<ModelOption> kSttModelOptions = <ModelOption>[
  ModelOption(
    id: 'speech_to_text',
    title: 'Speech to Text (device)',
    description: 'Reconocimiento de voz del dispositivo, rapido para MVP.',
  ),
  ModelOption(
    id: 'whisper_tiny_local',
    title: 'Whisper Tiny (local)',
    description: 'Preparado para integracion local de Whisper.',
    available: false,
  ),
];

const List<ModelOption> kNluModelOptions = <ModelOption>[
  ModelOption(
    id: 'regex_local',
    title: 'Regex Local',
    description: 'Parser local robusto y estable.',
  ),
  ModelOption(
    id: 'llama_local',
    title: 'Llama Local',
    description: 'Preparado para extraccion financiera con Llama.',
    available: false,
  ),
];
