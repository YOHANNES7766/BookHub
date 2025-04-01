import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage; // ✅ Added error handling

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage; // ✅ Expose error messages

  // Fetch categories from API
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await CategoryService.getCategories();
    } catch (e) {
      _errorMessage = 'Error fetching categories';
      print('Error fetching categories: $e');
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
      print('Error adding category: $e');
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
      print('Error deleting category: $e');
    }
  }
}
