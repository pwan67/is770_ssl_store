enum TransactionType { buy, sell, pawn }

class GoldTransaction {
  final String id;
  final String assetId;
  final TransactionType type;
  final double amount; // THB
  final double weight; // Baht
  final DateTime timestamp;
  final String details;

  GoldTransaction({
    required this.id,
    required this.assetId,
    required this.type,
    required this.amount,
    required this.weight,
    required this.timestamp,
    required this.details,
  });
}
