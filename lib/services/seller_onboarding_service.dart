import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOnboardingService {
  SellerOnboardingService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> createSellerAccount({
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    required Map<String, Object?> restaurantDetails,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user.');
    }

    try {
      await user.updateDisplayName(ownerName.trim());

      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), {
        'uid': user.uid,
        'name': ownerName.trim(),
        'email': user.email,
        'phone': phone.trim(),
        'role': 'seller',
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('sellerApplications').doc(user.uid), {
        ...restaurantDetails,
        'uid': user.uid,
        'ownerName': ownerName.trim(),
        'ownerEmail': user.email,
        'ownerPhone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('restaurants').doc(user.uid), {
        ...restaurantDetails,
        'ownerId': user.uid,
        'name': restaurantDetails['restaurantName'],
        'phone': restaurantDetails['restaurantPhone'],
        'email': restaurantDetails['restaurantEmail'],
        'addressText': _formatAddress(restaurantDetails['address']),
        'categories': [restaurantDetails['cuisine']],
        'isOpen': true,
        'isApproved': true,
        'logoUrl': '',
        'coverImageUrl': '',
        'scheduledClosures': const <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (error) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (cleanupError) {
        await _auth.signOut();
        throw StateError(
          'Saving the application failed (${error.code}), and the newly '
          'created account could not be removed (${cleanupError.code}). '
          'Contact support before retrying.',
        );
      }
      rethrow;
    }

    return credential;
  }

  String _formatAddress(Object? value) {
    if (value is! Map) return '';
    return [
      value['street'],
      value['area'],
      value['city'],
      value['state'],
      value['pincode'],
      value['country'],
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
  }
}
