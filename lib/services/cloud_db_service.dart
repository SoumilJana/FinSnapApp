import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';

class CloudDbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'transactions';

  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(transaction.id);

      // We convert it to a map to upload to Firestore
      final map = transaction.toMap();
      // Use set instead of add to maintain the same ID across local and cloud
      await docRef.set(map);
    } catch (e) {
      print('Error saving to cloud: $e');
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      if (transaction.id == null) return;
      await _firestore
          .collection(_collectionName)
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      print('Error updating cloud transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      print('Error deleting cloud transaction: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      // Wait for all deletions to complete
      await Future.wait(snapshot.docs.map((doc) => doc.reference.delete()));
    } catch (e) {
      print('Error wiping cloud database: $e');
    }
  }
}
