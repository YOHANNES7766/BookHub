import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // ✅ Added logger
import '../models/category_model.dart';
import '../services/category_service.dart';

final logger = Logger(); // ✅ Initialize logger

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch categories from API
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await CategoryService.getCategories();
    } catch (e) {
      _errorMessage = 'Error fetching categories';
      logger.e('Error fetching categories', error: e); // ✅ Replaced print
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add category
  Future<void> addCategory(String name, String? description) async {
    try {
      final newCategory = await CategoryService.addCategory(name, description);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error adding category';
      logger.e('Error adding category', error: e); // ✅ Replaced print
    }
  }

  // Delete category
  Future<void> deleteCategory(int id) async {
    try {
      await CategoryService.deleteCategory(id);
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error deleting category';
      logger.e('Error deleting category', error: e); // ✅ Replaced print
    }
  }
}
