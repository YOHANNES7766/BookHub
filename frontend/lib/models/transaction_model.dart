class Transaction {
  final int id;
  final int userId;
  final int bookId;
  final String transactionType;
  final double amount;
  final String status;

  Transaction({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.transactionType,
    required this.amount,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      transactionType: json['transaction_type'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
    );
  }
}
