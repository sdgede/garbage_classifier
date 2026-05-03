import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'classification_state.g.dart';

class ClassificationState {
  final String? imagePath;
  final String additionalContext;

  const ClassificationState({
    this.imagePath,
    this.additionalContext = '',
  });

  ClassificationState copyWith({
    String? imagePath,
    String? additionalContext,
  }) {
    return ClassificationState(
      imagePath: imagePath ?? this.imagePath,
      additionalContext: additionalContext ?? this.additionalContext,
    );
  }
}

@riverpod
class ClassificationNotifier extends _$ClassificationNotifier {
  @override
  ClassificationState build() => const ClassificationState();

  void setImage(String? path) {
    if (path == null) {
      state = const ClassificationState();
    } else {
      state = state.copyWith(imagePath: path);
    }
  }

  void setContext(String context) {
    state = state.copyWith(additionalContext: context);
  }
}
