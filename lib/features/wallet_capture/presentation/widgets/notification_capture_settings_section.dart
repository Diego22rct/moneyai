import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/core/theme/app_theme.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';
import 'package:moneyai/features/wallet_capture/presentation/providers/wallet_capture_providers.dart';

class NotificationCaptureSettingsSection extends ConsumerWidget {
  const NotificationCaptureSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(walletCaptureRepositoryProvider);
    if (!repo.isSupported) {
      return const SizedBox.shrink();
    }

    final configAsync = ref.watch(captureConfigProvider);
    final accessAsync = ref.watch(notificationAccessProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Captura automática de billeteras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              // Main enable switch
              configAsync.maybeWhen(
                data: (config) => SwitchListTile(
                  title: const Text('Detectar pagos automáticamente'),
                  subtitle: const Text(
                    'Lee notificaciones locales para capturar gastos en la bandeja de revisión.',
                  ),
                  value: config.enabled,
                  onChanged: (val) =>
                      ref.read(captureConfigProvider.notifier).setEnabled(val),
                ),
                orElse: () => const ListTile(
                  title: Text('Detectar pagos automáticamente'),
                ),
              ),

              const Divider(height: 1),

              // Access permission status
              accessAsync.maybeWhen(
                data: (granted) => ListTile(
                  leading: Icon(
                    granted ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: granted ? AppTheme.secondary : Colors.amber,
                  ),
                  title: const Text('Acceso a notificaciones'),
                  subtitle: Text(
                    granted
                        ? 'Permiso concedido en el sistema.'
                        : 'Requerido para escuchar en segundo plano.',
                  ),
                  trailing: TextButton(
                    onPressed: () => repo.openAccessSettings(),
                    child: Text(granted ? 'Configurar' : 'Activar'),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              const Divider(height: 1),

              // Supported sources
              ...WalletSource.supported.map((source) {
                final isAllowed = configAsync.maybeWhen(
                  data: (config) => config.allowedPackages
                      .any((p) => source.packageNames.contains(p)),
                  orElse: () => true,
                );

                return SwitchListTile(
                  secondary: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(source.displayName),
                  value: isAllowed,
                  onChanged: configAsync.valueOrNull?.enabled == true
                      ? (_) {
                          for (final pkg in source.packageNames) {
                            ref
                                .read(captureConfigProvider.notifier)
                                .togglePackage(pkg);
                          }
                        }
                      : null,
                );
              }),

              // Upcoming sources placeholders
              ListTile(
                leading: const Icon(Icons.schedule, color: AppTheme.onSurfaceMuted),
                title: const Text(
                  'Yape / Plin / BCP / Correo',
                  style: TextStyle(color: AppTheme.onSurfaceMuted),
                ),
                subtitle: const Text(
                  'Próximamente en una actualización.',
                  style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Pronto', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
