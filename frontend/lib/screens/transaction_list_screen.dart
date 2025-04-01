import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (ctx, transactionProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transactions'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await transactionProvider.fetchTransactions();
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await transactionProvider.fetchTransactions();
            },
            child: transactionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactionProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              transactionProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await transactionProvider.fetchTransactions();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : transactionProvider.transactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: transactionProvider.transactions.length,
                            itemBuilder: (ctx, index) {
                              final transaction =
                                  transactionProvider.transactions[index];
                              return _buildTransactionCard(ctx, transaction);
                            },
                          ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/add-transaction');
            },
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  // Build the UI for an empty list of transactions
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No transactions found. Add some transactions!',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  // Build the card for each transaction
  Widget _buildTransactionCard(BuildContext context, transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        title: Text(
          transaction.transactionType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Amount: \$${transaction.amount.toStringAsFixed(2)}\nStatus: ${transaction.status}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, transaction.id),
        ),
      ),
    );
  }

  // Show confirmation dialog before deleting a transaction
  void _confirmDelete(BuildContext context, int transactionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaction(transactionId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting transaction: $e'),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
