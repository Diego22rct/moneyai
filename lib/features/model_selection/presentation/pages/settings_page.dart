import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';
import 'package:moneyai/features/model_selection/presentation/providers/model_selector_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStt = ref.watch(activeSttModelProvider);
    final activeNlu = ref.watch(activeNluModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion de Modelos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Transcripcion de voz (STT)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ...kSttModelOptions.map(
                    (option) => _ModelOptionTile(
                      option: option,
                      activeModel: activeStt,
                      onSelected: option.available
                          ? () => ref.read(modelSelectionControllerProvider.notifier).selectModel(
                                task: AiTask.stt,
                                modelId: option.id,
                              )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Extraccion financiera (NLU)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...kNluModelOptions.map(
                    (option) => _ModelOptionTile(
                      option: option,
                      activeModel: activeNlu,
                      onSelected: option.available
                          ? () => ref.read(modelSelectionControllerProvider.notifier).selectModel(
                                task: AiTask.nlu,
                                modelId: option.id,
                              )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelOptionTile extends StatelessWidget {
  const _ModelOptionTile({
    required this.option,
    required this.activeModel,
    this.onSelected,
  });

  final ModelOption option;
  final AsyncValue<String> activeModel;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = activeModel.maybeWhen(
      data: (model) => model == option.id,
      orElse: () => false,
    );

    return Card(
      child: ListTile(
        title: Text(option.title),
        subtitle: Text(option.description),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : option.available
                ? const Icon(Icons.radio_button_unchecked)
                : const Icon(Icons.lock_outline, color: Colors.grey),
        onTap: onSelected,
      ),
    );
  }
}
