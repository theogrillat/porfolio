import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Replace with your actual Firebase function URL
  static const String _functionUrl = 'https://sendcontactemail-y2733hn7aa-od.a.run.app';

  /// Sends a contact form email
  /// Returns true if successful, false otherwise
  static Future<bool> sendContactEmail({
    required String firstName,
    required String lastName,
    required String senderEmail,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'senderEmail': senderEmail,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception sending email: $e');
      return false;
    }
  }

  /// Sends contact email with better error handling
  static Future<ContactEmailResult> sendContactEmailWithDetails({
    required String firstName,
    required String lastName,
    required String senderEmail,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'senderEmail': senderEmail,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return ContactEmailResult.success(
            messageId: result['messageId'],
          );
        } else {
          return ContactEmailResult.failure(
            error: result['error'] ?? 'Unknown error',
          );
        }
      } else if (response.statusCode == 400) {
        final result = jsonDecode(response.body);
        return ContactEmailResult.failure(
          error: result['error'] ?? 'Invalid request',
        );
      } else {
        return ContactEmailResult.failure(
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ContactEmailResult.failure(
        error: 'Network error: $e',
      );
    }
  }
}

/// Result class for better error handling
class ContactEmailResult {
  final bool success;
  final String? messageId;
  final String? error;

  ContactEmailResult._({
    required this.success,
    this.messageId,
    this.error,
  });

  factory ContactEmailResult.success({String? messageId}) {
    return ContactEmailResult._(
      success: true,
      messageId: messageId,
    );
  }

  factory ContactEmailResult.failure({required String error}) {
    return ContactEmailResult._(
      success: false,
      error: error,
    );
  }
}
