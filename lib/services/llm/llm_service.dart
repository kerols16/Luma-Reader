/// Placeholder for future AI/LLM features.
///
/// v0 ships no AI features. This interface defines the boundary only; there is
/// intentionally no implementation.
abstract interface class LlmService {
  /// Whether an explanation service is configured.
  bool get isAvailable;
}
