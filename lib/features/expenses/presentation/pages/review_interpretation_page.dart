import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/core/theme/app_theme.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_capture_controller.dart';
import 'package:moneyai/features/expenses/presentation/providers/voice_input_controller.dart';

class ReviewInterpretationPage extends ConsumerStatefulWidget {
  const ReviewInterpretationPage({super.key});

  @override
  ConsumerState<ReviewInterpretationPage> createState() => _ReviewInterpretationPageState();
}

class _ReviewInterpretationPageState extends ConsumerState<ReviewInterpretationPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(expenseCaptureControllerProvider).pendingDraft;
    _descriptionController.text = draft?.description ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseCaptureControllerProvider);
    final voiceState = ref.watch(voiceInputControllerProvider);
    final draft = state.pendingDraft;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revision de interpretacion')),
        body: const Center(child: Text('No hay analisis pendiente.')),
      );
    }

    final NumberFormat amountFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: '${draft.currency} ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision de interpretacion'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: <Widget>[
              Text(
                'Confirma si es ingreso o gasto, ajusta texto y etiquetas antes de registrar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Monto detectado', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        amountFormat.format(draft.amount),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(draft.timestamp.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<TransactionType>(
                segments: const <ButtonSegment<TransactionType>>[
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text('Gasto'),
                    icon: Icon(Icons.trending_down),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text('Ingreso'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: <TransactionType>{draft.type},
                onSelectionChanged: (selection) {
                  final selected = selection.first;
                  ref.read(expenseCaptureControllerProvider.notifier).updateDraftType(selected);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Texto interpretado',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ref.read(expenseCaptureControllerProvider.notifier).updateDraftDescription(value);
                },
              ),
              const SizedBox(height: 12),
              Text('Etiquetas', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: draft.suggestedTags.map((tag) {
                  final bool selected = draft.selectedTags
                      .any((value) => value.toLowerCase() == tag.toLowerCase());
                  return FilterChip(
                    selected: selected,
                    onSelected: (_) {
                      ref.read(expenseCaptureControllerProvider.notifier).toggleTag(tag);
                    },
                    label: Text(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Nueva etiqueta',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (voiceState.isListening)
                const _InlineInfoCard(message: 'Escuchando... toca detener y luego Analizar.'),
              if (state.message != null && state.status == CaptureStatus.error)
                _InlineErrorCard(message: state.message!),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(voiceInputControllerProvider.notifier).toggleListening(
                              onText: (text) {
                                _descriptionController.text = text;
                                ref
                                    .read(expenseCaptureControllerProvider.notifier)
                                    .updateDraftDescription(text);
                              },
                            );
                      },
                      icon: Icon(voiceState.isListening ? Icons.stop : Icons.mic),
                      label: Text(
                        voiceState.isListening ? 'Detener grabacion' : 'Volver a grabar voz',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        await ref
                            .read(expenseCaptureControllerProvider.notifier)
                            .submitText(_descriptionController.text);
                        final updated = ref.read(expenseCaptureControllerProvider).pendingDraft;
                        if (updated != null) {
                          _descriptionController.text = updated.description;
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Analizar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        ref.read(expenseCaptureControllerProvider.notifier).discardDraft();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: state.status == CaptureStatus.loading
                          ? null
                          : () async {
                              await ref.read(expenseCaptureControllerProvider.notifier).confirmDraft();
                              if (!context.mounted) {
                                return;
                              }
                              final updated = ref.read(expenseCaptureControllerProvider);
                              if (updated.status == CaptureStatus.success) {
                                Navigator.of(context).pop();
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: Text(
                        state.status == CaptureStatus.loading ? 'Registrando...' : 'Registrar',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTag() {
    final String value = _tagController.text.trim();
    if (value.isEmpty) {
      return;
    }

    ref.read(expenseCaptureControllerProvider.notifier).addCustomTag(value);
    _tagController.clear();
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.primary)),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.danger)),
    );
  }
}
