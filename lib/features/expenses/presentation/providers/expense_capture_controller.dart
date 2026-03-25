import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';

enum CaptureStatus { idle, loading, success, error }

class ExpenseCaptureState {
  const ExpenseCaptureState({
    this.status = CaptureStatus.idle,
    this.message,
    this.lastSaved,
  });

  final CaptureStatus status;
  final String? message;
  final Expense? lastSaved;

  ExpenseCaptureState copyWith({
    CaptureStatus? status,
    String? message,
    Expense? lastSaved,
  }) {
    return ExpenseCaptureState(
      status: status ?? this.status,
      message: message,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}

final expenseCaptureControllerProvider =
    StateNotifierProvider<ExpenseCaptureController, ExpenseCaptureState>(
  (ref) => ExpenseCaptureController(ref),
);

class ExpenseCaptureController extends StateNotifier<ExpenseCaptureState> {
  ExpenseCaptureController(this._ref) : super(const ExpenseCaptureState());

  final Ref _ref;

  Future<void> submitText(String text) async {
    final String cleaned = text.trim();
    if (cleaned.isEmpty) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: 'Ingresa un gasto para procesar.',
      );
      return;
    }

    state = state.copyWith(status: CaptureStatus.loading, message: null);

    try {
      final expense = await _ref.read(recordTextExpenseProvider).call(cleaned);
      await _ref.read(expenseListProvider.notifier).refreshList();
      state = state.copyWith(
        status: CaptureStatus.success,
        message: 'Gasto registrado correctamente.',
        lastSaved: expense,
      );
    } on FormatException catch (error) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: 'Ocurrió un error inesperado al procesar el gasto.',
      );
    }
  }

  void resetStatus() {
    state = state.copyWith(status: CaptureStatus.idle, message: null);
  }
}
