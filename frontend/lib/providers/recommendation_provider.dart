import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recommendation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart'; // ✅ Import logger

final logger = Logger(); // ✅ Initialize logger

class RecommendationProvider with ChangeNotifier {
  List<Recommendation> _recommendations = [];
  bool _isLoading = false;

  List<Recommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  final String _baseUrl = 'http://10.0.2.2:8000/api/recommendations';

  // Fetch Recommendations
  Future<void> fetchRecommendations() async {
    _isLoading = true;
    notifyListeners();

    try {
      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _recommendations =
            data.map((json) => Recommendation.fromJson(json)).toList();
      } else {
        logger.w('Failed to load recommendations: ${response.statusCode}');
        logger.w('Response body: ${response.body}');
      }
    } catch (e) {
      logger.e('Error fetching recommendations', error: e);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add Recommendation
  Future<void> addRecommendation(int userId, int bookId, String message) async {
    try {
      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'book_id': bookId,
          'recommendation_message': message,
        }),
      );

      if (response.statusCode == 201) {
        final newRecommendation =
            Recommendation.fromJson(json.decode(response.body));
        _recommendations.add(newRecommendation);
        notifyListeners();
      } else {
        logger.w('Failed to add recommendation: ${response.statusCode}');
        logger.w('Response body: ${response.body}');
      }
    } catch (e) {
      logger.e('Error adding recommendation', error: e);
    }
  }

  // Delete Recommendation
  Future<void> deleteRecommendation(int id) async {
    try {
      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _recommendations.removeWhere((r) => r.id == id);
        notifyListeners();
      } else {
        logger.w('Failed to delete recommendation: ${response.statusCode}');
        logger.w('Response body: ${response.body}');
      }
    } catch (e) {
      logger.e('Error deleting recommendation', error: e);
    }
  }

  // Retrieve auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
