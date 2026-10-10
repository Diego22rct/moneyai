import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';

enum CaptureStatus { idle, loading, reviewing, success, error }

class MovementDraft {
  const MovementDraft({
    required this.amount,
    required this.currency,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.suggestedTags,
    required this.selectedTags,
  });

  final double amount;
  final String currency;
  final TransactionType type;
  final String description;
  final DateTime timestamp;
  final List<String> suggestedTags;
  final List<String> selectedTags;

  MovementDraft copyWith({
    double? amount,
    String? currency,
    TransactionType? type,
    String? description,
    DateTime? timestamp,
    List<String>? suggestedTags,
    List<String>? selectedTags,
  }) {
    return MovementDraft(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }
}

class ExpenseCaptureState {
  const ExpenseCaptureState({
    this.status = CaptureStatus.idle,
    this.message,
    this.pendingDraft,
    this.lastSaved,
  });

  final CaptureStatus status;
  final String? message;
  final MovementDraft? pendingDraft;
  final Expense? lastSaved;

  ExpenseCaptureState copyWith({
    CaptureStatus? status,
    String? message,
    MovementDraft? pendingDraft,
    Expense? lastSaved,
    bool clearDraft = false,
  }) {
    return ExpenseCaptureState(
      status: status ?? this.status,
      message: message,
      pendingDraft: clearDraft ? null : (pendingDraft ?? this.pendingDraft),
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
        message: 'Ingresa un movimiento para procesar.',
      );
      return;
    }

    state = state.copyWith(
      status: CaptureStatus.loading,
      message: null,
      clearDraft: true,
    );

    try {
      final expense = await _ref
          .read(expenseRepositoryProvider)
          .analyzeMovementFromText(cleaned);
      final List<String> suggested = _buildSuggestedTags(expense);

      state = state.copyWith(
        status: CaptureStatus.reviewing,
        message: 'Revisa la interpretacion antes de registrar.',
        pendingDraft: MovementDraft(
          amount: expense.amount,
          currency: expense.currency,
          type: expense.type,
          description: expense.description,
          timestamp: expense.timestamp,
          suggestedTags: suggested,
          selectedTags: suggested,
        ),
      );
    } on FormatException catch (error) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: error.message,
        clearDraft: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: 'Ocurrio un error inesperado al analizar el movimiento.',
        clearDraft: true,
      );
    }
  }

  void updateDraftDescription(String value) {
    final MovementDraft? draft = state.pendingDraft;
    if (draft == null) {
      return;
    }

    state = state.copyWith(
      pendingDraft: draft.copyWith(description: value),
      status: CaptureStatus.reviewing,
      message: null,
    );
  }

  void updateDraftType(TransactionType type) {
    final MovementDraft? draft = state.pendingDraft;
    if (draft == null) {
      return;
    }

    state = state.copyWith(
      pendingDraft: draft.copyWith(type: type),
      status: CaptureStatus.reviewing,
      message: null,
    );
  }

  void toggleTag(String tag) {
    final MovementDraft? draft = state.pendingDraft;
    if (draft == null) {
      return;
    }

    final String cleaned = tag.trim();
    if (cleaned.isEmpty) {
      return;
    }

    final List<String> tags = List<String>.from(draft.selectedTags);
    final int index = tags.indexWhere(
      (value) => value.toLowerCase() == cleaned.toLowerCase(),
    );

    if (index >= 0) {
      tags.removeAt(index);
    } else {
      tags.add(cleaned);
    }

    state = state.copyWith(
      pendingDraft: draft.copyWith(selectedTags: tags),
      status: CaptureStatus.reviewing,
      message: null,
    );
  }

  void addCustomTag(String tag) {
    final MovementDraft? draft = state.pendingDraft;
    if (draft == null) {
      return;
    }

    final String cleaned = tag.trim();
    if (cleaned.isEmpty) {
      return;
    }

    final bool alreadyExists = draft.suggestedTags.any(
      (value) => value.toLowerCase() == cleaned.toLowerCase(),
    );

    final List<String> suggested = alreadyExists
        ? List<String>.from(draft.suggestedTags)
        : <String>[...draft.suggestedTags, cleaned];

    final bool alreadySelected = draft.selectedTags.any(
      (value) => value.toLowerCase() == cleaned.toLowerCase(),
    );

    final List<String> selected = alreadySelected
        ? List<String>.from(draft.selectedTags)
        : <String>[...draft.selectedTags, cleaned];

    state = state.copyWith(
      pendingDraft: draft.copyWith(
        suggestedTags: suggested,
        selectedTags: selected,
      ),
      status: CaptureStatus.reviewing,
      message: null,
    );
  }

  Future<void> confirmDraft() async {
    final MovementDraft? draft = state.pendingDraft;
    if (draft == null) {
      return;
    }

    final List<String> effectiveTags = draft.selectedTags
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (effectiveTags.isEmpty) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: 'Selecciona al menos una etiqueta para registrar.',
      );
      return;
    }

    state = state.copyWith(
      status: CaptureStatus.loading,
      message: 'Registrando movimiento...',
    );

    try {
      final Expense expense = Expense(
        amount: draft.amount,
        currency: draft.currency,
        type: draft.type,
        description: draft.description,
        category: effectiveTags.first,
        tags: effectiveTags,
        timestamp: draft.timestamp,
      );

      final Expense saved = await _ref
          .read(expenseRepositoryProvider)
          .saveMovement(expense);
      await _ref.read(expenseListProvider.notifier).refreshList();

      final String kind = saved.type == TransactionType.income
          ? 'Ingreso'
          : 'Gasto';
      state = state.copyWith(
        status: CaptureStatus.success,
        message: '$kind registrado correctamente.',
        lastSaved: saved,
        clearDraft: true,
      );
    } on FormatException catch (error) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: CaptureStatus.error,
        message: 'No se pudo registrar el movimiento.',
      );
    }
  }

  void discardDraft() {
    state = state.copyWith(
      status: CaptureStatus.idle,
      message: null,
      clearDraft: true,
    );
  }

  List<String> _buildSuggestedTags(Expense expense) {
    final Set<String> base = <String>{
      expense.category,
      expense.type == TransactionType.income ? 'Ingreso' : 'Gasto',
    };

    return base
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  void resetStatus() {
    state = state.copyWith(
      status: CaptureStatus.idle,
      message: null,
      clearDraft: true,
    );
  }
}
