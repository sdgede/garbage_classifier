class ClassificationResult {
  final String category;
  final String subcategory;
  final double confidence;
  final List<String> instructions;

  const ClassificationResult({
    required this.category,
    required this.subcategory,
    required this.confidence,
    required this.instructions,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    final rawConfidence = json['confidence'];
    double confidence;
    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble();
    } else if (rawConfidence is String) {
      confidence = double.tryParse(rawConfidence) ?? 0.0;
    } else {
      confidence = 0.0;
    }

    return ClassificationResult(
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      confidence: confidence,
      instructions: (json['instructions'] as List).map((e) => e as String).toList(),
    );
  }
}
