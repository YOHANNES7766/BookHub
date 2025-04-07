import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch books from the API
  Future<void> fetchBooks() async {
    _setLoading(true);
    try {
      final url = 'http://10.0.2.2:8000/api/books';
      final token = await _getToken();

      logger.i(
          'Fetching books with token: ${token != null ? 'Token exists' : 'No token found'}');

      if (token == null) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      logger.d('Books API response status: ${response.statusCode}');
      logger.d('Books API response body: ${response.body}');

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        _books = jsonResponse.map((data) => Book.fromJson(data)).toList();
        notifyListeners();

        if (_books.isEmpty) logger.w('No books returned from API');
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Failed to load books');
      }
    } catch (error) {
      logger.e('Error in fetchBooks', error: error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Add a new book
  Future<void> addBook({
    required String title,
    required String author,
    required int categoryId,
    String? description,
    File? coverImage,
    File? pdfFile,
  }) async {
    _setLoading(true);
    final url = 'http://10.0.2.2:8000/api/books';
    final token = await _getToken();

    if (token == null) throw Exception('User not authenticated');

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = title
        ..fields['author'] = author
        ..fields['category_id'] = categoryId.toString();

      if (description != null) {
        request.fields['description'] = description;
      }

      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImage.path,
          filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      }

      if (pdfFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'pdf_file',
          pdfFile.path,
          filename: 'book_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ));
      }

      final response = await request.send();
      final resBody = await http.Response.fromStream(response);

      if (response.statusCode == 201) {
        logger.i('Book added successfully');
        await fetchBooks();
      } else {
        final body = json.decode(resBody.body);
        throw Exception(body['message'] ?? 'Failed to add book');
      }
    } catch (error) {
      logger.e('Error in addBook', error: error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing book
  Future<void> updateBook(
      String bookId, String title, String author, int categoryId) async {
    _setLoading(true);
    final url = 'http://10.0.2.2:8000/api/books/$bookId';
    final token = await _getToken();

    if (token == null) throw Exception('User not authenticated');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'author': author,
          'category_id': categoryId,
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Book updated successfully');
        await fetchBooks();
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Failed to update book');
      }
    } catch (error) {
      logger.e('Error in updateBook', error: error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a book
  Future<void> deleteBook(String bookId) async {
    _setLoading(true);
    final url = 'http://10.0.2.2:8000/api/books/$bookId';
    final token = await _getToken();

    if (token == null) throw Exception('User not authenticated');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _books.removeWhere((book) => book.id == bookId);
        notifyListeners();
        logger.i('Book deleted successfully');
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Failed to delete book');
      }
    } catch (error) {
      logger.e('Error in deleteBook', error: error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get token from local storage
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

// Book model
class Book {
  final String id;
  final String title;
  final String author;
  final int categoryId;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'],
      author: json['author'],
      categoryId: json['category_id'],
      description: json['description'],
    );
  }
}
