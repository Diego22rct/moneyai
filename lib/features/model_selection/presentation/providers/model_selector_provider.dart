import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/ai_services/data/datasources/ai_runtime_config_local_datasource.dart';
import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/model_selection/data/datasources/model_config_local_datasource.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';

final sqliteServiceForModelProvider = Provider<SQLiteService>((ref) {
  return SQLiteService();
});

final modelConfigLocalDataSourceProvider = Provider<ModelConfigLocalDataSource>((ref) {
  return ModelConfigLocalDataSource(ref.watch(sqliteServiceForModelProvider));
});

final aiRuntimeConfigLocalDataSourceProvider = Provider<AiRuntimeConfigLocalDataSource>((ref) {
  return AiRuntimeConfigLocalDataSource(ref.watch(sqliteServiceForModelProvider));
});

final activeSttModelProvider = FutureProvider<String>((ref) async {
  return ref.read(modelConfigLocalDataSourceProvider).getActiveModelId(AiTask.stt);
});

final activeNluModelProvider = FutureProvider<String>((ref) async {
  return ref.read(modelConfigLocalDataSourceProvider).getActiveModelId(AiTask.nlu);
});

final nluModelPathProvider = FutureProvider<String?>((ref) async {
  return ref.read(aiRuntimeConfigLocalDataSourceProvider).getModelPath(AiTask.nlu);
});

final nluNativeLibPathProvider = FutureProvider<String?>((ref) async {
  return ref.read(aiRuntimeConfigLocalDataSourceProvider).getNativeLibPath(AiTask.nlu);
});

final modelSelectionControllerProvider =
    StateNotifierProvider<ModelSelectionController, AsyncValue<void>>(
  (ref) => ModelSelectionController(ref),
);

final modelRuntimeConfigControllerProvider =
    StateNotifierProvider<ModelRuntimeConfigController, AsyncValue<void>>(
  (ref) => ModelRuntimeConfigController(ref),
);

class ModelSelectionController extends StateNotifier<AsyncValue<void>> {
  ModelSelectionController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> selectModel({required AiTask task, required String modelId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(modelConfigLocalDataSourceProvider).setActiveModel(
            task: task,
            modelId: modelId,
          );

      if (task == AiTask.stt) {
        _ref.invalidate(activeSttModelProvider);
      } else {
        _ref.invalidate(activeNluModelProvider);
      }
    });
  }
}

class ModelRuntimeConfigController extends StateNotifier<AsyncValue<void>> {
  ModelRuntimeConfigController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> setModelPath({required AiTask task, required String? path}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(aiRuntimeConfigLocalDataSourceProvider).setModelPath(
            task: task,
            path: path,
          );

      if (task == AiTask.nlu) {
        _ref.invalidate(nluModelPathProvider);
      }
    });
  }

  Future<void> setNluNativeLibPath(String? path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(aiRuntimeConfigLocalDataSourceProvider).setNativeLibPath(
            task: AiTask.nlu,
            path: path,
          );

      _ref.invalidate(nluNativeLibPathProvider);
    });
  }
}
