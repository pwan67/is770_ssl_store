import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String userId;
  final double balance;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Wallet(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
