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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (transactionProvider.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          transactionProvider.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              _userIdController,
                              'User ID',
                              TextInputType.number,
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              _bookIdController,
                              'Book ID',
                              TextInputType.number,
                              icon: Icons.book,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown(
                              label: 'Transaction Type',
                              value: _selectedTransactionType,
                              items: ['Purchase', 'Rent'],
                              onChanged: (value) => setState(
                                  () => _selectedTransactionType = value),
                              icon: Icons.swap_horiz,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              _amountController,
                              'Amount',
                              TextInputType.number,
                              icon: Icons.attach_money,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown(
                              label: 'Status',
                              value: _selectedStatus,
                              items: ['Pending', 'Completed', 'Failed'],
                              onChanged: (value) =>
                                  setState(() => _selectedStatus = value),
                              icon: Icons.info,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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
                                      final amount = double.tryParse(
                                          _amountController.text);

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
                                        await transactionProvider
                                            .addTransaction(
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
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            child: const Text(
                              'Add Transaction',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type, {
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      keyboardType: type,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 16),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
      dropdownColor: Colors.white,
      style: TextStyle(color: Colors.grey.shade800),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
