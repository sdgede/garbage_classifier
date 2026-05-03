import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';
import '../models/classification_result.dart';

class ClassifierService {
  final GenerativeModel _model;
  final _log = Logger('ClassifierService');

  ClassifierService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(
            'Anda adalah asisten ahli klasifikasi sampah untuk program pemilahan sampah di Bali. '
            'Tugas utama Anda adalah menganalisis foto sampah dan mengklasifikasikannya ke dalam '
            'salah satu dari tiga kategori: organik, non-organik, atau residu. '
            'Berikan instruksi pembuangan yang praktis dan relevan bagi masyarakat di Bali. '
            'Anda wajib menjawab HANYA dalam format JSON yang telah ditentukan.',
          ),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: Schema.object(
              properties: {
                'category': Schema.enumString(
                  description: 'Kategori sampah (organik, non-organik, residu)',
                  enumValues: ['organik', 'non-organik', 'residu'],
                ),
                'subcategory': Schema.string(
                  description: 'Nama spesifik dari item sampah',
                ),
                'confidence': Schema.number(
                  description: 'Tingkat kepercayaan model (0-1)',
                ),
                'instructions': Schema.array(
                  description: 'Instruksi pembuangan dalam Bahasa Indonesia',
                  items: Schema.string(),
                ),
              },
              requiredProperties: ['category', 'subcategory', 'confidence', 'instructions'],
            ),
          ),
        );

  Future<ClassificationResult> classify(String imagePath, {String? additionalContext}) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    
    // Determine mime type based on extension
    final extension = imagePath.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    }

    final parts = [
      TextPart(
        'Identifikasi dan klasifikasikan sampah dalam foto ini sesuai dengan kategori yang ditentukan. '
        'Berikan detail subkategori, tingkat kepercayaan, dan instruksi penanganan.',
      ),
      DataPart(mimeType, imageBytes),
    ];

    if (additionalContext != null && additionalContext.isNotEmpty) {
      parts.add(TextPart('\nKonteks tambahan dari pengguna: $additionalContext'));
    }

    _log.info('Sending classification request to Google Gemini... MimeType: $mimeType');
    
    // DEBUG PRINT: Input info
    print('--- GEMINI API CALL START ---');
    print('Image Path: $imagePath');
    print('MimeType: $mimeType');
    if (additionalContext != null) print('Context: $additionalContext');

    final response = await _model.generateContent([Content.multi(parts)]);
    String? rawText = response.text;

    // DEBUG PRINT: Raw Response
    print('--- GEMINI API RESPONSE ---');
    print(rawText ?? 'NULL RESPONSE');
    print('--- GEMINI API CALL END ---');

    if (rawText == null) {
      _log.severe('AI returned null response.');
      throw Exception('Gagal mendapatkan jawaban dari AI. Mungkin konten diblokir oleh filter keamanan.');
    }

    _log.info('Raw AI Response: $rawText');

    // Clean markdown if present (though responseMimeType: application/json should prevent it)
    if (rawText.startsWith('```json')) {
      rawText = rawText.replaceFirst('```json', '');
      if (rawText.endsWith('```')) {
        rawText = rawText.substring(0, rawText.length - 3);
      }
      rawText = rawText.trim();
    }

    try {
      final json = jsonDecode(rawText) as Map<String, dynamic>;
      final result = ClassificationResult.fromJson(json);
      _log.info('Classification successful: ${result.category}');
      return result;
    } catch (e) {
      _log.severe('Failed to parse AI response: $e');
      throw Exception('Gagal memproses format jawaban AI. Pastikan foto sampah terlihat jelas.');
    }
  }
}
