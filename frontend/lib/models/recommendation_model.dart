class Recommendation {
  final int id;
  final int userId;
  final int bookId;
  final String message;

  Recommendation({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.message,
  });

  // Convert JSON to Model
  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      message: json['recommendation_message'],
    );
  }

  // Convert Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'recommendation_message': message,
    };
  }
}
