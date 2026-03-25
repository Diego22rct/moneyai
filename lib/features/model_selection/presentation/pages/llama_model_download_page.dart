import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/model_selection/domain/entities/llama_remote_file.dart';
import 'package:moneyai/features/model_selection/presentation/providers/model_download_provider.dart';

class LlamaModelDownloadPage extends ConsumerStatefulWidget {
  const LlamaModelDownloadPage({super.key});

  @override
  ConsumerState<LlamaModelDownloadPage> createState() => _LlamaModelDownloadPageState();
}

class _LlamaModelDownloadPageState extends ConsumerState<LlamaModelDownloadPage> {
  final TextEditingController _searchController = TextEditingController(text: 'qwen gguf');

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(modelDownloadControllerProvider.notifier).loadCurrentPath();
      await ref.read(modelDownloadControllerProvider.notifier).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelDownloadControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Descargar modelo Llama')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar en Hugging Face',
                  hintText: 'Ej: qwen gguf',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: state.isSearching
                        ? null
                        : () {
                            ref.read(modelDownloadControllerProvider.notifier).search(
                                  _searchController.text,
                                );
                          },
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (value) {
                  ref.read(modelDownloadControllerProvider.notifier).search(value);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Se muestran modelos GGUF optimizados para telefono (cuantizados y de menor tamano).\nLa descarga recomienda Wi-Fi. En datos moviles, confirma antes de continuar.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              _CurrentModelBanner(path: state.activeFilePath),
              if (state.isDownloading) ...<Widget>[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: state.progress == 0 ? null : state.progress),
                const SizedBox(height: 6),
                Text('${(state.progress * 100).toStringAsFixed(1)}%'),
              ],
              if (state.statusMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(state.statusMessage!, style: const TextStyle(color: Colors.green)),
              ],
              if (state.errorMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: state.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : state.results.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay resultados mobile-friendly para esa busqueda.\nPrueba: qwen 1.5b gguf o llama 3b q4.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.results.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final file = state.results[index];
                              return _ModelFileTile(
                                file: file,
                                isDownloading: state.isDownloading,
                                onDownload: () async {
                                  final bool confirmed = await _confirmDownload(context, file);
                                  if (!confirmed) {
                                    return;
                                  }
                                  if (!mounted) {
                                    return;
                                  }
                                  await ref
                                      .read(modelDownloadControllerProvider.notifier)
                                      .downloadAndActivate(file);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDownload(BuildContext context, LlamaRemoteFile file) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar descarga'),
        content: Text(
          'Modelo: ${file.modelId}\nArchivo: ${file.fileName}\nTamano: ${file.prettySize}\n\nRecomendado usar Wi-Fi.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );

    return accepted ?? false;
  }
}

class _CurrentModelBanner extends StatelessWidget {
  const _CurrentModelBanner({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final bool hasModel = path != null && path!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blueGrey.withValues(alpha: 0.08),
      ),
      child: Text(
        hasModel ? 'Modelo activo:\n$path' : 'Aun no hay modelo local descargado.',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _ModelFileTile extends StatelessWidget {
  const _ModelFileTile({
    required this.file,
    required this.isDownloading,
    required this.onDownload,
  });

  final LlamaRemoteFile file;
  final bool isDownloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    file.modelId,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Icon(Icons.sd_storage, size: 16),
                    label: Text(file.prettySize),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isDownloading ? null : onDownload,
              child: const Text('Usar'),
            ),
          ],
        ),
      ),
    );
  }
}
