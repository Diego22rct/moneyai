abstract interface class NluService {
  Future<Map<String, Object>> extractMovement(String text);
}
