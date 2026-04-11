// lib/data/datasources/firebase_auth_remote_data_source.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/errors/exceptions.dart';

abstract class FirebaseAuthRemoteDataSource {
  Future<String> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<String> signIn({
    required String email,
    required String password,
  });

  Future<String> signInWithGoogle();

  Future<void> signOut();

  Future<void> resetPassword({required String email});

  Future<bool> isUserLoggedIn();

  String? getCurrentUserId();

  String? getCurrentUserEmail();
}

class FirebaseAuthRemoteDataSourceImpl implements FirebaseAuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  FirebaseAuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<String> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'User creation returned null');
      }

      await user.updateDisplayName(username);
      await user.reload();

      return user.uid;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(message: 'Sign up failed: $e');
    }
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'User sign in returned null');
      }

      return user.uid;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(message: 'Sign in failed: $e');
    }
  }

  @override
  Future<String> signInWithGoogle() async {
    try {
      // Sign out of both Google and Firebase to ensure clean state
      await googleSignIn.signOut();
      await firebaseAuth.signOut();

      // Get Google Sign-In account (v7 API)
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Get the idToken (synchronous in v7)
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw AuthException(
          message: 'Failed to get ID token from Google',
        );
      }

      // Create Firebase credential with idToken only.
      // On Android, the idToken alone is sufficient for Firebase auth.
      // The accessToken is only needed if you call Google APIs directly.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw AuthException(
          message: 'Google sign in returned null user',
        );
      }

      return user.uid;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Google sign in failed: $e',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut();
    } catch (e) {
      throw UnknownException(message: 'Sign out failed: $e');
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw UnknownException(message: 'Password reset failed: $e');
    }
  }

  @override
  Future<bool> isUserLoggedIn() async {
    return firebaseAuth.currentUser != null;
  }

  @override
  String? getCurrentUserId() {
    return firebaseAuth.currentUser?.uid;
  }

  @override
  String? getCurrentUserEmail() {
    return firebaseAuth.currentUser?.email;
  }

  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return AuthException(message: 'The password provided is too weak.');
      case 'email-already-in-use':
        return AuthException(
            message: 'An account already exists for that email.');
      case 'invalid-email':
        return AuthException(message: 'The email address is not valid.');
      case 'user-disabled':
        return AuthException(message: 'This user account has been disabled.');
      case 'user-not-found':
        return AuthException(message: 'No user found for that email.');
      case 'wrong-password':
        return AuthException(message: 'Wrong password provided.');
      case 'invalid-credential':
        return AuthException(
            message: 'The supplied auth credential is invalid.');
      case 'operation-not-allowed':
        return AuthException(
            message: 'Email/password accounts are not enabled.');
      case 'too-many-requests':
        return AuthException(
            message: 'Too many login attempts. Try again later.');
      default:
        return AuthException(message: e.message ?? 'Authentication failed');
    }
  }
}
