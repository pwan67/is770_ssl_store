import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet.dart';
import '../models/wallet_transaction.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of user's wallet
  Stream<Wallet?> getWalletStream(String userId) {
    return _firestore
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Wallet.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Get transactions stream
  Stream<List<WalletTransaction>> getTransactionsStream(String walletId) {
    return _firestore
        .collection('wallets')
        .doc(walletId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromFirestore(doc))
            .toList());
  }

  // Create initial wallet for a new user
  Future<void> createWalletForUser(String userId) async {
    // Check if exists first
    final existing = await _firestore
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection('wallets').add({
        'userId': userId,
        'balance': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Perform transaction using an overarching transaction (from MockService)
  Future<void> performTransactionWithTx({
    required Transaction transaction,
    required String walletId,
    required double amount,
    required WalletTransactionType type,
    String? description,
    String? referenceId,
  }) async {
    final walletRef = _firestore.collection('wallets').doc(walletId);
    final transactionRef = walletRef.collection('transactions').doc();

    final walletSnapshot = await transaction.get(walletRef);
    if (!walletSnapshot.exists) {
      throw Exception("Wallet does not exist!");
    }

    double currentBalance = (walletSnapshot.data()?['balance'] ?? 0.0).toDouble();
    
    double newBalance = currentBalance;
    if (type == WalletTransactionType.deposit || type == WalletTransactionType.sale) {
      newBalance += amount;
    } else if (type == WalletTransactionType.withdrawal || type == WalletTransactionType.purchase) {
      if (currentBalance < amount) {
        throw Exception("Insufficient funds!");
      }
      newBalance -= amount;
    }

    // Update wallet balance
    transaction.update(walletRef, {
      'balance': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add to ledger
    transaction.set(transactionRef, {
      'amount': amount,
      'type': type.name,
      'resultingBalance': newBalance,
      'description': description,
      'referenceId': referenceId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Add transaction (deposits, purchases) using its own internal batch
  Future<void> performTransaction({
    required String walletId,
    required double amount,
    required WalletTransactionType type,
    String? description,
    String? referenceId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      await performTransactionWithTx(
        transaction: transaction,
        walletId: walletId,
        amount: amount,
        type: type,
        description: description,
        referenceId: referenceId,
      );
    });
  }
}
