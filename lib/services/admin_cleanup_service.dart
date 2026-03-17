import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssl_store/services/id_generator_service.dart';

class AdminCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IdGeneratorService _idGeneratorService = IdGeneratorService();

  /// Completely wipes a collection. 
  /// WARNING: Use with extreme caution. Only for development.
  Future<void> purgeCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Removes legacy metadata that might cause confusion.
  Future<void> cleanupLegacyMetadata() async {
    // Delete the old centralized counters document
    await _firestore.collection('metadata').doc('counters').delete();
  }

  /// Re-scans all collections and ensures the new per-collection counters
  /// are synchronized with the highest existing ID.
  Future<void> realignAllCounters() async {
    final collections = [
      'users',
      'transactions',
      'products',
      'appointments',
      'assets',
      'notifications',
    ];

    for (var collection in collections) {
      await _idGeneratorService.repairCounter(collection);
    }
  }

  /// Performs a full "Fresh Start" cleanup.
  Future<void> performFreshStart() async {
    // 1. Clear out test-heavy collections
    await purgeCollection('transactions');
    await purgeCollection('appointments');
    await purgeCollection('notifications');
    await purgeCollection('products');

    // 2. Remove legacy metadata
    await cleanupLegacyMetadata();

    // 3. Align counters for users and anything remaining
    await realignAllCounters();
  }
}
