import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/address.dart';

class AddressRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _addressRef(String uid) =>
      _db.collection('users').doc(uid).collection('addresses');

  Stream<List<Address>> watchAddresses(String uid) {
    return _addressRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Address.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> _clearOtherDefaults(String uid, {String? exceptId}) async {
    final existing = await _addressRef(uid)
        .where('isDefault', isEqualTo: true)
        .get();
    final batch = _db.batch();
    for (final doc in existing.docs) {
      if (doc.id != exceptId) batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }

  Future<void> addAddress(String uid, Address address) async {
    final docRef = _addressRef(uid).doc();
    if (address.isDefault) await _clearOtherDefaults(uid);
    await docRef.set(address.toMap());
  }

  Future<void> updateAddress(
    String uid,
    String addressId,
    Address address,
  ) async {
    if (address.isDefault) await _clearOtherDefaults(uid, exceptId: addressId);
    await _addressRef(uid).doc(addressId).update(address.toMap());
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _addressRef(uid).doc(addressId).delete();
  }
}
