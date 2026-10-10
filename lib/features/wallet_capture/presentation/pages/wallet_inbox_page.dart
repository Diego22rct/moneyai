import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/core/theme/app_theme.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/pages/review_interpretation_page.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_capture_controller.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_capture.dart';
import 'package:moneyai/features/wallet_capture/presentation/providers/wallet_capture_providers.dart';

class WalletInboxPage extends ConsumerWidget {
  const WalletInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(walletInboxProvider);
    final accessAsync = ref.watch(notificationAccessProvider);
    final repo = ref.watch(walletCaptureRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Billeteras'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sincronizar ahora',
            onPressed: () => ref.read(walletInboxProvider.notifier).syncAndRefresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(walletInboxProvider.notifier).syncAndRefresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Permission banner if not granted
            accessAsync.maybeWhen(
              data: (granted) {
                if (granted || !repo.isSupported) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AccessRequiredCard(
                    onOpenSettings: () => repo.openAccessSettings(),
                    onOpenAppDetails: () => repo.openAppDetails(),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            inboxAsync.when(
              data: (captures) {
                if (captures.isEmpty) {
                  return const _EmptyInboxView();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Movimientos por confirmar (${captures.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...captures.map(
                      (capture) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CaptureCard(capture: capture),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error al cargar la bandeja: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends ConsumerWidget {
  const _CaptureCard({required this.capture});

  final WalletCapture capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: '${capture.currency} ',
      decimalDigits: 2,
    );

    final isIncome = capture.type == TransactionType.income;
    final formattedTime = DateFormat('dd/MM HH:mm').format(capture.postedAt.toLocal());

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        capture.source.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        capture.displayTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (capture.rawText != null && capture.rawText!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          capture.rawText!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceMuted,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(capture.amount)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isIncome ? AppTheme.secondary : AppTheme.onSurface,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    if (capture.id != null) {
                      ref.read(walletInboxProvider.notifier).dismiss(capture.id!);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Descartar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _handleReview(context, ref),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Revisar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: AppTheme.background,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReview(BuildContext context, WidgetRef ref) async {
    final textForAnalysis = capture.merchant?.trim().isNotEmpty == true
        ? capture.merchant!
        : capture.displayTitle;

    // Use current NLU to predict category from merchant name
    String predictedCategory = 'Otros';
    try {
      final analyzed = await ref
          .read(expenseRepositoryProvider)
          .analyzeMovementFromText('$textForAnalysis ${capture.amount}');
      predictedCategory = analyzed.category;
    } catch (_) {}

    final suggested = <String>{
      predictedCategory,
      capture.type == TransactionType.income ? 'Ingreso' : 'Gasto',
      capture.source.displayName,
    }.where((t) => t.trim().isNotEmpty).toList();

    final draft = MovementDraft(
      amount: capture.amount,
      currency: capture.currency,
      type: capture.type,
      description: capture.displayTitle,
      timestamp: capture.postedAt,
      suggestedTags: suggested,
      selectedTags: suggested,
    );

    ref.read(expenseCaptureControllerProvider.notifier).startReview(
          draft,
          message: 'Confirma el pago detectado de ${capture.source.displayName}.',
        );

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReviewInterpretationPage(),
      ),
    );

    final endState = ref.read(expenseCaptureControllerProvider);
    if (endState.status == CaptureStatus.success && endState.lastSaved?.id != null) {
      if (capture.id != null) {
        await ref
            .read(walletInboxProvider.notifier)
            .markConfirmed(capture.id!, endState.lastSaved!.id!);
      }
    }
  }
}

class _AccessRequiredCard extends StatelessWidget {
  const _AccessRequiredCard({
    required this.onOpenSettings,
    required this.onOpenAppDetails,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAppDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.notification_important, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Acceso a notificaciones requerido',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'MoneyAI procesa localmente las notificaciones de billeteras para registrar tus pagos. Ningún dato sale de tu dispositivo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: onOpenSettings,
                  child: const Text('Activar acceso'),
                ),
                OutlinedButton(
                  onPressed: onOpenAppDetails,
                  child: const Text('Info de la app'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nota (Android 13+): si la opción aparece bloqueada en gris, pulsa "Info de la app" → menú ⋮ arriba a la derecha → "Permitir ajustes restringidos".',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceMuted.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInboxView extends StatelessWidget {
  const _EmptyInboxView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.done_all,
              size: 56,
              color: AppTheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes pagos pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los pagos con Google Wallet o Google Pay se detectarán automáticamente y aparecerán aquí para tu confirmación.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
