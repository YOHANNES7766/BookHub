import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _messageController = TextEditingController();
  int _selectedUserId = 1;
  int _selectedBookId = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecommendationProvider>(context, listen: false)
          .fetchRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        centerTitle: true, // Center the title for better alignment
      ),
      body: recommendationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendationProvider.recommendations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: recommendationProvider.recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation =
                        recommendationProvider.recommendations[index];

                    return ListTile(
                      title: Text(recommendation.message),
                      subtitle: Text(
                          'Book ID: ${recommendation.bookId} - User ID: ${recommendation.userId}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                            context, recommendationProvider, recommendation.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddRecommendationDialog(context, recommendationProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  // UI for when there are no recommendations
  Widget _buildEmptyState() {
    return const Center(
      child: Text('No recommendations available',
          style: TextStyle(fontSize: 18, color: Colors.grey)),
    );
  }

  // Show a dialog to add a recommendation
  void _showAddRecommendationDialog(
      BuildContext context, RecommendationProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Recommendation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Recommendation Message',
                    hintText: 'Enter your recommendation message here...',
                  ),
                  maxLines: 3, // Allow multi-line input for the message
                ),
                const SizedBox(height: 10),
                _buildNumberInputField(
                  label: 'User ID',
                  onChanged: (value) {
                    _selectedUserId = int.tryParse(value) ?? 1;
                  },
                ),
                const SizedBox(height: 10),
                _buildNumberInputField(
                  label: 'Book ID',
                  onChanged: (value) {
                    _selectedBookId = int.tryParse(value) ?? 1;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_messageController.text.isNotEmpty &&
                    _selectedUserId > 0 &&
                    _selectedBookId > 0) {
                  provider.addRecommendation(
                    _selectedUserId,
                    _selectedBookId,
                    _messageController.text,
                  );
                  _messageController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields properly.'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Helper method for number input fields (User ID and Book ID)
  Widget _buildNumberInputField(
      {required String label, required Function(String) onChanged}) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  // Confirm before deleting a recommendation
  Future<void> _confirmDelete(BuildContext context,
      RecommendationProvider provider, int recommendationId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Recommendation?'),
          content: const Text(
              'Are you sure you want to delete this recommendation?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                provider.deleteRecommendation(recommendationId);
                Navigator.pop(context, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      provider.deleteRecommendation(recommendationId);
    }
  }
}
