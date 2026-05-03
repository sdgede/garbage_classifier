import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'models/classification_result.dart';
import 'providers/classification_controller.dart';
import 'features/classification/domain/classification_state.dart';
import 'features/classification/widgets/result_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });

  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garbage Classifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classificationState = ref.watch(classificationNotifierProvider);
    final classificationController = ref.watch(classificationControllerProvider);
    final notifier = ref.read(classificationNotifierProvider.notifier);

    // Listen to the classification controller for results or errors
    ref.listen<AsyncValue<ClassificationResult?>>(
      classificationControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (result) {
            if (result != null) {
              ResultModal.show(context, result);
            }
          },
          error: (error, stackTrace) {
            _showErrorDialog(context, error);
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Classifier'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePickerSection(
              imagePath: classificationState.imagePath,
              onImagePicked: (path) {
                notifier.setImage(path);
                if (path == null) {
                  ref.read(classificationControllerProvider.notifier).reset();
                }
              },
            ),
            const SizedBox(height: 32),
            _ContextInputSection(
              onChanged: notifier.setContext,
            ),
            const SizedBox(height: 32),
            _ClassificationButton(
              isLoading: classificationController.isLoading,
              onPressed: classificationState.imagePath != null
                  ? () => ref.read(classificationControllerProvider.notifier).classify()
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, Object error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Classification Error'),
        content: Text(_humanizeError(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _humanizeError(Object error) {
    if (error is UnimplementedError) {
      return 'This feature is coming soon! The classifier is not yet fully implemented.';
    }
    if (error is SocketException) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    // Extract message from Exception if possible
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    
    return message;
  }
}

class ResultCard extends StatelessWidget {
  final ClassificationResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.category.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              result.subcategory,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: result.confidence,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 4),
            Text(
              'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...result.instructions.map((ins) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(ins)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onImagePicked;

  const _ImagePickerSection({
    required this.imagePath,
    required this.onImagePicked,
  });

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 640,
      maxHeight: 640,
    );
    if (image != null) {
      onImagePicked(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: imagePath != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filled(
                        onPressed: () => onImagePicked(null),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload Garbage Photo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextInputSection extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _ContextInputSection({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional Context',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'e.g. found this on the beach...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}

class _ClassificationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ClassificationButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Classify Garbage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
