import 'package:cloud_firestore/cloud_firestore.dart';

class IdGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Prefix mappings for best practice naming
  static const Map<String, String> _prefixMap = {
    'receipts': 'RCT',
    'invoices': 'INV',
    'quotations': 'QTN',
    'users': 'CST',
    'products': 'PRD',
    'suppliers': 'SUP',
    'transactions': 'TXN',
    'promotions': 'PRM',
    'appointments': 'APT',
    'assets': 'AST',
    'notifications': 'NTF',
  };

  /// Default padding mappings for different collection types
  static const Map<String, int> _paddingMap = {
    'users': 6,
    'transactions': 8,
    'receipts': 8,
    'invoices': 8,
    'products': 5,
    'appointments': 5,
    'assets': 6,
    'notifications': 6,
  };

  /// Generates a sequential ID formatted according to best practices.
  /// Defaults to: PREFIX-000001 (padding varies by collection)
  Future<String> generateId(
    String collectionName, {
    String? prefixOverride,
    int? paddingOverride,
    String separator = '-',
  }) async {
    // Determine the prefix
    String prefix = prefixOverride ?? 
                    _prefixMap[collectionName] ?? 
                    collectionName.substring(0, 3).toUpperCase();

    // Determine the padding
    int padding = paddingOverride ?? _paddingMap[collectionName] ?? 4;

    // Use a dedicated document per collection to avoid write bottlenecks
    final counterRef = _firestore
        .collection('metadata')
        .doc('counters')
        .collection('collections')
        .doc(collectionName);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int currentSequence = 0;
      if (snapshot.exists && snapshot.data() != null) {
        currentSequence = (snapshot.data()?['current'] ?? 0) as int;
      }

      final nextSequence = currentSequence + 1;

      // Update the counter document for this specific collection
      transaction.set(
        counterRef,
        {'current': nextSequence, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      return '$prefix$separator${nextSequence.toString().padLeft(padding, '0')}';
    });
  }

  /// Manually repairs/syncs the counter based on current collection size.
  Future<void> repairCounter(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    int currentCount = snapshot.docs.length;
    
    int maxSequential = 0;
    
    for (var doc in snapshot.docs) {
      final id = doc.id;
      final match = RegExp(r'^([A-Z]+)-(\d+)$').firstMatch(id);
      if (match != null) {
        final numPart = int.tryParse(match.group(2)!);
        if (numPart != null && numPart > maxSequential) {
          maxSequential = numPart;
        }
      }
    }

    final finalCounterValue = maxSequential > currentCount ? maxSequential : currentCount;
    
    final counterRef = _firestore
        .collection('metadata')
        .doc('counters')
        .collection('collections')
        .doc(collectionName);
    
    await counterRef.set(
      {'current': finalCounterValue, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
