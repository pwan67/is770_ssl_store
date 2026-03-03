import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gold_rate.dart';
import '../models/product.dart';
import '../models/news_item.dart';
import '../models/gold_asset.dart';
import '../models/gold_transaction.dart';
import '../models/appointment.dart';

import 'package:firebase_auth/firebase_auth.dart';

class MockService {
  // Singleton pattern
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal();

  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Mock News Data
  List<NewsItem> getNews() {
    return [
      NewsItem(
        id: '1',
        title: 'Why Gold is the Best Safe Haven Asset?',
        summary: 'In times of economic uncertainty, gold is the answer. Maintain your wealth value...',
        imageUrl: 'https://via.placeholder.com/150x150/FFD700/000000?text=Safe+Haven',
        date: DateTime.now().subtract(const Duration(days: 1)),
        content: 'Full article content about safe haven...',
      ),
      NewsItem(
        id: '2',
        title: 'Gold Price Analysis: Upward Trend continues',
        summary: 'Experts predict continued growth for gold prices this quarter due to global factors.',
        imageUrl: 'https://via.placeholder.com/150x150/800000/FFFFFF?text=Price+Up',
        date: DateTime.now().subtract(const Duration(days: 3)),
        content: 'Full analysis content...',
      ),
      NewsItem(
        id: '3',
        title: 'Understanding 96.5% vs 99.99% Gold',
        summary: 'What is the difference and which one is right for investment? Let us explain.',
        imageUrl: 'https://via.placeholder.com/150x150/FFA000/000000?text=Gold+Standard',
        date: DateTime.now().subtract(const Duration(days: 5)),
        content: 'Full educational content...',
      ),
    ];
  }

  // Live Cloud Gold Rate Stream
  Stream<GoldRate> getGoldRateStream() {
    return FirebaseFirestore.instance
        .collection('market')
        .doc('gold_rate')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        final now = DateTime.now();
        int hour = now.hour;
        String period = 'AM';
        if (hour >= 12) {
          period = 'PM';
          if (hour > 12) hour -= 12;
        }
        if (hour == 0) hour = 12;
        String formattedTime = '$hour:${now.minute.toString().padLeft(2, '0')} $period';

        return GoldRate(
          buyPrice: 40000.0,
          sellPrice: 40100.0,
          timestamp: now,
          updateTime: formattedTime,
          trend: 'stable',
        );
      }
      
      final data = snapshot.data()!;
      final buy = (data['buyPrice'] ?? 40000).toDouble();
      final sell = (data['sellPrice'] ?? 40100).toDouble();
      
      Timestamp? ts = data['timestamp'] as Timestamp?;
      final trend = data['trend'] as String? ?? 'stable';
      final dateTime = ts?.toDate() ?? DateTime.now();

      int hour = dateTime.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      
      final formattedTimeStr = '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';

      return GoldRate(
        buyPrice: buy,
        sellPrice: sell,
        timestamp: dateTime,
        updateTime: formattedTimeStr,
        trend: trend,
      );
    });
  }

  // Cloud Assets & Transactions Streams
  Stream<double> getWalletBalanceStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0.0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return 0.0;
      return (snapshot.data()!['walletBalance'] ?? 0.0 as num).toDouble();
    });
  }

  Future<void> addFunds(double amount) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'walletBalance': FieldValue.increment(amount)
    }, SetOptions(merge: true));
  }

  Future<void> withdrawFunds(double amount) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    
    // We ideally should check the balance transactionally, 
    // but for this mock service a simple read then write is okay or just rely on UI validation.
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final currentBalance = (doc.data()?['walletBalance'] ?? 0.0 as num).toDouble();
    
    if (currentBalance < amount) {
      throw Exception('Insufficient funds to withdraw');
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'walletBalance': FieldValue.increment(-amount)
    }, SetOptions(merge: true));
  }

  Stream<List<GoldAsset>> getMemberAssetsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GoldAsset(
          id: doc.id,
          name: data['name'] ?? 'Unknown Asset',
          weight: (data['weight'] ?? 0 as num).toDouble(),
          category: data['category'] ?? 'General',
          acquisitionDate: (data['acquisitionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          acquisitionPrice: (data['acquisitionPrice'] ?? 0 as num).toDouble(),
          status: data['status'] ?? 'owned',
          loanAmount: data['loanAmount'] != null ? (data['loanAmount'] as num).toDouble() : null,
          pawnDate: (data['pawnDate'] as Timestamp?)?.toDate(),
          dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
          interestRate: data['interestRate'] != null ? (data['interestRate'] as num).toDouble() : null,
        );
      }).toList();
    });
  }

  Stream<List<GoldTransaction>> getTransactionHistoryStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Simple string to enum mapping
        TransactionType type = TransactionType.buy;
        if (data['type'] == 'sell') type = TransactionType.sell;
        else if (data['type'] == 'pawn') type = TransactionType.pawn;
        else if (data['type'] == 'redeem') type = TransactionType.redeem;

        return GoldTransaction(
          id: doc.id,
          assetId: data['assetId'] ?? '',
          type: type,
          amount: (data['amount'] ?? 0 as num).toDouble(),
          weight: (data['weight'] ?? 0 as num).toDouble(),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          details: data['details'] ?? '',
        );
      }).toList();
    });
  }

  Future<void> createTransaction({
    required String assetName,
    required double weight,
    required double amount,
    required TransactionType type,
    String? category,
    String? productId, // For simulated stock reduction
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    if (type == TransactionType.buy) {
      // Check Wallet Balance First
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final currentBalance = (userDoc.data()?['walletBalance'] ?? 0.0 as num).toDouble();
      
      if (currentBalance < amount) {
        throw Exception('Insufficient funds. Please deposit money into your wallet.');
      }

      // Deduct from wallet
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'walletBalance': FieldValue.increment(-amount)
      }, SetOptions(merge: true));

      // Real Database Write: Deduct Stock
      if (productId != null) {
        try {
           final docRef = FirebaseFirestore.instance.collection('products').doc(productId);
           // Ask Firestore to atomically guarantee the stock goes down by exactly 1
           await docRef.update({'stock': FieldValue.increment(-1)});
        } catch (e) {
          print('Error reducing stock: $e');
        }
      }

      // Convert to Firestore Document
      final assetDoc = {
        'name': assetName,
        'weight': weight,
        'category': category ?? 'General',
        'acquisitionDate': FieldValue.serverTimestamp(),
        'acquisitionPrice': amount,
        'status': 'owned',
      };
      
      // Write to Cloud Portfolio
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('assets')
          .doc('a$id')
          .set(assetDoc);
    }

    final transactionDoc = {
      'assetId': 'a$id',
      'type': type.name,
      'amount': amount,
      'weight': weight,
      'timestamp': FieldValue.serverTimestamp(),
      'details': '${type.name.toUpperCase()}: $assetName ($weight Baht)',
    };
    
    // Write to Cloud Transaction History
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc('t$id')
        .set(transactionDoc);
        
    // Write to global transactions collection for store admin visibility
    final globalTxDoc = Map<String, dynamic>.from(transactionDoc);
    globalTxDoc['userId'] = uid;
    globalTxDoc['userEmail'] = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';
    
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc('t$id')
        .set(globalTxDoc);
  }

  Future<void> sellAsset({
    required GoldAsset asset,
    required double sellPrice,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // 1. Remove the asset from the user's portfolio
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .doc(asset.id)
        .delete();

    // 1.5 Add funds to wallet
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'walletBalance': FieldValue.increment(sellPrice)
    }, SetOptions(merge: true));

    // 2. Create the Sell Transaction record
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final transactionDoc = {
      'assetId': asset.id,
      'type': TransactionType.sell.name,
      'amount': sellPrice,
      'weight': asset.weight,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'SELL: ${asset.name} (${asset.weight} Baht)',
    };

    // Write to user transactions
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc('t$id')
        .set(transactionDoc);

    // Write to global transactions for store admins
    final globalTxDoc = Map<String, dynamic>.from(transactionDoc);
    globalTxDoc['userId'] = uid;
    globalTxDoc['userEmail'] = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc('t$id')
        .set(globalTxDoc);
  }

  Future<void> pawnAsset({
    required GoldAsset asset,
    required double loanAmount,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await Future.delayed(const Duration(seconds: 1));

    // 1. Update asset status to 'pawned' and attach loan data
    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 30));
    final interestRate = 0.0125; // 1.25% monthly default

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .doc(asset.id)
        .update({
      'status': 'pawned',
      'loanAmount': loanAmount,
      'pawnDate': FieldValue.serverTimestamp(),
      'dueDate': Timestamp.fromDate(dueDate),
      'interestRate': interestRate,
    });

    // 2. Add loan funds to wallet
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'walletBalance': FieldValue.increment(loanAmount)
    }, SetOptions(merge: true));

    // 3. Create Pawn Transaction
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final transactionDoc = {
      'assetId': asset.id,
      'type': TransactionType.pawn.name,
      'amount': loanAmount,
      'weight': asset.weight,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'PAWN: ${asset.name} (${asset.weight} Baht)',
      'userId': uid,
      'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email',
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc('t$id')
        .set(transactionDoc);

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc('t$id')
        .set(transactionDoc);
  }

  Future<void> redeemAsset({
    required GoldAsset asset,
    required double totalOwed,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    // 1. Check wallet balance
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    double currentBalance = (userDoc.data()?['walletBalance'] ?? 0.0).toDouble();

    if (currentBalance < totalOwed) {
      throw Exception('Insufficient funds to redeem asset');
    }

    await Future.delayed(const Duration(seconds: 1));

    // 2. Clear loan fields and revert status to 'owned'
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .doc(asset.id)
        .update({
      'status': 'owned',
      'loanAmount': FieldValue.delete(),
      'pawnDate': FieldValue.delete(),
      'dueDate': FieldValue.delete(),
      'interestRate': FieldValue.delete(),
    });

    // 3. Deduct total owed from wallet
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(-totalOwed)
    });

    // 4. Create Redeem Transaction
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final transactionDoc = {
      'assetId': asset.id,
      'type': TransactionType.redeem.name,
      'amount': totalOwed, // Representing cash paid
      'weight': asset.weight,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'REDEEM: ${asset.name} (${asset.weight} Baht)',
      'userId': uid,
      'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email',
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc('t$id')
        .set(transactionDoc);

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc('t$id')
        .set(transactionDoc);
  }

  double calculatePawnLoan(double weight, double currentBuyPrice) {
    // Standard pawn shop rule: ~85-90% of buyback value
    return (weight * currentBuyPrice) * 0.85;
  }

  Map<String, double> calculatePawnOwed(double principal, DateTime pawnDate, DateTime dueDate, double monthlyRate) {
    final now = DateTime.now();
    
    // Calculate standard interest
    int daysPawned = now.difference(pawnDate).inDays;
    if (daysPawned < 1) daysPawned = 1; // minimum 1 day interest for UI testing
    double standardInterest = principal * monthlyRate * (daysPawned / 30.0);
    
    // Calculate penalty interest if overdue
    double penaltyInterest = 0.0;
    if (now.isAfter(dueDate)) {     
      int daysOverdue = now.difference(dueDate).inDays;
      // Example Penalty: 2% per month overdue
      double penaltyRate = 0.02;
      penaltyInterest = principal * penaltyRate * (daysOverdue / 30.0);
    }
    
    return {
      'principal': principal,
      'standardInterest': standardInterest,
      'penaltyInterest': penaltyInterest,
      'totalOwed': principal + standardInterest + penaltyInterest,
    };
  }

  // -- Appointments --
  
  Stream<List<Appointment>> getAppointmentsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Appointment.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('appointments')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'scheduled') // only count active ones
        .get();

    return snapshot.docs.map((doc) => Appointment.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> createAppointment({
    required GoldAsset asset,
    required DateTime appointmentDate,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await Future.delayed(const Duration(seconds: 1));

    // Capacity Check
    final isoDateStart = appointmentDate.toIso8601String();
    // In our 30-min slot logic, exact match on the time is enough
    final existingParams = await FirebaseFirestore.instance
        .collectionGroup('appointments')
        .where('date', isEqualTo: isoDateStart)
        .where('status', isEqualTo: 'scheduled')
        .get();
        
    if (existingParams.docs.length >= 2) {
      throw Exception('This time slot has reached maximum capacity.');
    }

    // 1. Create Appointment Document
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final appointment = Appointment(
      id: id,
      userId: uid,
      assetId: asset.id,
      assetName: asset.name,
      date: appointmentDate,
      status: 'scheduled',
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .doc('apt$id')
        .set(appointment.toMap());

    // 2. Update Asset Status to 'pickup_scheduled'
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .doc(asset.id)
        .update({
      'status': 'pickup_scheduled',
    });
  }

  // Live Cloud Products Stream
  Stream<List<Product>> getProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? 'Unknown Product',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0 as num).toDouble(),
          weight: (data['weight'] ?? 0 as num).toDouble(),
          laborFee: (data['laborFee'] ?? 0 as num).toDouble(),
          stock: data['stock'] ?? 0,
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? 'General',
        );
      }).toList();
    });
  }

  // Search and Filter helper (to be used locally on the streamed list)
  List<Product> filterProducts(List<Product> allProducts, String query) {
    if (query.isEmpty) return allProducts;
    return allProducts.where((p) =>
      p.name.toLowerCase().contains(query.toLowerCase()) ||
      p.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
