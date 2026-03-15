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
  };

  /// Generates a sequential ID formatted according to best practices.
  /// Defaults to: PREFIX-0001 (padding 4, separator '-')
  Future<String> generateId(
    String collectionName, {
    String? prefixOverride,
    int padding = 4,
    String separator = '-',
  }) async {
    // Determine the prefix: use override, then map, then default to first 3 letters
    String prefix = prefixOverride ?? 
                    _prefixMap[collectionName] ?? 
                    collectionName.substring(0, 3).toUpperCase();

    print('DEBUG: Starting ID generation for $collectionName with prefix: $prefix');
    // Use a specific counter for this collection to maintain sequence
    final counterName = '${collectionName}_counter';
    final counterRef = _firestore.collection('metadata').doc('counters');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int currentSequence = 0;
      if (snapshot.exists && snapshot.data() != null) {
        currentSequence = (snapshot.data()![counterName] ?? 0) as int;
      }
      print('DEBUG: Current sequence for $collectionName is $currentSequence');

      final nextSequence = currentSequence + 1;

      // Update the counter transactionally
      transaction.set(
        counterRef,
        {counterName: nextSequence},
        SetOptions(merge: true),
      );

      // Format the ID: e.g., RCT-0001
      print('DEBUG: Generated next ID for $collectionName: $prefix$separator${nextSequence.toString().padLeft(padding, '0')}');
      return '$prefix$separator${nextSequence.toString().padLeft(padding, '0')}';
    });
  }

  /// Manually repairs/syncs the counter based on current collection size.
  /// Useful if records were created before sequential IDs were implemented.
  Future<void> repairCounter(String collectionName) async {
    print('Starting repair for collection: $collectionName');
    final snapshot = await _firestore.collection(collectionName).get();
    int currentCount = snapshot.docs.length;
    
    // Also try to find the highest existing sequential ID to avoid collisions
    int maxSequential = 0;
    final prefix = _prefixMap[collectionName] ?? collectionName.substring(0, 3).toUpperCase();
    
    for (var doc in snapshot.docs) {
      final id = doc.id;
      // Regex to find ANY sequential ID pattern: PREFIX-NUMBER
      final match = RegExp(r'^([A-Z]+)-(\d+)$').firstMatch(id);
      if (match != null) {
        final numPart = int.tryParse(match.group(2)!);
        if (numPart != null && numPart > maxSequential) {
          maxSequential = numPart;
        }
      }
    }

    // Use the higher of total docs or highest sequential ID found
    final finalCounterValue = maxSequential > currentCount ? maxSequential : currentCount;
    
    print('Repair Findings for $collectionName: Total Docs=$currentCount, Max Sequential=$maxSequential. Setting counter to: $finalCounterValue');

    final counterName = '${collectionName}_counter';
    final counterRef = _firestore.collection('metadata').doc('counters');
    
    await counterRef.set(
      {counterName: finalCounterValue},
      SetOptions(merge: true),
    );
  }
}
