import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import 'add_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true, // Center the title for a better layout
        elevation: 0, // Remove app bar shadow for a clean look
      ),
      body: categoryProvider.isLoading
          ? _buildLoadingState()
          : categoryProvider.errorMessage != null
              ? _buildErrorState(categoryProvider.errorMessage!)
              : categoryProvider.categories.isEmpty
                  ? _buildEmptyState()
                  : _buildCategoryList(categoryProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Show loading state with a spinner
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Show empty state when no categories exist
  Widget _buildEmptyState() {
    return const Center(
      child: Text('No categories available',
          style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }

  // Show error state with a more user-friendly design
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          Text(errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Provider.of<CategoryProvider>(context, listen: false)
                  .fetchCategories();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Show category list with a delete action and better list design
  Widget _buildCategoryList(CategoryProvider categoryProvider) {
    return ListView.builder(
      itemCount: categoryProvider.categories.length,
      itemBuilder: (context, index) {
        final category = categoryProvider.categories[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(category.description ?? 'No description available',
                style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  _confirmDelete(context, categoryProvider, category.id),
            ),
          ),
        );
      },
    );
  }

  // Confirm deletion before removing a category
  Future<void> _confirmDelete(
      BuildContext context, CategoryProvider provider, int categoryId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category?'),
          content: const Text(
              'Are you sure you want to delete this category? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await provider.deleteCategory(categoryId);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Category deleted')));
    }
  }
}
