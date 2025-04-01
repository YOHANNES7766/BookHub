import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  final bool _isLoading = false;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;

  // Fetch books from the API
  Future<void> fetchBooks() async {
    try {
      final url = 'http://10.0.2.2:8000/api/books';
      final token = await _getToken();

      print(
          'Fetching books with token: ${token != null ? 'Token exists' : 'No token found'}');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Books API response status: ${response.statusCode}');
      print('Books API response body: ${response.body}');

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        _books = jsonResponse.map((data) => Book.fromJson(data)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in fetchBooks: $error');
      rethrow;
    }
  }

  // Add a new book with image and PDF
  Future<void> addBook({
    required String title,
    required String author,
    required int categoryId,
    String? description,
    File? coverImage,
    File? pdfFile,
  }) async {
    final url =
        'http://10.0.2.2:8000/api/books'; // Replace with your server URL
    final token = await _getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

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
        ));
      }

      if (pdfFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'pdf_file',
          pdfFile.path,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        // Book added successfully
        await fetchBooks(); // Refresh the list of books
      } else {
        throw Exception('Failed to add book');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Update an existing book's details
  Future<void> updateBook(
      String bookId, String title, String author, int categoryId) async {
    final url =
        'http://10.0.2.2:8000/api/books/$bookId'; // Replace with your server URL
    final token = await _getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

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
        // If the update is successful, refresh the list of books
        await fetchBooks();
      } else {
        throw Exception('Failed to update book');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Delete a book by ID
  Future<void> deleteBook(String bookId) async {
    final url =
        'http://10.0.2.2:8000/api/books/$bookId'; // Replace with your server URL
    final token = await _getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Book deleted successfully
        _books.removeWhere(
            (book) => book.id == bookId); // Remove the book from the list
        notifyListeners(); // Notify listeners to update UI
      } else {
        throw Exception('Failed to delete book');
      }
    } catch (error) {
      rethrow;
    }
  }

  // Get the stored token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

// Book class definition with categoryId
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
