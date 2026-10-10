import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/core/theme/app_theme.dart';
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

class _CapturePageState extends ConsumerState<CapturePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(expenseCaptureControllerProvider);
    final voiceState = ref.watch(voiceInputControllerProvider);
    final expensesState = ref.watch(expenseListProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
      children: <Widget>[
        const Text(
          'AI TRANSCRIPTION ACTIVE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _textController.text.trim().isEmpty
              ? 'Habla para analizar tu movimiento\nen tiempo real'
              : '"${_textController.text}"',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 26),
        Center(
          child: SizedBox(
            width: 190,
            height: 90,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return _Waveform(
                  factor: voiceState.isListening ? _waveController.value : 0.2,
                  active: voiceState.isListening,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(
              child: _InfoStatCard(
                title: 'AMOUNT',
                value: _formatDraftAmount(captureState),
                valueColor: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoStatCard(
                title: 'TYPE',
                value: _draftTypeText(captureState),
                valueColor: _draftIsIncome(captureState)
                    ? AppTheme.secondary
                    : AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.secondary.withValues(alpha: 0.11),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El analisis de voz se procesa localmente en tu dispositivo.',
                  style: TextStyle(color: AppTheme.secondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _textController,
          minLines: 1,
          maxLines: 3,
          style: const TextStyle(color: AppTheme.onSurface),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Texto capturado',
            hintText: 'Ej: me pagaron 1200 de salario',
          ),
        ),
        const SizedBox(height: 14),
        _CaptureFeedback(
          message: captureState.message,
          status: captureState.status,
        ),
        if (voiceState.errorMessage != null) ...<Widget>[
          const SizedBox(height: 10),
          _CaptureFeedback(
            message: voiceState.errorMessage,
            status: CaptureStatus.error,
          ),
        ],
        const SizedBox(height: 18),
        Center(
          child: _MicActionButton(
            isListening: voiceState.isListening,
            onTap: () async {
              await ref
                  .read(voiceInputControllerProvider.notifier)
                  .toggleListening(
                    onText: (text) {
                      _textController.text = text;
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _textController.text.length),
                      );
                      setState(() {});
                    },
                  );
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
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
                        builder: (context) => const ReviewInterpretationPage(),
                      ),
                    );
                  }

                  final endState = ref.read(expenseCaptureControllerProvider);
                  if (endState.status == CaptureStatus.success) {
                    _textController.clear();
                    setState(() {});
                  }
                },
          icon: captureState.status == CaptureStatus.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.psychology_alt),
          label: const Text('Analizar y revisar'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppTheme.primaryContainer,
            foregroundColor: AppTheme.background,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ledger Activity',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        expensesState.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return const _GlassInfo('Aun no tienes movimientos registrados.');
            }

            return Column(
              children: expenses.take(4).map((expense) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MovementTile(expense: expense),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const _GlassInfo('No se pudo cargar la lista de movimientos.'),
        ),
      ],
    );
  }

  String _formatDraftAmount(ExpenseCaptureState state) {
    final draft = state.pendingDraft;
    if (draft == null) {
      return '--';
    }

    return NumberFormat.currency(
      locale: 'es_PE',
      symbol: '${draft.currency} ',
    ).format(draft.amount);
  }

  bool _draftIsIncome(ExpenseCaptureState state) {
    return state.pendingDraft?.type == TransactionType.income;
  }

  String _draftTypeText(ExpenseCaptureState state) {
    if (state.pendingDraft == null) {
      return '--';
    }
    return _draftIsIncome(state) ? 'Ingreso' : 'Gasto';
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.factor, required this.active});

  final double factor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(13, (index) {
        final double phase = (index / 13) * math.pi;
        final double normalized =
            (math.sin((factor * math.pi * 2) + phase).abs() * 0.75) + 0.25;
        final double height =
            (active ? 18 : 8) + (normalized * (active ? 46 : 16));
        final bool accent = index % 4 == 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 5,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: accent ? AppTheme.secondary : AppTheme.primary,
              boxShadow: accent
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ]
                  : <BoxShadow>[],
            ),
          ),
        );
      }),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  const _InfoStatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.surfaceHigh.withValues(alpha: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.onSurfaceMuted,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

    Color color = AppTheme.onSurfaceMuted;
    if (status == CaptureStatus.success) {
      color = AppTheme.secondary;
    } else if (status == CaptureStatus.error) {
      color = AppTheme.danger;
    } else if (status == CaptureStatus.reviewing) {
      color = AppTheme.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(message!, style: TextStyle(color: color)),
    );
  }
}

class _MicActionButton extends StatelessWidget {
  const _MicActionButton({required this.isListening, required this.onTap});

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color base = isListening ? AppTheme.secondary : AppTheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isListening ? 98 : 86,
      height: isListening ? 98 : 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[base, base.withValues(alpha: 0.75)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: isListening ? 36 : 24,
            color: base.withValues(alpha: 0.45),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          isListening ? Icons.stop_rounded : Icons.mic,
          size: 36,
          color: AppTheme.background,
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = expense.type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.surfaceHigh.withValues(alpha: 0.7),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            child: Icon(
              isIncome ? Icons.payments : Icons.shopping_bag,
              color: isIncome ? AppTheme.secondary : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expense.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isIncome ? AppTheme.secondary : AppTheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassInfo extends StatelessWidget {
  const _GlassInfo(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.surfaceHigh.withValues(alpha: 0.7),
      ),
      child: Text(message),
    );
  }
}
