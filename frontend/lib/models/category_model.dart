class Category {
  final int id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  // Convert JSON to Category object
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  // Convert Category object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}
