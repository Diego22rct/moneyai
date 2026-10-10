import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/model_selection/data/services/huggingface_llama_service.dart';
import 'package:moneyai/features/model_selection/domain/entities/llama_remote_file.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';
import 'package:moneyai/features/model_selection/presentation/providers/model_selector_provider.dart';

class ModelDownloadState {
  const ModelDownloadState({
    this.query = '',
    this.results = const <LlamaRemoteFile>[],
    this.isSearching = false,
    this.isDownloading = false,
    this.progress = 0,
    this.statusMessage,
    this.errorMessage,
    this.activeFilePath,
  });

  final String query;
  final List<LlamaRemoteFile> results;
  final bool isSearching;
  final bool isDownloading;
  final double progress;
  final String? statusMessage;
  final String? errorMessage;
  final String? activeFilePath;

  ModelDownloadState copyWith({
    String? query,
    List<LlamaRemoteFile>? results,
    bool? isSearching,
    bool? isDownloading,
    double? progress,
    String? statusMessage,
    String? errorMessage,
    String? activeFilePath,
    bool clearStatus = false,
    bool clearError = false,
  }) {
    return ModelDownloadState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeFilePath: activeFilePath ?? this.activeFilePath,
    );
  }
}

final huggingFaceLlamaServiceProvider = Provider<HuggingFaceLlamaService>((
  ref,
) {
  return const HuggingFaceLlamaService();
});

final modelDownloadControllerProvider =
    StateNotifierProvider<ModelDownloadController, ModelDownloadState>(
      (ref) => ModelDownloadController(ref),
    );

class ModelDownloadController extends StateNotifier<ModelDownloadState> {
  ModelDownloadController(this._ref) : super(const ModelDownloadState());

  final Ref _ref;

  Future<void> loadCurrentPath() async {
    final String? current = await _ref
        .read(aiRuntimeConfigLocalDataSourceProvider)
        .getModelPath(AiTask.nlu);
    state = state.copyWith(activeFilePath: current);
  }

  Future<void> search(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        query: '',
        results: const <LlamaRemoteFile>[],
        clearError: true,
        clearStatus: true,
      );
      return;
    }

    state = state.copyWith(
      query: trimmed,
      isSearching: true,
      clearError: true,
      clearStatus: true,
    );

    try {
      final List<LlamaRemoteFile> files = await _ref
          .read(huggingFaceLlamaServiceProvider)
          .searchGgufFiles(trimmed);

      state = state.copyWith(
        isSearching: false,
        results: files,
        statusMessage: files.isEmpty
            ? 'No se encontraron archivos GGUF para "$trimmed".'
            : null,
      );
    } on FormatException catch (error) {
      state = state.copyWith(isSearching: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'No se pudo buscar modelos en este momento.',
      );
    }
  }

  Future<void> downloadAndActivate(LlamaRemoteFile file) async {
    if (state.isDownloading) {
      return;
    }

    state = state.copyWith(
      isDownloading: true,
      progress: 0,
      clearError: true,
      statusMessage: 'Descargando ${file.fileName}...',
    );

    try {
      final String localPath = await _ref
          .read(huggingFaceLlamaServiceProvider)
          .downloadGguf(
            file: file,
            onProgress: (received, total) {
              final double ratio = total == null || total <= 0
                  ? 0
                  : (received / total).clamp(0, 1);
              state = state.copyWith(progress: ratio);
            },
          );

      await _ref
          .read(aiRuntimeConfigLocalDataSourceProvider)
          .setModelPath(task: AiTask.nlu, path: localPath);

      await _ref
          .read(modelConfigLocalDataSourceProvider)
          .setActiveModel(task: AiTask.nlu, modelId: 'llama_local');

      _ref.invalidate(nluModelPathProvider);
      _ref.invalidate(activeNluModelProvider);

      state = state.copyWith(
        isDownloading: false,
        progress: 1,
        activeFilePath: localPath,
        statusMessage: 'Modelo descargado y activado correctamente.',
      );
    } on FormatException catch (error) {
      state = state.copyWith(isDownloading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isDownloading: false,
        errorMessage: 'No se pudo completar la descarga del modelo.',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearStatus: true);
  }
}
