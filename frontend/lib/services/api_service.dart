// lib/services/api_service.dart
//
// Connects to Sehat Mand Pakistan Flask backend.
// POST /api/chat  — { message, mode, session_id }
// POST /api/clear — { session_id }
// GET  /api/health

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ── Base URL ────────────────────────────────────────────
  // Android emulator → use 10.0.2.2:5000
  // iOS simulator    → use localhost:5000
  // Physical device  → use your machine's LAN IP, e.g. 192.168.1.x:5000
  // Web (Chrome dev) → use localhost:5000
  // Production       → https://your-backend.com
  static const String _baseUrl = 'http://localhost:5000';

  static const Duration _timeout = Duration(seconds: 30);

  // ── POST /api/chat ──────────────────────────────────────
  // mode: "user" (My AI tab) | "doctor" (Doctor AI tab)
  // session_id: unique per conversation, kept on the Notifier
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String mode, // "user" or "doctor"
    required String sessionId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');

    final body = jsonEncode({
      'message': message,
      'mode': mode, // backend expects "user" or "doctor"
      'session_id': sessionId,
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final err = _parseError(response.body);
      throw ApiException('Server error ${response.statusCode}: $err');
    }
  }

  // ── POST /api/clear (clears server-side session memory) ─
  static Future<void> clearSession(String sessionId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/clear');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'session_id': sessionId}),
          )
          .timeout(_timeout);
    } catch (_) {
      // Best-effort — don't crash the UI if this fails
    }
  }

  // ── GET /api/health ─────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/health');
      final response = await http.get(uri).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error'] ?? body;
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
