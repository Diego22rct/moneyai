abstract interface class SttService {
  bool get isListening;

  Future<void> startListening({required void Function(String text) onText});

  Future<void> stopListening();
}
