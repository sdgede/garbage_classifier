import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Manual parsing of .env to avoid flutter_dotenv dependency
  final file = File('.env');
  final lines = await file.readAsLines();
  String apiKey = '';
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
    }
  }

  if (apiKey.isEmpty) {
    print('Error: API Key not found in .env');
    return;
  }

  print('Using API Key: ${apiKey.substring(0, 8)}...');

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List;
      print('\nAvailable Models for your key:');
      for (var model in models) {
        print('- ${model['name']} (Supported: ${model['supportedGenerationMethods']})');
      }
    } else {
      print('Failed to list models: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
