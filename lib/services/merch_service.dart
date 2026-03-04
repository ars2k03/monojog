import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:monojog/models/tshirt_model.dart';

class MerchService {
  MerchService._();

  static final MerchService instance = MerchService._();
  static const String merchantPaymentNumber = '01797859806';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tshirtRef =>
      _firestore.collection('merch_tshirts');

  CollectionReference<Map<String, dynamic>> get _orderRef =>
      _firestore.collection('merch_orders');

  Stream<List<TShirt>> watchTShirts() {
    return _tshirtRef
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TShirt.fromMap({'id': doc.id, ...doc.data()}))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Stream<List<TShirtOrder>> watchOrdersForUser(String userId) {
    return _orderRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        TShirtOrder.fromMap({'id': doc.id, ...doc.data()}))
        .toList()
      ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt)));
  }

  Future<void> placeOrder(TShirtOrder order) async {
    await _orderRef.doc(order.id).set(order.toMap());
  }

  Future<void> addTShirt(TShirt tshirt) async {
    await _tshirtRef.doc(tshirt.id).set(tshirt.toMap());
  }

  Future<void> seedDefaultTShirtsIfEmpty({List<TShirt>? tshirts}) async {
    try {
      final existing = await _tshirtRef.limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final defaults = tshirts ?? TShirt.catalog.take(5).toList();

      if (defaults.isEmpty) return;

      final batch = _firestore.batch();
      for (final item in defaults) {
        batch.set(_tshirtRef.doc(item.id), item.toMap());
      }
      await batch.commit();
    } catch (e) {
      // Seed failed silently — log করো debug-এর জন্য
      debugPrint('MerchService seedDefaultTShirtsIfEmpty error: $e');
    }
  }
}