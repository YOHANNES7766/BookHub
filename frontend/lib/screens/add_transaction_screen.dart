import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _userIdController = TextEditingController();
  final _bookIdController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedTransactionType;
  String? _selectedStatus;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  if (transactionProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        transactionProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _buildTextField(
                      _userIdController, 'User ID', TextInputType.number),
                  const SizedBox(height: 15),
                  _buildTextField(
                      _bookIdController, 'Book ID', TextInputType.number),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    label: 'Transaction Type',
                    value: _selectedTransactionType,
                    items: ['Purchase', 'Rent'],
                    onChanged: (value) =>
                        setState(() => _selectedTransactionType = value),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                      _amountController, 'Amount', TextInputType.number),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    label: 'Status',
                    value: _selectedStatus,
                    items: ['Pending', 'Completed', 'Failed'],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value),
                  ),
                  const SizedBox(height: 25),
                  transactionProvider.isAdding
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: transactionProvider.isAdding
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    final userId =
                                        int.tryParse(_userIdController.text);
                                    final bookId =
                                        int.tryParse(_bookIdController.text);
                                    final amount =
                                        double.tryParse(_amountController.text);

                                    if (userId == null ||
                                        bookId == null ||
                                        amount == null) {
                                      _showErrorSnackbar(context,
                                          'Please enter valid numbers');
                                      return;
                                    }

                                    final navigator = Navigator.of(context);
                                    final messenger =
                                        ScaffoldMessenger.of(context);

                                    try {
                                      await transactionProvider.addTransaction(
                                        userId: userId,
                                        bookId: bookId,
                                        transactionType:
                                            _selectedTransactionType!,
                                        amount: amount,
                                        status: _selectedStatus!,
                                      );

                                      if (!mounted) return;
                                      navigator.pop();
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to add transaction: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Add Transaction',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(
      TextEditingController controller, String label, TextInputType type) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      keyboardType: type,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }

  // Helper method to build dropdowns
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _bookIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
