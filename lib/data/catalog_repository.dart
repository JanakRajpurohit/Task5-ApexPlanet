import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food.dart';

class CatalogRepository {
  CatalogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Food>> watchFoods() => _firestore
      .collection('foods')
      .where('isPublished', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => Food.fromFirestore(document.id, document.data()))
            .toList(growable: false),
      );
}
