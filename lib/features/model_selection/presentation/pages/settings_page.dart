import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';
import 'package:moneyai/features/model_selection/presentation/providers/model_selector_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNlu = ref.watch(activeNluModelProvider);
    final nluModelPath = ref.watch(nluModelPathProvider);
    final nluLibPath = ref.watch(nluNativeLibPathProvider);
    final runtimeConfigState = ref.watch(modelRuntimeConfigControllerProvider);

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
                    title: 'Configurar Llama local',
                    subtitle: _buildLlamaSubtitle(
                      modelPath: nluModelPath,
                      libPath: nluLibPath,
                    ),
                    onTap: () => _showLlamaConfigDialog(
                      context,
                      ref,
                      initialModelPath: nluModelPath.valueOrNull,
                      initialLibPath: nluLibPath.valueOrNull,
                    ),
                  ),
                  if (runtimeConfigState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No se pudo guardar la configuracion runtime.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
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

  String _buildLlamaSubtitle({
    required AsyncValue<String?> modelPath,
    required AsyncValue<String?> libPath,
  }) {
    final String ggufPath = modelPath.valueOrNull?.trim().isNotEmpty == true
        ? modelPath.valueOrNull!
        : 'No configurada';
    final String nativePath = libPath.valueOrNull?.trim().isNotEmpty == true
        ? libPath.valueOrNull!
        : 'Auto';

    return 'Modelo GGUF: $ggufPath\nLibreria nativa: $nativePath';
  }


  Future<void> _showLlamaConfigDialog(
    BuildContext context,
    WidgetRef ref, {
    required String? initialModelPath,
    required String? initialLibPath,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController modelPathController =
        TextEditingController(text: initialModelPath ?? '');
    final TextEditingController libPathController = TextEditingController(text: initialLibPath ?? '');

    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Llama local'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: modelPathController,
                  decoration: const InputDecoration(
                    labelText: 'Ruta del modelo GGUF',
                    hintText: 'Ej: /storage/emulated/.../modelo.gguf',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La ruta del modelo GGUF es obligatoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: libPathController,
                  decoration: const InputDecoration(
                    labelText: 'Ruta libreria nativa (opcional)',
                    hintText: 'Si esta vacio, se usa resolucion por defecto del paquete',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (accepted != true) {
      modelPathController.dispose();
      libPathController.dispose();
      return;
    }

    await ref.read(modelRuntimeConfigControllerProvider.notifier).setModelPath(
          task: AiTask.nlu,
          path: modelPathController.text,
        );
    await ref
        .read(modelRuntimeConfigControllerProvider.notifier)
        .setNluNativeLibPath(libPathController.text);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuracion de Llama guardada.')),
      );
    }

    modelPathController.dispose();
    libPathController.dispose();
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
