import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> signInCustomer({
    required String email,
    required String password,
  }) async {
    final credential = await signIn(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user.');
    }

    var accepted = false;
    try {
      final role = await roleFor(user.uid);
      if (role != 'customer') {
        throw FirebaseAuthException(
          code: 'permission-denied',
          message: 'This account is not registered as a customer.',
        );
      }
      accepted = true;
      return credential;
    } finally {
      if (!accepted) await signOut();
    }
  }

  Future<UserCredential> createCustomerAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user.');
    }

    await user.updateDisplayName(name.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': user.email,
      'phone': phone.trim(),
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<String?> roleFor(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data()?['role'] as String?;
  }

  Future<Map<String, dynamic>> profileFor(User user) async {
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final profile = snapshot.data() ?? <String, dynamic>{};
    return {
      'name': profile['name'] as String? ?? user.displayName ?? '',
      'email': profile['email'] as String? ?? user.email ?? '',
      'phone': profile['phone'] as String? ?? user.phoneNumber ?? '',
      'role': profile['role'] as String?,
    };
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(User user) =>
      _firestore.collection('users').doc(user.uid).snapshots();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
