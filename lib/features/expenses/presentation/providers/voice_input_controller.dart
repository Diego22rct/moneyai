import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';

class VoiceInputState {
  const VoiceInputState({this.isListening = false, this.errorMessage});

  final bool isListening;
  final String? errorMessage;

  VoiceInputState copyWith({bool? isListening, String? errorMessage}) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      errorMessage: errorMessage,
    );
  }
}

final voiceInputControllerProvider =
    StateNotifierProvider<VoiceInputController, VoiceInputState>(
      (ref) => VoiceInputController(ref),
    );

class VoiceInputController extends StateNotifier<VoiceInputState> {
  VoiceInputController(this._ref) : super(const VoiceInputState());

  final Ref _ref;

  Future<void> startListening({
    required void Function(String text) onText,
  }) async {
    try {
      await _ref.read(sttServiceProvider).startListening(onText: onText);
      state = state.copyWith(isListening: true, errorMessage: null);
    } on FormatException catch (error) {
      state = state.copyWith(isListening: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isListening: false,
        errorMessage: 'No se pudo iniciar la captura por voz.',
      );
    }
  }

  Future<void> stopListening() async {
    await _ref.read(sttServiceProvider).stopListening();
    state = state.copyWith(isListening: false, errorMessage: null);
  }

  Future<void> toggleListening({
    required void Function(String text) onText,
  }) async {
    if (state.isListening) {
      await stopListening();
      return;
    }

    await startListening(onText: onText);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
