import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return 'خطای ناشناخته: $e';
    }
  }

  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(displayName);

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'xpRates': {
          'study_per_minute': 1.0,
          'workout_per_minute': 1.5,
          'chess_per_game': 20.0,
          'backgammon_per_game': 15.0,
          'language_per_minute': 1.0,
          'design_per_minute': 0.5,
          'reading_per_minute': 1.0,
          'podcast_per_minute': 0.25,
          'journal_per_day': 10.0,
          'meditation_per_minute': 1.5,
        },
      });

      await FirestoreService().seedDefaultSkills(credential.user!.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return 'خطای ناشناخته: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'کاربری با این ایمیل پیدا نشد.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'رمز عبور اشتباه است.';
      case 'email-already-in-use':
        return 'این ایمیل قبلاً ثبت شده است.';
      case 'weak-password':
        return 'رمز عبور خیلی ساده است (حداقل ۶ کاراکتر).';
      case 'invalid-email':
        return 'فرمت ایمیل نامعتبر است.';
      default:
        return 'خطا: ${e.message}';
    }
  }
}
