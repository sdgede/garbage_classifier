import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/classifier.dart';

part 'classifier_provider.g.dart';

@riverpod
ClassifierService classifierService(ClassifierServiceRef ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  return ClassifierService(apiKey: apiKey);
}
