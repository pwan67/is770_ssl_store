import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import '../models/gold_rate.dart';
import '../models/product.dart';
import '../models/news_item.dart';
import '../models/gold_asset.dart';
import '../models/gold_transaction.dart';
import '../models/appointment.dart';
import '../models/notification_item.dart';
import '../models/gold_savings.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'wallet_service.dart';
import 'id_generator_service.dart';
import '../models/wallet_transaction.dart';

class MockService {
  final WalletService _walletService = WalletService();
  final IdGeneratorService _idGeneratorService = IdGeneratorService();

  // Singleton pattern
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal();

  // Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _generateInitialNews() async {
    final batch = FirebaseFirestore.instance.batch();
    final newsList = [
      {
        'title': 'Why Gold is the Best Safe Haven Asset?',
        'summary':
            'In times of economic uncertainty, gold is the answer. Maintain your wealth value...',
        'imageUrl':
            'https://via.placeholder.com/150x150/FFD700/000000?text=Safe+Haven',
        'date': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'content': 'Full article content about safe haven...',
      },
      {
        'title': 'Gold Price Analysis: Upward Trend continues',
        'summary':
            'Experts predict continued growth for gold prices this quarter due to global factors.',
        'imageUrl':
            'https://via.placeholder.com/150x150/800000/FFFFFF?text=Price+Up',
        'date': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        'content': 'Full analysis content...',
      },
      {
        'title': 'Understanding 96.5% vs 99.99% Gold',
        'summary':
            'What is the difference and which one is right for investment? Let us explain.',
        'imageUrl':
            'https://via.placeholder.com/150x150/FFA000/000000?text=Gold+Standard',
        'date': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
        'content': 'Full educational content...',
      },
    ];

    for (int i = 0; i < newsList.length; i++) {
      final docRef = FirebaseFirestore.instance
          .collection('news')
          .doc('news_$i');
      batch.set(docRef, newsList[i]);
    }
    await batch.commit();
  }

  // Live Cloud News Stream
  Stream<List<NewsItem>> getNewsStream() {
    final collection = FirebaseFirestore.instance.collection('news');

    // Auto-generate if empty
    collection.limit(1).get().then((snapshot) {
      if (snapshot.docs.isEmpty) {
        _generateInitialNews();
      }
    });

    return collection.orderBy('date', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NewsItem(
          id: doc.id,
          title: data['title'] ?? 'No Title',
          summary: data['summary'] ?? '',
          imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150x150',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          content: data['content'] ?? '',
        );
      }).toList();
    });
  }

  // Live Cloud Promotions Stream
  Future<void> _generateInitialPromotions() async {
    final batch = FirebaseFirestore.instance.batch();
    final promos = [
      {
        'title': '50% Off Labor Fee\nApp Launch Special',
        'color': 0xFF800000,
        'textColor': 0xFFFFFFFF,
        'image':
            'https://via.placeholder.com/600x200/800000/FFFFFF?text=50%25+OFF',
      },
      {
        'title': 'Golden Dragon Collection\nLunar New Year',
        'color': 0xFFFFD700,
        'textColor': 0xFF000000,
        'image':
            'https://via.placeholder.com/600x200/FFD700/000000?text=Dragon+Collection',
      },
      {
        'title': 'Easy Gold Savings\nStart at 100 THB',
        'color': 0xFF1E88E5,
        'textColor': 0xFFFFFFFF,
        'image':
            'https://via.placeholder.com/600x200/1E88E5/FFFFFF?text=Saving+Plan',
      },
    ];

    for (int i = 0; i < promos.length; i++) {
      final docRef = FirebaseFirestore.instance
          .collection('promotions')
          .doc('promo_$i');
      batch.set(docRef, promos[i]);
    }
    await batch.commit();
  }

  // Live Cloud Promotions Stream
  Stream<List<Map<String, dynamic>>> getPromotionsStream() {
    final collection = FirebaseFirestore.instance.collection('promotions');

    // Auto-generate if empty
    collection.limit(1).get().then((snapshot) {
      if (snapshot.docs.isEmpty) {
        _generateInitialPromotions();
      }
    });

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'color': data['color'] ?? 0xFF800000,
          'textColor': data['textColor'] ?? 0xFFFFFFFF,
          'image': data['image'],
        };
      }).toList();
    });
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
            String formattedTime =
                '$hour:${now.minute.toString().padLeft(2, '0')} $period';

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

          final formattedTimeStr =
              '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';

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

    return _walletService
        .getWalletStream(uid)
        .map((wallet) => wallet?.balance ?? 0.0);
  }

  Future<void> addFunds(double amount) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    // Ensure wallet exists
    await _walletService.createWalletForUser(uid);

    // Find wallet ID
    final walletQuery = await FirebaseFirestore.instance
        .collection('wallets')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (walletQuery.docs.isEmpty) throw Exception('Wallet not found');
    final walletId = walletQuery.docs.first.id;

    await _walletService.performTransaction(
      walletId: walletId,
      amount: amount,
      type: WalletTransactionType.deposit,
      description: 'Wallet Top-Up',
    );

    // Add a notification
    final notifId = DateTime.now().millisecondsSinceEpoch.toString();
    final notifRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc('n_$notifId');
    final formatter = NumberFormat('#,##0.00');
    final notif = NotificationItem(
      id: notifId,
      title: 'Wallet Top-Up',
      message:
          'Successfully deposited ฿${formatter.format(amount)} into your wallet.',
      type: 'store',
      timestamp: DateTime.now(),
      isRead: false,
    );
    await notifRef.set(notif.toMap());
  }

  Future<void> withdrawFunds(double amount) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final walletQuery = await FirebaseFirestore.instance
        .collection('wallets')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (walletQuery.docs.isEmpty) throw Exception('Wallet not found');
    final walletId = walletQuery.docs.first.id;

    await _walletService.performTransaction(
      walletId: walletId,
      amount: amount,
      type: WalletTransactionType.withdrawal,
      description: 'Wallet Withdrawal',
    );

    // Add a notification
    final notifId = DateTime.now().millisecondsSinceEpoch.toString();
    final notifRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc('n_$notifId');
    final formatter = NumberFormat('#,##0.00');
    final notif = NotificationItem(
      id: notifId,
      title: 'Wallet Withdrawal',
      message:
          'Successfully withdrew ฿${formatter.format(amount)} from your wallet.',
      type: 'store',
      timestamp: DateTime.now(),
      isRead: false,
    );
    await notifRef.set(notif.toMap());
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data() ?? {};
  }

  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');
    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName('$firstName $lastName'.trim());
    }
  }

  Future<String> uploadProfilePicture(
    Uint8List fileBytes,
    String extension,
  ) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final ref = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child('$uid.$extension');
    final uploadTask = await ref.putData(
      fileBytes,
      SettableMetadata(contentType: 'image/$extension'),
    );
    final url = await uploadTask.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'photoUrl': url,
    }, SetOptions(merge: true));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePhotoURL(url);
    }
    return url;
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
              acquisitionDate:
                  (data['acquisitionDate'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              acquisitionPrice: (data['acquisitionPrice'] ?? 0 as num)
                  .toDouble(),
              status: data['status'] ?? 'owned',
              loanAmount: data['loanAmount'] != null
                  ? (data['loanAmount'] as num).toDouble()
                  : null,
              pawnDate: (data['pawnDate'] as Timestamp?)?.toDate(),
              dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
              interestRate: data['interestRate'] != null
                  ? (data['interestRate'] as num).toDouble()
                  : null,
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
            if (data['type'] == 'sell')
              type = TransactionType.sell;
            else if (data['type'] == 'pawn')
              type = TransactionType.pawn;
            else if (data['type'] == 'redeem')
              type = TransactionType.redeem;
            else if (data['type'] == 'savings_deposit')
              type = TransactionType.savings_deposit;
            else if (data['type'] == 'savings_withdraw')
              type = TransactionType.savings_withdraw;

            return GoldTransaction(
              id: doc.id,
              assetId: data['assetId'] ?? '',
              type: type,
              amount: (data['amount'] ?? 0 as num).toDouble(),
              weight: (data['weight'] ?? 0 as num).toDouble(),
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              details: data['details'] ?? '',
            );
          }).toList();
        });
  }

  Stream<int> getRewardPointsStream() {
    return getTransactionHistoryStream().map((transactions) {
      double totalSpend = 0.0;
      for (var tx in transactions) {
        if (tx.type == TransactionType.buy) {
          totalSpend += tx.amount;
        }
      }
      return totalSpend ~/ 1000;
    });
  }

  Future<void> _generateInitialNotifications(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final notifs = [
      NotificationItem(
        id: 'n1',
        title: 'Pawn Expiring Soon',
        message: 'Your pawn asset "Gold Chain 1 Baht" expires in 3 days.',
        type: 'pawn',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationItem(
        id: 'n2',
        title: 'Item in Cart',
        message: 'You left a 1 Baht Gold Bar in your cart!',
        type: 'cart',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationItem(
        id: 'n3',
        title: 'Emergency Store Update',
        message: 'Notice: Store closed today due to heavy flooding.',
        type: 'store',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      NotificationItem(
        id: 'n4',
        title: 'Upcoming Appointment',
        message: 'Reminder: You have a pickup appointment tomorrow at 10:30.',
        type: 'appointment',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: 'n5',
        title: 'Price Alert',
        message: 'Gold price has dropped to your target of ฿40,000.',
        type: 'price',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
      ),
    ];

    for (var n in notifs) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(n.id);
      batch.set(docRef, n.toMap());
    }
    await batch.commit();
  }

  Stream<List<NotificationItem>> getNotificationsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');

    // Auto-generate if empty
    collection.limit(1).get().then((snapshot) {
      if (snapshot.docs.isEmpty) {
        _generateInitialNotifications(uid);
      }
    });

    return collection.orderBy('timestamp', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => NotificationItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    final uid = currentUserId;
    if (uid == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
    final unreadDocs = await collection.where('isRead', isEqualTo: false).get();

    if (unreadDocs.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> clearAllNotifications() async {
    final uid = currentUserId;
    if (uid == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
    final allDocs = await collection.get();

    if (allDocs.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in allDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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

    String prefix = 'TXN'; // Default fallback
    if (type == TransactionType.buy)
      prefix = 'BUY';
    else if (type == TransactionType.sell)
      prefix = 'SEL';
    else if (type == TransactionType.pawn)
      prefix = 'PWN';
    else if (type == TransactionType.redeem)
      prefix = 'RED';

    final id = await _idGeneratorService.generateId('tx_counter', prefix);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (type == TransactionType.buy) {
          final walletQuery = await FirebaseFirestore.instance
              .collection('wallets')
              .where('userId', isEqualTo: uid)
              .limit(1)
              .get();
          if (walletQuery.docs.isEmpty)
            throw Exception('Wallet not found. Please top up first.');

          // 1. Read Product Stock if applicable
          DocumentSnapshot? productDoc;
          if (productId != null) {
            productDoc = await transaction.get(
              FirebaseFirestore.instance.collection('products').doc(productId),
            );
            if (!productDoc.exists) throw Exception('Product not found.');
            if ((productDoc.data() as Map<String, dynamic>)['stock'] <= 0)
              throw Exception('Product is out of stock.');
          }

          // 2. Perform Wallet Transaction (Deduct Funds)
          await _walletService.performTransactionWithTx(
            transaction: transaction,
            walletId: walletQuery.docs.first.id,
            amount: amount,
            type: WalletTransactionType.purchase,
            description: 'Purchase: $assetName',
          );

          // 3. Deduct Stock
          if (productId != null && productDoc != null) {
            transaction.update(productDoc.reference, {
              'stock': FieldValue.increment(-1),
            });
          }

          // 4. Create Asset in Portfolio
          final assetRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('assets')
              .doc('a$id');

          final assetDoc = {
            'name': assetName,
            'weight': weight,
            'category': category ?? 'General',
            'acquisitionDate': FieldValue.serverTimestamp(),
            'acquisitionPrice': amount,
            'status': 'owned',
          };
          transaction.set(assetRef, assetDoc);
        }

        // 5. Create Transaction Ledger (User specific)
        final userTxRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc('t$id');

        final transactionDoc = {
          'assetId': 'a$id',
          'type': type.name,
          'amount': amount,
          'weight': weight,
          'timestamp': FieldValue.serverTimestamp(),
          'details': '${type.name.toUpperCase()}: $assetName ($weight Baht)',
        };
        transaction.set(userTxRef, transactionDoc);

        // 6. Create Global Transaction Record
        final globalTxRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc('t$id');

        final globalTxDoc = Map<String, dynamic>.from(transactionDoc);
        globalTxDoc['userId'] = uid;
        globalTxDoc['userEmail'] =
            FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';
        transaction.set(globalTxRef, globalTxDoc);

        // 7. Add Notification
        final notifId = DateTime.now().millisecondsSinceEpoch.toString();
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc('n_$notifId');
        final formatter = NumberFormat('#,##0.00');
        final notif = NotificationItem(
          id: notifId,
          title: 'Transaction Successful',
          message:
              'Successfully completed ${type.name} for $assetName (${weight.toStringAsFixed(2)} Baht).',
          type: type == TransactionType.buy ? 'store' : 'pawn',
          timestamp: DateTime.now(),
          isRead: false,
        );
        transaction.set(notifRef, notif.toMap());
      });
    } catch (e) {
      print('Transaction failed: $e');
      rethrow;
    }
  }

  Future<void> sellAsset({
    required GoldAsset asset,
    required double sellPrice,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final walletQuery = await FirebaseFirestore.instance
            .collection('wallets')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();
        if (walletQuery.docs.isEmpty) throw Exception('Wallet not found');

        // 1. Get asset ref to delete
        final assetRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('assets')
            .doc(asset.id);

        // Check if asset exists first
        final assetDoc = await transaction.get(assetRef);
        if (!assetDoc.exists) throw Exception('Asset not found in portfolio.');

        // 2. Perform Wallet Transaction (Add Funds)
        await _walletService.performTransactionWithTx(
          transaction: transaction,
          walletId: walletQuery.docs.first.id,
          amount: sellPrice,
          type: WalletTransactionType.sale,
          description: 'Asset Sale: ${asset.name}',
        );

        // 3. Remove the asset from the user's portfolio
        transaction.delete(assetRef);

        // 4. Create the Sell Transaction record
        final id = await _idGeneratorService.generateId('tx_counter', 'SEL');

        final userTxRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc('t$id');

        final transactionDoc = {
          'assetId': asset.id,
          'type': TransactionType.sell.name,
          'amount': sellPrice,
          'weight': asset.weight,
          'timestamp': FieldValue.serverTimestamp(),
          'details': 'SELL: ${asset.name} (${asset.weight} Baht)',
        };

        // Write to user transactions
        transaction.set(userTxRef, transactionDoc);

        // Write to global transactions for store admins
        final globalTxRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc('t$id');

        final globalTxDoc = Map<String, dynamic>.from(transactionDoc);
        globalTxDoc['userId'] = uid;
        globalTxDoc['userEmail'] =
            FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';

        transaction.set(globalTxRef, globalTxDoc);

        // 5. Add a notification
        final notifId = DateTime.now().millisecondsSinceEpoch.toString();
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc('n_$notifId');
        final formatter = NumberFormat('#,##0.00');
        final notif = NotificationItem(
          id: notifId,
          title: 'Asset Sold',
          message:
              'Successfully sold ${asset.name} for ฿${formatter.format(sellPrice)}.',
          type: 'store',
          timestamp: DateTime.now(),
          isRead: false,
        );
        transaction.set(notifRef, notif.toMap());
      });
    } catch (e) {
      print('Sell Transaction failed: $e');
      rethrow;
    }
  }

  Future<void> pawnAsset({
    required GoldAsset asset,
    required double loanAmount,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final walletQuery = await FirebaseFirestore.instance
            .collection('wallets')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();
        if (walletQuery.docs.isEmpty) throw Exception('Wallet not found');

        // 1. Get asset ref to verify and update
        final assetRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('assets')
            .doc(asset.id);

        final assetDoc = await transaction.get(assetRef);
        if (!assetDoc.exists) throw Exception('Asset not found in portfolio.');

        // 2. Perform Wallet Transaction (Add Loan Funds)
        await _walletService.performTransactionWithTx(
          transaction: transaction,
          walletId: walletQuery.docs.first.id,
          amount: loanAmount,
          type: WalletTransactionType.deposit,
          description: 'Pawn Loan: ${asset.name}',
        );

        // 3. Update asset status to 'pawned' and attach loan data
        final now = DateTime.now();
        final dueDate = now.add(const Duration(days: 30));
        final interestRate = 0.0125; // 1.25% monthly default

        transaction.update(assetRef, {
          'status': 'pawned',
          'loanAmount': loanAmount,
          'pawnDate': FieldValue.serverTimestamp(),
          'dueDate': Timestamp.fromDate(dueDate),
          'interestRate': interestRate,
        });

        // 4. Create Pawn Transaction
        final id = await _idGeneratorService.generateId('tx_counter', 'PWN');

        final userTxRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc('t$id');

        final transactionDoc = {
          'assetId': asset.id,
          'type': TransactionType.pawn.name,
          'amount': loanAmount,
          'weight': asset.weight,
          'timestamp': FieldValue.serverTimestamp(),
          'details': 'PAWN: ${asset.name} (${asset.weight} Baht)',
          'userId': uid,
          'userEmail':
              FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email',
        };

        transaction.set(userTxRef, transactionDoc);

        final globalTxRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc('t$id');

        transaction.set(globalTxRef, transactionDoc);

        // 5. Add a notification
        final notifId = DateTime.now().millisecondsSinceEpoch.toString();
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc('n_$notifId');
        final formatter = NumberFormat('#,##0.00');
        final notif = NotificationItem(
          id: notifId,
          title: 'Pawn Successful',
          message:
              'Successfully pawned ${asset.name} for a loan of ฿${formatter.format(loanAmount)}.',
          type: 'pawn',
          timestamp: DateTime.now(),
          isRead: false,
        );
        transaction.set(notifRef, notif.toMap());
      });
    } catch (e) {
      print('Pawn Transaction failed: $e');
      rethrow;
    }
  }

  Future<void> redeemAsset({
    required GoldAsset asset,
    required double totalOwed,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1 & 3 Check wallet balance & Deduct total owed from wallet safely
        final walletQuery = await FirebaseFirestore.instance
            .collection('wallets')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();
        if (walletQuery.docs.isEmpty) throw Exception('Wallet not found');

        // Verify Asset exists and is pawned
        final assetRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('assets')
            .doc(asset.id);

        final assetDoc = await transaction.get(assetRef);
        if (!assetDoc.exists) throw Exception('Asset not found in portfolio.');
        if ((assetDoc.data() as Map<String, dynamic>)['status'] != 'pawned') {
          throw Exception('Asset is not currently pawned.');
        }

        await _walletService.performTransactionWithTx(
          transaction: transaction,
          walletId: walletQuery.docs.first.id,
          amount: totalOwed,
          type: WalletTransactionType.withdrawal,
          description: 'Pawn Redemption: ${asset.name}',
        );

        // 2. Clear loan fields and revert status to 'owned'
        transaction.update(assetRef, {
          'status': 'owned',
          'loanAmount': FieldValue.delete(),
          'pawnDate': FieldValue.delete(),
          'dueDate': FieldValue.delete(),
          'interestRate': FieldValue.delete(),
        });

        // 4. Create Redeem Transaction
        final id = await _idGeneratorService.generateId('tx_counter', 'RED');

        final userTxRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc('t$id');

        final transactionDoc = {
          'assetId': asset.id,
          'type': TransactionType.redeem.name,
          'amount': totalOwed, // Representing cash paid
          'weight': asset.weight,
          'timestamp': FieldValue.serverTimestamp(),
          'details': 'REDEEM: ${asset.name} (${asset.weight} Baht)',
          'userId': uid,
          'userEmail':
              FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email',
        };

        transaction.set(userTxRef, transactionDoc);

        final globalTxRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc('t$id');

        transaction.set(globalTxRef, transactionDoc);

        // 5. Add a notification
        final notifId = DateTime.now().millisecondsSinceEpoch.toString();
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc('n_$notifId');
        final formatter = NumberFormat('#,##0.00');
        final notif = NotificationItem(
          id: notifId,
          title: 'Asset Redeemed',
          message:
              'Successfully redeemed ${asset.name}. Total paid: ฿${formatter.format(totalOwed)}.',
          type: 'pawn',
          timestamp: DateTime.now(),
          isRead: false,
        );
        transaction.set(notifRef, notif.toMap());
      });
    } catch (e) {
      print('Redeem Transaction failed: $e');
      rethrow;
    }
  }

  double calculatePawnLoan(double weight, double currentBuyPrice) {
    // Standard pawn shop rule: ~85-90% of buyback value
    return (weight * currentBuyPrice) * 0.85;
  }

  Map<String, double> calculatePawnOwed(
    double principal,
    DateTime pawnDate,
    DateTime dueDate,
    double monthlyRate,
  ) {
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
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        // Removed orderBy to prevent composite index requirements
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Appointment.fromMap(doc.id, doc.data()))
              .toList();
          // Sort locally
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  Stream<List<Appointment>> getAllScheduledAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Appointment.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toIso8601String();

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .get();

    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.id, doc.data()))
        .where((apt) => apt.status == 'scheduled')
        .toList();
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
        .collection('appointments')
        .where('date', isEqualTo: isoDateStart)
        .get();

    final scheduledBookingsCount = existingParams.docs
        .where((d) => d.data()['status'] == 'scheduled')
        .length;

    if (scheduledBookingsCount >= 2) {
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
        .collection('appointments')
        .doc('apt$id')
        .set(appointment.toMap());

    // 2. Update Asset Status to 'pickup_scheduled'
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .doc(asset.id)
        .update({'status': 'pickup_scheduled'});
  }

  Future<void> updateAppointment(String appointmentId, DateTime newDate) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    // Capacity Check
    final isoDateStart = newDate.toIso8601String();
    final existingParams = await FirebaseFirestore.instance
        .collection('appointments')
        .where('date', isEqualTo: isoDateStart)
        .get();

    final scheduledBookingsCount = existingParams.docs
        .where(
          (d) => d.data()['status'] == 'scheduled' && d.id != appointmentId,
        )
        .length;

    if (scheduledBookingsCount >= 2) {
      throw Exception('This time slot has reached maximum capacity.');
    }

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'date': newDate.toIso8601String()});
  }

  Future<void> cancelAppointment(String appointmentId, String assetId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .delete();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('assets')
        .doc(assetId)
        .update({'status': 'owned'});
  }

  Future<void> completeAppointment(String appointmentId) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': 'completed'});
  }

  // Live Cloud Products Stream
  Stream<List<Product>> getProductsStream() {
    return FirebaseFirestore.instance.collection('products').snapshots().map((
      snapshot,
    ) {
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

  // Admin function to reset/seed catalog
  Future<void> seedDummyProducts() async {
    final firestore = FirebaseFirestore.instance;
    final productsRef = firestore.collection('products');
    final batch = firestore.batch();

    final dummyProducts = [
      {
        'id': 'p1',
        'name': 'Classic Gold Chain',
        'description':
            'A timeless 96.5% pure gold necklace suitable for everyday wear. Features a durable hook clasp.',
        'price': 42000.0,
        'weight': 1.0,
        'laborFee': 1200.0,
        'stock': 15,
        'imageUrl':
            'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0370.jpg',
        'category': 'Necklace',
      },
      {
        'id': 'p2',
        'name': 'Dragon Carved Ring',
        'description':
            'Intricately designed gold ring featuring a traditional dragon motif. Perfect for special occasions.',
        'price': 21500.0,
        'weight': 0.5,
        'laborFee': 800.0,
        'stock': 8,
        'imageUrl':
            'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0158.jpg',
        'category': 'Ring',
      },
      {
        'id': 'p3',
        'name': 'Simple Gold Bangle',
        'description':
            'Elegant solid gold bangle with a smooth polished finish.',
        'price': 84500.0,
        'weight': 2.0,
        'laborFee': 1500.0,
        'stock': 5,
        'imageUrl':
            'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0279-Edit.jpg',
        'category': 'Bracelet',
      },
      {
        'id': 'p4',
        'name': 'Lotus Stud Earrings',
        'description':
            'Delicate gold stud earrings shaped like blooming lotus flowers.',
        'price': 10800.0,
        'weight': 0.25,
        'laborFee': 600.0,
        'stock': 20,
        'imageUrl':
            'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0209-Edit.jpg',
        'category': 'Earrings',
      },
      {
        'id': 'p5',
        'name': 'Ruby Embedded Ring',
        'description':
            'Premium gold ring featuring a small, high-quality ruby centerpiece.',
        'price': 25000.0,
        'weight': 0.5,
        'laborFee': 2500.0,
        'stock': 3,
        'imageUrl':
            'https://somsrimanee.com/wp-content/uploads/2023/07/20240906-0164.jpg',
        'category': 'Ring',
      },
    ];

    for (var p in dummyProducts) {
      batch.set(productsRef.doc(p['id'].toString()), p);
    }

    await batch.commit();
  }

  // Search and Filter helper (to be used locally on the streamed list)
  List<Product> filterProducts(List<Product> allProducts, String query) {
    if (query.isEmpty) return allProducts;
    return allProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.category.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // ==== Gold Savings (ออมทอง) ====

  Stream<GoldSavingsAccount> getGoldSavingsAccountStream() {
    final uid = currentUserId;
    if (uid == null) {
      return Stream.value(
        GoldSavingsAccount(
          totalWeightSaved: 0.0,
          totalAmountInvested: 0.0,
          lastUpdated: DateTime.now(),
        ),
      );
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savings')
        .doc('account')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return GoldSavingsAccount(
              totalWeightSaved: 0.0,
              totalAmountInvested: 0.0,
              lastUpdated: DateTime.now(),
            );
          }
          return GoldSavingsAccount.fromMap(snapshot.data()!);
        });
  }

  Stream<List<GoldSavingsTransaction>> getGoldSavingsTransactionsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savings')
        .doc('account')
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GoldSavingsTransaction.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> depositToGoldSavings(
    double amountInTHB,
    double currentBuyPricePerBaht,
  ) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await Future.delayed(const Duration(seconds: 1)); // Network simulation

    // 1. Check wallet balance
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final currentBalance = (userDoc.data()?['walletBalance'] ?? 0.0 as num)
        .toDouble();

    if (currentBalance < amountInTHB) {
      throw Exception('Insufficient wallet balance. Please add funds first.');
    }

    // 2. Calculate fractional weight gained
    final weightGained = amountInTHB / currentBuyPricePerBaht;

    final batch = FirebaseFirestore.instance.batch();

    // 3. Deduct THB from wallet
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    batch.update(userRef, {
      'walletBalance': FieldValue.increment(-amountInTHB),
    });

    // 4. Update the aggregate savings account
    final savingsRef = userRef.collection('savings').doc('account');
    batch.set(savingsRef, {
      'totalWeightSaved': FieldValue.increment(weightGained),
      'totalAmountInvested': FieldValue.increment(amountInTHB),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 5. Create the transaction record
    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    final txRef = savingsRef.collection('transactions').doc('stx_$txId');
    final stx = GoldSavingsTransaction(
      id: txId,
      amountInvested: amountInTHB,
      weightGained: weightGained,
      buyPriceAtTransaction: currentBuyPricePerBaht,
      timestamp: DateTime.now(),
    );
    batch.set(txRef, stx.toMap());

    // 6. Add global transaction record
    final formatter = NumberFormat('#,##0.00');
    final globalTxDoc = {
      'assetId': 'savings',
      'type': TransactionType.savings_deposit.name, // Log specific Savings type
      'amount': amountInTHB,
      'weight': weightGained,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'SAVINGS: Deposited ฿${formatter.format(amountInTHB)}',
      'userId': uid,
      'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email',
    };

    final userTxRef = userRef.collection('transactions').doc('t$txId');
    batch.set(userTxRef, globalTxDoc);

    final globalTransactionsRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc('t$txId');
    batch.set(globalTransactionsRef, globalTxDoc);

    // 7. Add a notification
    final notifId = DateTime.now().millisecondsSinceEpoch.toString();
    final notifRef = userRef.collection('notifications').doc('n_$notifId');
    final notif = NotificationItem(
      id: notifId,
      title: 'Gold Savings Deposit',
      message:
          'Successfully deposited ฿${formatter.format(amountInTHB)} toward your Gold Savings. Gained ${weightGained.toStringAsFixed(4)} Baht.',
      type: 'savings',
      timestamp: DateTime.now(),
      isRead: false,
    );
    batch.set(notifRef, notif.toMap());

    await batch.commit();
  }

  Future<void> sellFromGoldSavings(
    double weightToSell,
    double currentSellPricePerBaht,
  ) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await Future.delayed(const Duration(seconds: 1)); // Network simulation

    // 1. Check if user has enough saved gold weight
    final savingsDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savings')
        .doc('account')
        .get();
    final currentWeight = (savingsDoc.data()?['totalWeightSaved'] ?? 0.0 as num)
        .toDouble();

    if (currentWeight < weightToSell) {
      throw Exception('Insufficient gold weight in your savings.');
    }

    // 2. Calculate cash returned
    final amountInTHB = weightToSell * currentSellPricePerBaht;

    final batch = FirebaseFirestore.instance.batch();

    // 3. Add THB back to wallet
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    batch.update(userRef, {'walletBalance': FieldValue.increment(amountInTHB)});

    // 4. Update the aggregate savings account (deduct weight, and optionally adjust total invested)
    // We adjust total amount invested proportionally down
    double proportionSold = weightToSell / currentWeight;
    double currentInvested =
        (savingsDoc.data()?['totalAmountInvested'] ?? 0.0 as num).toDouble();
    double investedToDeduct = proportionSold * currentInvested;

    final savingsRef = userRef.collection('savings').doc('account');
    batch.set(savingsRef, {
      'totalWeightSaved': FieldValue.increment(-weightToSell),
      'totalAmountInvested': FieldValue.increment(-investedToDeduct),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 5. Create the transaction record
    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    final txRef = savingsRef.collection('transactions').doc('stx_$txId');

    // We can reuse the same model, but we make amountInvested negative to indicate cash returned
    final stx = GoldSavingsTransaction(
      id: txId,
      amountInvested: -amountInTHB,
      weightGained: -weightToSell,
      buyPriceAtTransaction:
          currentSellPricePerBaht, // Store the price they sold at
      timestamp: DateTime.now(),
    );
    batch.set(txRef, stx.toMap());

    // 6. Add global transaction record
    final amountAbs = amountInTHB.abs();
    final formatter = NumberFormat('#,##0.00');
    final globalTxDoc = {
      'assetId': 'savings',
      'type':
          TransactionType.savings_withdraw.name, // Log specific Savings type
      'amount': amountAbs,
      'weight': weightToSell,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'SAVINGS: Sold ${weightToSell.toStringAsFixed(4)} Baht',
      'userId': uid,
      'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email',
    };

    final userTxRef = userRef.collection('transactions').doc('t$txId');
    batch.set(userTxRef, globalTxDoc);

    final globalTransactionsRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc('t$txId');
    batch.set(globalTransactionsRef, globalTxDoc);

    // 7. Add a notification
    final notifId = DateTime.now().millisecondsSinceEpoch.toString();
    final notifRef = userRef.collection('notifications').doc('n_$notifId');
    final notif = NotificationItem(
      id: notifId,
      title: 'Gold Savings Sold',
      message:
          'Successfully sold ${weightToSell.toStringAsFixed(4)} Baht of saved gold. You received ฿${formatter.format(amountInTHB)} back into your wallet.',
      type: 'savings',
      timestamp: DateTime.now(),
      isRead: false,
    );
    batch.set(notifRef, notif.toMap());

    await batch.commit();
  }
}
