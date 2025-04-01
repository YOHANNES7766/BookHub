import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  bool _isAdding = false;
  bool _isDeleting = false;
  bool _isUpdating = false;
  String? _errorMessage;
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  // Valid transaction types with their variations
  static const Map<String, List<String>> validTransactionTypes = {
    'purchase': ['purchase', 'buy', 'order'],
    'refund': ['refund', 'return payment', 'reimbursement'],
    'rental': ['rental', 'rent', 'lease'],
    'return': ['return', 'give back', 'bring back']
  };

  // Valid transaction statuses
  static const List<String> validStatuses = [
    'pending',
    'completed',
    'failed',
    'cancelled'
  ];

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isAdding => _isAdding;
  bool get isDeleting => _isDeleting;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'http://10.0.2.2:8000/api/transactions';

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  Future<T> _handleRequest<T>({
    required Future<T> Function() request,
    required String operation,
  }) async {
    int retries = 0;
    while (retries < _maxRetries) {
      try {
        return await request().timeout(_timeout);
      } catch (e) {
        retries++;
        if (retries == _maxRetries) {
          throw Exception('$operation failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: retries));
      }
    }
    throw Exception('$operation failed');
  }

  // Normalize and validate transaction type
  String _normalizeTransactionType(String type) {
    final normalizedType = type.toLowerCase().trim();

    // Check each valid type and its variations
    for (var entry in validTransactionTypes.entries) {
      if (entry.value.contains(normalizedType)) {
        return entry.key; // Return the canonical form
      }
    }

    // If no match found, throw detailed error
    final allValidTypes = validTransactionTypes.entries
        .map((e) => '${e.key} (or: ${e.value.join(", ")})')
        .join("\n");
    throw Exception(
        'Invalid transaction type "$type". Must be one of:\n$allValidTypes');
  }

  // Validate transaction data before sending to server
  void _validateTransactionData({
    required int bookId,
    required String transactionType,
    required String status,
    required double amount,
  }) {
    print('Validating transaction data:');
    print('Book ID: $bookId');
    print('Transaction Type: $transactionType');
    print('Status: $status');
    print('Amount: $amount');

    if (bookId <= 0) {
      throw Exception('Invalid book ID. Please select a valid book.');
    }

    // Normalize and validate transaction type
    final normalizedTransactionType =
        _normalizeTransactionType(transactionType);
    print('Normalized transaction type: $normalizedTransactionType');

    final normalizedStatus = status.toLowerCase().trim();
    if (!validStatuses.contains(normalizedStatus)) {
      throw Exception(
          'Invalid status "$status". Must be one of: ${validStatuses.join(", ")}');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }
  }

  // Fetch Transactions
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await _handleRequest(
        operation: 'Fetch transactions',
        request: () => http.get(
          Uri.parse(_baseUrl),
          headers: _getHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _transactions = data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      _errorMessage = 'Error fetching transactions: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Transaction
  Future<void> addTransaction({
    required int userId,
    required int bookId,
    required String transactionType,
    required double amount,
    required String status,
  }) async {
    _isAdding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Adding transaction with data:');
      print('User ID: $userId');
      print('Book ID: $bookId');
      print('Transaction Type: $transactionType');
      print('Amount: $amount');
      print('Status: $status');

      // Validate data before making the request
      _validateTransactionData(
        bookId: bookId,
        transactionType: transactionType,
        status: status,
        amount: amount,
      );

      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final normalizedTransactionType =
          _normalizeTransactionType(transactionType);
      final normalizedStatus = status.toLowerCase().trim();

      final body = jsonEncode({
        'user_id': userId,
        'book_id': bookId,
        'transaction_type': normalizedTransactionType,
        'amount': amount,
        'status': normalizedStatus,
      });

      print('Request body: $body');

      final response = await _handleRequest(
        operation: 'Add transaction',
        request: () => http.post(
          Uri.parse(_baseUrl),
          headers: _getHeaders(token),
          body: body,
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final newTransaction = Transaction.fromJson(json.decode(response.body));
        _transactions.add(newTransaction);
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      _errorMessage = 'Error adding transaction: $e';
      print(_errorMessage);
      rethrow;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  // Delete Transaction
  Future<void> deleteTransaction(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final response = await _handleRequest(
        operation: 'Delete transaction',
        request: () => http.delete(
          Uri.parse('$_baseUrl/$id'),
          headers: _getHeaders(token),
        ),
      );

      if (response.statusCode == 200) {
        _transactions.removeWhere((transaction) => transaction.id == id);
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      _errorMessage = 'Error deleting transaction: $e';
      print(_errorMessage);
      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // Update Transaction
  Future<void> updateTransaction({
    required int id,
    required int userId,
    required int bookId,
    required String transactionType,
    required double amount,
    required String status,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate data before making the request
      _validateTransactionData(
        bookId: bookId,
        transactionType: transactionType,
        status: status,
        amount: amount,
      );

      String? token = await _getAuthToken();
      if (token == null) throw Exception('No auth token found');

      final body = jsonEncode({
        'user_id': userId,
        'book_id': bookId,
        'transaction_type': transactionType.toLowerCase(),
        'amount': amount,
        'status': status.toLowerCase(),
      });

      final response = await _handleRequest(
        operation: 'Update transaction',
        request: () => http.put(
          Uri.parse('$_baseUrl/$id'),
          headers: _getHeaders(token),
          body: body,
        ),
      );

      if (response.statusCode == 200) {
        final updatedTransaction =
            Transaction.fromJson(json.decode(response.body));
        final index = _transactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _transactions[index] = updatedTransaction;
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      _errorMessage = 'Error updating transaction: $e';
      print(_errorMessage);
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Exception _handleErrorResponse(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      final errors = errorData['errors'] as Map<String, dynamic>?;

      if (errors != null) {
        final errorMessages = errors.values
            .map((error) => error is List ? error.first : error)
            .join('\n');
        return Exception(errorMessages);
      }

      return Exception(errorData['message'] ?? 'Unknown error occurred');
    } catch (e) {
      return Exception('Failed with status code: ${response.statusCode}');
    }
  }

  // Retrieve auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
