import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/core/theme/app_theme.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_capture_controller.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:moneyai/features/expenses/presentation/providers/voice_input_controller.dart';
import 'package:moneyai/features/model_selection/presentation/pages/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(expenseCaptureControllerProvider);
    final voiceState = ref.watch(voiceInputControllerProvider);
    final expensesState = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyAI'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Modelos IA',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Describe tu gasto o ingreso',
                  hintText: 'Ej: Me pagaron 1200 de salario',
                ),
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: captureState.status == CaptureStatus.loading
                          ? null
                          : () async {
                              await ref
                                  .read(
                                    expenseCaptureControllerProvider.notifier,
                                  )
                                  .submitText(_textController.text);
                              if (mounted &&
                                  ref
                                          .read(
                                            expenseCaptureControllerProvider,
                                          )
                                          .status ==
                                      CaptureStatus.success) {
                                _textController.clear();
                              }
                            },
                      child: captureState.status == CaptureStatus.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Procesar movimiento'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () async {
                      await ref
                          .read(voiceInputControllerProvider.notifier)
                          .toggleListening(
                            onText: (text) {
                              _textController.text = text;
                              _textController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _textController.text.length,
                                    ),
                                  );
                            },
                          );
                    },
                    icon: Icon(voiceState.isListening ? Icons.stop : Icons.mic),
                    tooltip: voiceState.isListening ? 'Detener voz' : 'Hablar',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (voiceState.isListening)
                const _ListeningBadge()
              else
                const SizedBox.shrink(),
              if (voiceState.errorMessage != null)
                _CaptureFeedback(
                  message: voiceState.errorMessage,
                  status: CaptureStatus.error,
                )
              else
                const SizedBox.shrink(),
              if (voiceState.isListening || voiceState.errorMessage != null)
                const SizedBox(height: 12),
              _CaptureFeedback(
                message: captureState.message,
                status: captureState.status,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: expensesState.when(
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return const Center(
                        child: Text('Aún no tienes gastos registrados.'),
                      );
                    }
                    return ListView.separated(
                      itemBuilder: (context, index) =>
                          ExpenseTile(expense: expenses[index]),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemCount: expenses.length,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => const Center(
                    child: Text('No se pudo cargar la lista de gastos.'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureFeedback extends StatelessWidget {
  const _CaptureFeedback({required this.message, required this.status});

  final String? message;
  final CaptureStatus status;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const SizedBox.shrink();
    }

    Color color;
    switch (status) {
      case CaptureStatus.success:
        color = AppTheme.secondary;
      case CaptureStatus.error:
        color = AppTheme.danger;
      default:
        color = AppTheme.onSurfaceMuted;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message!, style: TextStyle(color: color)),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = expense.type == TransactionType.income;
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: '${expense.currency} ',
      decimalDigits: 2,
    );

    return Card(
      child: ListTile(
        title: Text(
          amountFormat.format(expense.amount),
          style: TextStyle(
            color: isIncome ? AppTheme.secondary : AppTheme.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('${expense.category} - ${expense.description}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isIncome ? AppTheme.secondary : AppTheme.danger)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isIncome ? 'Ingreso' : 'Gasto',
                style: TextStyle(
                  color: isIncome ? AppTheme.secondary : AppTheme.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM HH:mm').format(expense.timestamp.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningBadge extends StatelessWidget {
  const _ListeningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.graphic_eq, size: 18, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Escuchando... habla ahora'),
        ],
      ),
    );
  }
}
