import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';
import 'package:moneyai/features/model_selection/presentation/pages/llama_model_download_page.dart';
import 'package:moneyai/features/model_selection/presentation/providers/model_selector_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNlu = ref.watch(activeNluModelProvider);
    final nluModelPath = ref.watch(nluModelPathProvider);

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
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.mic),
                      title: Text('Speech to Text (device)'),
                      subtitle: Text('Modelo STT activo y unico para Android e iOS.'),
                      trailing: Icon(Icons.check_circle, color: Colors.green),
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
                  const SizedBox(height: 8),
                  _RuntimeConfigCard(
                    title: 'Descargar modelo Llama',
                    subtitle: _buildLlamaSubtitle(modelPath: nluModelPath),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const LlamaModelDownloadPage(),
                        ),
                      );
                      return;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La app buscara y descargara modelos GGUF desde Hugging Face para activar llama_local automaticamente.',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (nluModelPath.valueOrNull?.trim().isNotEmpty == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Puedes cambiar de modelo cuando quieras desde este mismo flujo.',
                        style: TextStyle(fontSize: 12),
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

  String _buildLlamaSubtitle({required AsyncValue<String?> modelPath}) {
    final String ggufPath = modelPath.valueOrNull?.trim().isNotEmpty == true
        ? modelPath.valueOrNull!
        : 'No configurada';

    return 'Modelo GGUF activo:\n$ggufPath';
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

class _RuntimeConfigCard extends StatelessWidget {
  const _RuntimeConfigCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }
}
