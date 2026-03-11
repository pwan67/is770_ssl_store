import 'package:cloud_firestore/cloud_firestore.dart';

class IdGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a sequential ID formatted as PREFIX_000000.
  /// Uses a Firestore Transaction to ensure atomic increments.
  Future<String> generateId(String counterName, String prefix) async {
    final counterRef = _firestore.collection('metadata').doc('counters');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int currentSequence = 0;
      if (snapshot.exists && snapshot.data() != null) {
        currentSequence = (snapshot.data()![counterName] ?? 0) as int;
      }

      final nextSequence = currentSequence + 1;

      // Update the counter transactionally
      transaction.set(
        counterRef,
        {counterName: nextSequence},
        SetOptions(merge: true),
      );

      // Format the ID: e.g., SSL_000001
      final formattedSequence = nextSequence.toString().padLeft(6, '0');
      return '${prefix}_$formattedSequence';
    });
  }
}
