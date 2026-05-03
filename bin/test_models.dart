import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load .env
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

  final client = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  
  try {
    // There isn't a direct listModels in the high-level GenerativeModel, 
    // but we can try to hit the info endpoint if we had the lower level client.
    // Instead, let's try a very basic prompt on a different model to see if it's just flash.
    
    print('\nTesting gemini-1.5-pro...');
    final proModel = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
    final proResponse = await proModel.generateContent([Content.text('hi')]);
    print('Gemini 1.5 Pro Success: ${proResponse.text != null}');
    
  } catch (e) {
    print('Error with Gemini 1.5 Pro: $e');
  }

  try {
    print('\nTesting gemini-1.0-pro...');
    final pro10Model = GenerativeModel(model: 'gemini-1.0-pro', apiKey: apiKey);
    final pro10Response = await pro10Model.generateContent([Content.text('hi')]);
    print('Gemini 1.0 Pro Success: ${pro10Response.text != null}');
  } catch (e) {
    print('Error with Gemini 1.0 Pro: $e');
  }
}
