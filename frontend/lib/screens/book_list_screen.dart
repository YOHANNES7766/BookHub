import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'add_book_screen.dart';
import 'category_screen.dart';
import 'recommendation_screen.dart';
import 'transaction_list_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  BookListScreenState createState() => BookListScreenState();
}

class BookListScreenState extends State<BookListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookProvider>(context, listen: false).fetchBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.recommend),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RecommendationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.payment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TransactionListScreen()),
              );
            },
          ),
        ],
      ),
      body: bookProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookProvider.books.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: bookProvider.books.length,
                  itemBuilder: (context, index) {
                    final book = bookProvider.books[index];
                    return _buildBookTile(book, bookProvider);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBookScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No books available!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTile(Book book, BookProvider bookProvider) {
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(
        book.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(book.author),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final shouldDelete = await _confirmDelete(context);
          if (shouldDelete && mounted) {
            await bookProvider.deleteBook(book.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Book deleted')),
            );
          }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text('Are you sure you want to delete this book?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        )) ??
        false;
  }
}
