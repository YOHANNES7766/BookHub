import 'package:flutter/material.dart';
import '../providers/book_provider.dart';
import 'package:provider/provider.dart';

class EditBookScreen extends StatefulWidget {
  final String bookId; // Book ID for identifying which book to edit
  const EditBookScreen({super.key, required this.bookId});

  @override
  _EditBookScreenState createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController categoryIdController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load the book details when the screen is initialized
    _loadBookDetails();
  }

  // Load the book details
  void _loadBookDetails() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final book =
        bookProvider.books.firstWhere((book) => book.id == widget.bookId);
    titleController.text = book.title;
    authorController.text = book.author;
    categoryIdController.text = book.categoryId.toString();
  }

  void _saveChanges() {
    setState(() => isLoading = true);

    final title = titleController.text.trim();
    final author = authorController.text.trim();
    final categoryId = int.tryParse(categoryIdController.text.trim());

    if (title.isEmpty || author.isEmpty || categoryId == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.updateBook(widget.bookId, title, author, categoryId);

    setState(() => isLoading = false);
    Navigator.pop(context); // Go back to the previous screen after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        centerTitle: true, // Center the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Book Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: titleController,
              label: 'Title',
              icon: Icons.book,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: authorController,
              label: 'Author',
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: categoryIdController,
              label: 'Category ID',
              icon: Icons.category,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Helper method to build text fields with icons
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
