class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.category,
    required this.timestamp,
  });

  final int? id;
  final double amount;
  final String currency;
  final String description;
  final String category;
  final DateTime timestamp;

  Expense copyWith({
    int? id,
    double? amount,
    String? currency,
    String? description,
    String? category,
    DateTime? timestamp,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'amount': amount,
      'currency': currency,
      'description': description,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
