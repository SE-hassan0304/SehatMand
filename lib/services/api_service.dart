import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ── Change this to your machine's IP when testing on a real device ──
  // For emulator: 10.0.2.2  |  For real device: your local IP e.g. 192.168.x.x
  static const String _baseUrl = 'http://localhost:5000';

  /// Sends a message to the Flask backend.
  ///
  /// [message] — the user's text
  /// [mode]    — 1 for user mode, 2 for doctor mode
  /// [history] — list of {"role": "user"/"assistant", "content": "..."} maps
  ///
  /// Returns the full response map from backend:
  ///   User mode   → {reply, type, mode, specialist, doctors}
  ///   Doctor mode → {reply, type, mode, emergency_flag}
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required int mode,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'mode': mode,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Backend returned an error status
        final errorBody = jsonDecode(response.body);
        return {
          'reply': errorBody['error'] ?? 'Server error: ${response.statusCode}',
          'type': 'error',
          'mode': mode == 2 ? 'doctor' : 'user',
          'emergency_flag': false,
          'doctors': [],
        };
      }
    } on Exception {
      // Network error / timeout
      return {
        'reply': '⚠️ Server se connection nahi ho pa raha.\n'
            'Backend chal raha hai? Terminal mein check karein.',
        'type': 'error',
        'mode': mode == 2 ? 'doctor' : 'user',
        'emergency_flag': false,
        'doctors': [],
      };
    }
  }

  /// Health check — returns true if backend is running
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
