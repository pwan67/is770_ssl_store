class TransactionRecord {
  final String id;
  final String userId;
  final String type; // 'buy', 'sell', 'pawn'
  final double amount; // Baht weight or Monetary value depending on context
  final double price; // The actual fiat value transacted
  final DateTime date;
  final String description;

  TransactionRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.price,
    required this.date,
    required this.description,
  });

  factory TransactionRecord.fromMap(String id, Map<String, dynamic> data) {
    return TransactionRecord(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'unknown',
      amount: (data['amount'] ?? 0.0).toDouble(),
      price: (data['price'] ?? 0.0).toDouble(),
      date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'price': price,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}
