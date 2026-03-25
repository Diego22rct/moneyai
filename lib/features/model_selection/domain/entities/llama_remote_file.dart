class LlamaRemoteFile {
  const LlamaRemoteFile({
    required this.modelId,
    required this.fileName,
    this.sizeBytes,
  });

  final String modelId;
  final String fileName;
  final int? sizeBytes;

  Uri get downloadUri {
    final List<String> segments = <String>[
      ...modelId.split('/'),
      'resolve',
      'main',
      ...fileName.split('/'),
    ];

    return Uri.https('huggingface.co', segments.join('/'));
  }

  String get uniqueKey => '$modelId::$fileName';

  String get prettySize {
    if (sizeBytes == null || sizeBytes! <= 0) {
      return 'Tamano no disponible';
    }

    final double mb = sizeBytes! / (1024 * 1024);
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    final double gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
