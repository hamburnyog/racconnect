import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<bool> isServerReachable() async {
  final url = dotenv.env['POCKETBASE_URL'];
  if (url == null || url.isEmpty) {
    return false;
  }

  try {
    final response = await http.get(Uri.parse('$url/api/health'));
    // If we get a 429 (Too Many Requests), treat as unreachable temporarily
    if (response.statusCode == 429) {
      return false;
    }
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
