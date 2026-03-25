import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_capture_controller.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';

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
    final expensesState = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyAI'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Describe tu gasto',
                  hintText: 'Ej: Gaste 35 soles en almuerzo',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: captureState.status == CaptureStatus.loading
                      ? null
                      : () async {
                          await ref
                              .read(expenseCaptureControllerProvider.notifier)
                              .submitText(_textController.text);
                          if (mounted &&
                              ref
                                      .read(expenseCaptureControllerProvider)
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
                      : const Text('Procesar y guardar'),
                ),
              ),
              const SizedBox(height: 12),
              _CaptureFeedback(message: captureState.message, status: captureState.status),
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
                      itemBuilder: (context, index) => ExpenseTile(expense: expenses[index]),
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemCount: expenses.length,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
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
        color = Colors.green;
      case CaptureStatus.error:
        color = Colors.red;
      default:
        color = Colors.blueGrey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message!,
        style: TextStyle(color: color),
      ),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: '${expense.currency} ',
      decimalDigits: 2,
    );

    return Card(
      child: ListTile(
        title: Text(amountFormat.format(expense.amount)),
        subtitle: Text('${expense.category} - ${expense.description}'),
        trailing: Text(
          DateFormat('dd/MM HH:mm').format(expense.timestamp.toLocal()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
