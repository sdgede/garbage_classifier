import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/classification_result.dart';
import '../features/classification/domain/classification_state.dart';
import 'classifier_provider.dart';

part 'classification_controller.g.dart';

@Riverpod(keepAlive: true)
class ClassificationController extends _$ClassificationController {
  @override
  FutureOr<ClassificationResult?> build() {
    return null;
  }

  Future<void> classify() async {
    final classifier = ref.read(classifierServiceProvider);
    final uiState = ref.read(classificationNotifierProvider);
    
    if (uiState.imagePath == null) return;

    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      return await classifier.classify(
        uiState.imagePath!,
        additionalContext: uiState.additionalContext,
      );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
