class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'],
      title: json['title'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['createdAt']),
    );
  }
}
