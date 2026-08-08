import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'https://api.replicate.com/v1/predictions';
  // Use your actual token here, but store it securely!
  final String _apiKey = ''; 

  Future<String?> tryOnAI(String userImageBase64, String designImageBase64) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "version": "0513734a",
        "input": {
          "human_img": userImageBase64,
          "garm_img": designImageBase64,
        }
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['id']; // Returns the prediction ID
    } else {
      throw Exception('Failed to start AI generation');
    }
  }

  // The Polling Function
  Future<String?> checkPredictionStatus(String predictionId) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 3)); // Wait 3 seconds
      
      final response = await http.get(
        Uri.parse('$_baseUrl/$predictionId'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      final data = jsonDecode(response.body);
      String status = data['status'];

      if (status == 'succeeded') {
        return data['output']; // Returns the final image URL
      } else if (status == 'failed' || status == 'canceled') {
        throw Exception('AI generation $status');
      }
      // If 'starting' or 'processing', the loop continues automatically
    }
  }
}