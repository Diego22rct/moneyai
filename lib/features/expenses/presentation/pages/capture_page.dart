import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/pages/review_interpretation_page.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_capture_controller.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:moneyai/features/expenses/presentation/providers/voice_input_controller.dart';

class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key});

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Habla o escribe tu movimiento',
                hintText: 'Ej: Recibi 1200 de salario y 40 de transporte',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: captureState.status == CaptureStatus.loading
                        ? null
                        : () async {
                            await ref
                                .read(expenseCaptureControllerProvider.notifier)
                                .submitText(_textController.text);

                            if (!context.mounted) {
                              return;
                            }

                            final updated = ref.read(expenseCaptureControllerProvider);
                            if (updated.status == CaptureStatus.reviewing) {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ReviewInterpretationPage(),
                                ),
                              );
                            }

                            final finalState = ref.read(expenseCaptureControllerProvider);
                            if (finalState.status == CaptureStatus.success) {
                              _textController.clear();
                            }
                          },
                    icon: captureState.status == CaptureStatus.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_alt),
                    label: const Text('Analizar movimiento'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () async {
                    await ref.read(voiceInputControllerProvider.notifier).toggleListening(
                          onText: (text) {
                            _textController.text = text;
                            _textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _textController.text.length),
                            );
                          },
                        );
                  },
                  icon: Icon(voiceState.isListening ? Icons.stop : Icons.mic),
                  tooltip: voiceState.isListening ? 'Detener grabacion' : 'Hablar ahora',
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
            _CaptureFeedback(message: captureState.message, status: captureState.status),
            const SizedBox(height: 12),
            Expanded(
              child: expensesState.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text('Aun no tienes movimientos registrados.'),
                    );
                  }

                  return ListView.separated(
                    itemBuilder: (context, index) => _ExpenseTile(expense: expenses[index]),
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemCount: expenses.length,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(
                  child: Text('No se pudo cargar la lista de movimientos.'),
                ),
              ),
            ),
          ],
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
      case CaptureStatus.reviewing:
        color = Colors.blue;
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

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = expense.type == TransactionType.income;
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: '${expense.currency} ',
      decimalDigits: 2,
    );

    final String tags = expense.tags.isEmpty ? expense.category : expense.tags.join(' • ');

    return Card(
      child: ListTile(
        title: Text(
          amountFormat.format(expense.amount),
          style: TextStyle(
            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('$tags\n${expense.description}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isIncome ? 'Ingreso' : 'Gasto',
                style: TextStyle(
                  color: isIncome ? Colors.green.shade800 : Colors.red.shade800,
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
        color: Colors.blue.withValues(alpha: 0.08),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.graphic_eq, size: 18, color: Colors.blue),
          SizedBox(width: 8),
          Text('Escuchando... habla ahora'),
        ],
      ),
    );
  }
}
