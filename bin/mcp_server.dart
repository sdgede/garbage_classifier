import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables for API key
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env might not exist in the current directory if run from root
  }

  final apiKey = (Platform.environment['GEMINI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'])?.trim();

  // Initialize the MCP Server
  final server = McpServer(
    const Implementation(name: "garbage-classifier-server", version: "1.0.0"),
    options: const ServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  // Register a tool to analyze the project
  server.tool(
    "analyze_project",
    description: 'Run dart analyze on the project to check for errors and lints.',
    inputSchemaProperties: {},
    callback: ({args, extra}) async {
      final result = await Process.run('dart', ['analyze']);
      return CallToolResult.fromContent(
        content: [
          TextContent(
            text: result.stdout.toString() + result.stderr.toString(),
          ),
        ],
        isError: result.exitCode != 0,
      );
    },
  );

  // Register a tool to classify waste using Gemini SDK
  server.tool(
    "classify_waste",
    description: 'Classify waste into Bali\'s three-bin taxonomy (organik, non-organik, residu).',
    inputSchemaProperties: {
      'image_description': {
        'type': 'string',
        'description': 'A description of the waste item.',
      },
    },
    callback: ({args, extra}) async {
      final description = args?['image_description'] as String? ?? 'unknown';
      
      if (apiKey == null || apiKey.isEmpty) {
        return CallToolResult.fromContent(
          content: [
            TextContent(text: 'Error: GEMINI_API_KEY not found. Please set it in .env.'),
          ],
          isError: true,
        );
      }

      final model = ai.GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = 'Klasifikasikan sampah berikut ke dalam kategori Bali (organik, non-organik, residu) '
          'berdasarkan deskripsi ini: "$description". '
          'Berikan kategori dan alasan singkat dalam Bahasa Indonesia.';

      try {
        final response = await model.generateContent([ai.Content.text(prompt)]);
        return CallToolResult.fromContent(
          content: [
            TextContent(text: response.text ?? 'Gagal mendapatkan klasifikasi.'),
          ],
        );
      } catch (e) {
        return CallToolResult.fromContent(
          content: [
            TextContent(text: 'Error calling Gemini: $e'),
          ],
          isError: true,
        );
      }
    },
  );

  // Connect using Stdio transport
  await server.connect(StdioServerTransport());
}
