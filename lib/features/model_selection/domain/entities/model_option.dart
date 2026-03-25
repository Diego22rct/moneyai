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
    description: 'Reconocimiento de voz del dispositivo. Compatible con Android e iOS.',
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
    description: 'Extraccion financiera con modelo GGUF local.',
  ),
];
