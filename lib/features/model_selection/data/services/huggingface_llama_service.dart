import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:moneyai/features/model_selection/domain/entities/llama_remote_file.dart';

class HuggingFaceLlamaService {
  const HuggingFaceLlamaService();

  static const int _maxMobileSizeBytes = 1600 * 1024 * 1024;
  static const int _maxHeadRequests = 10;

  Future<List<LlamaRemoteFile>> searchGgufFiles(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <LlamaRemoteFile>[];
    }

    final Uri uri = Uri.https('huggingface.co', '/api/models', <String, String>{
      'search': trimmed,
      'limit': '30',
      'full': 'true',
      'config': 'false',
      'cardData': 'false',
    });

    final http.Response response = await http.get(uri);
    if (response.statusCode != 200) {
      throw const FormatException('No se pudo consultar Hugging Face.');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Respuesta invalida del catalogo de modelos.');
    }

    final List<LlamaRemoteFile> files = <LlamaRemoteFile>[];

    for (final dynamic item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final String? modelId = item['id'] as String?;
      if (modelId == null || modelId.trim().isEmpty) {
        continue;
      }

      List<dynamic> siblings = (item['siblings'] as List<dynamic>?) ?? <dynamic>[];
      if (siblings.isEmpty) {
        siblings = await _fetchModelSiblings(modelId);
      }

      for (final dynamic sibling in siblings) {
        if (sibling is! Map<String, dynamic>) {
          continue;
        }

        final String? fileName = sibling['rfilename'] as String?;
        if (fileName == null || !fileName.toLowerCase().endsWith('.gguf')) {
          continue;
        }

        files.add(
          LlamaRemoteFile(
            modelId: modelId,
            fileName: fileName,
            sizeBytes: _parseSize(sibling['size']),
          ),
        );
      }
    }

    final List<LlamaRemoteFile> withResolvedSizes = await _resolveMissingSizes(files);
    final List<LlamaRemoteFile> filtered = withResolvedSizes.where(_isMobileFriendly).toList();
    filtered.sort(_compareByMobilePriority);

    return filtered.take(20).toList();
  }

  Future<List<LlamaRemoteFile>> _resolveMissingSizes(List<LlamaRemoteFile> files) async {
    final List<LlamaRemoteFile> resolved = <LlamaRemoteFile>[];
    int requests = 0;

    for (final LlamaRemoteFile file in files) {
      if (file.sizeBytes != null || requests >= _maxHeadRequests) {
        resolved.add(file);
        continue;
      }

      requests++;
      final int? fetchedSize = await _fetchContentLength(file.downloadUri);
      resolved.add(
        LlamaRemoteFile(
          modelId: file.modelId,
          fileName: file.fileName,
          sizeBytes: fetchedSize,
        ),
      );
    }

    return resolved;
  }

  Future<int?> _fetchContentLength(Uri downloadUri) async {
    try {
      final http.Response response = await http.head(downloadUri);
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return null;
      }

      final String? contentLength = response.headers['content-length'];
      if (contentLength == null || contentLength.trim().isEmpty) {
        return null;
      }

      return int.tryParse(contentLength);
    } catch (_) {
      return null;
    }
  }

  bool _isMobileFriendly(LlamaRemoteFile file) {
    final String name = file.fileName.toLowerCase();
    final int? size = file.sizeBytes;

    final bool quantized = name.contains('q2') ||
        name.contains('q3') ||
        name.contains('q4') ||
        name.contains('q5') ||
        name.contains('iq');

    final bool smallerFamily = name.contains('0.5b') ||
        name.contains('1b') ||
        name.contains('1_5b') ||
        name.contains('1.5b') ||
        name.contains('2b') ||
        name.contains('3b');

    if (size != null && size > _maxMobileSizeBytes) {
      return false;
    }

    if (!quantized) {
      return false;
    }

    return size != null || smallerFamily;
  }

  int _compareByMobilePriority(LlamaRemoteFile a, LlamaRemoteFile b) {
    final int rankA = _mobileRank(a);
    final int rankB = _mobileRank(b);

    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }

    final int sizeA = a.sizeBytes ?? _maxMobileSizeBytes;
    final int sizeB = b.sizeBytes ?? _maxMobileSizeBytes;
    return sizeA.compareTo(sizeB);
  }

  int _mobileRank(LlamaRemoteFile file) {
    final String name = file.fileName.toLowerCase();

    if (name.contains('q4_k_m') || name.contains('q4km') || name.contains('q4_0')) {
      return 0;
    }

    if (name.contains('q3') || name.contains('q4')) {
      return 1;
    }

    if (name.contains('q2') || name.contains('q5')) {
      return 2;
    }

    return 3;
  }

  Future<List<dynamic>> _fetchModelSiblings(String modelId) async {
    final Uri detailUri = Uri.https('huggingface.co', '/api/models/$modelId');
    final http.Response detailResponse = await http.get(detailUri);

    if (detailResponse.statusCode != 200) {
      return <dynamic>[];
    }

    final dynamic detailDecoded = jsonDecode(detailResponse.body);
    if (detailDecoded is! Map<String, dynamic>) {
      return <dynamic>[];
    }

    return (detailDecoded['siblings'] as List<dynamic>?) ?? <dynamic>[];
  }

  Future<String> downloadGguf({
    required LlamaRemoteFile file,
    required void Function(int receivedBytes, int? totalBytes) onProgress,
  }) async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final Directory modelDir = Directory(p.join(docsDir.path, 'moneyai_models'));
    await modelDir.create(recursive: true);

    final String safeName = file.modelId.replaceAll('/', '__');
    final String localName = '${safeName}__${p.basename(file.fileName)}';
    final File targetFile = File(p.join(modelDir.path, localName));

    final http.Request request = http.Request('GET', file.downloadUri);
    final http.StreamedResponse response = await request.send();

    if (response.statusCode != 200) {
      throw const FormatException('No se pudo descargar el archivo GGUF.');
    }

    final IOSink sink = targetFile.openWrite();
    int received = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, response.contentLength);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    return targetFile.path;
  }

  int? _parseSize(Object? raw) {
    if (raw is int) {
      return raw;
    }

    if (raw is num) {
      return raw.toInt();
    }

    return null;
  }
}
