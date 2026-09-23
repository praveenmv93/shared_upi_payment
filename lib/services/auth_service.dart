import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of signed‑in user
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Sign up with email & password, then create a user profile document
  Future<User?> signUp({required String email, required String password, required String displayName}) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = cred.user;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': displayName,
        'email': email,
        'upiId': email, // default
        'groupIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  // Sign in with email & password
  Future<User?> signIn({required String email, required String password}) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Fetch current user's profile from Firestore
  Future<UserProfile?> getCurrentUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) {
      // Auto-create missing user profile document
      final defaultName = user.displayName ?? user.email?.split('@').first ?? 'User';
      await _db.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': defaultName,
        'email': user.email ?? '',
        'upiId': user.email ?? '', // default
        'groupIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return UserProfile(
        id: user.uid,
        name: defaultName,
        email: user.email ?? '',
        upiId: user.email ?? '',
      );
    }
    var data = snap.data() as Map<String, dynamic>;
    return UserProfile(
      id: user.uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      upiId: data['upiId'] ?? data['email'] ?? '',
    );
  }
}
