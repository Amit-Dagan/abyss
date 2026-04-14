import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:todo_list/data/repo/battle_repo_impl/firestore_battle_catalog_repository.dart';

class EditorSessionService extends ChangeNotifier {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirestoreBattleCatalogRepository? _catalogRepository;

  StreamSubscription<User?>? _authSubscription;

  bool _isInitialized = false;
  bool _isSigningIn = false;
  bool _isRefreshingAccess = false;
  bool _canEditUnits = false;
  bool _isAdmin = false;
  String? _errorMessage;
  User? _currentUser;

  EditorSessionService.local({bool canEditUnits = true})
    : _auth = null,
      _firestore = null,
      _catalogRepository = null,
      _isInitialized = true,
      _isAdmin = canEditUnits,
      _canEditUnits = canEditUnits;

  EditorSessionService.firebase({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirestoreBattleCatalogRepository catalogRepository,
  }) : _auth = auth,
       _firestore = firestore,
       _catalogRepository = catalogRepository;

  bool get canEditUnits => _canEditUnits;

  String? get currentUserEmail => _currentUser?.email;

  String? get errorMessage => _errorMessage;

  bool get isAdmin => _isAdmin;

  bool get isBusy => _isSigningIn || _isRefreshingAccess;

  bool get isInitialized => _isInitialized;

  bool get isSignedIn => _currentUser != null;

  bool get supportsAuthentication =>
      kIsWeb && _auth != null && _firestore != null;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final FirebaseAuth auth = _auth!;
    _authSubscription = auth.authStateChanges().listen((User? user) {
      unawaited(_syncFromUser(user));
    });

    await _syncFromUser(auth.currentUser);
    _isInitialized = true;
    notifyListeners();
  }

  String get statusMessage {
    if (!supportsAuthentication) {
      return 'Local catalog mode is active on this platform.';
    }
    if (!isInitialized || isBusy) {
      return 'Checking editor access...';
    }
    if (!isSignedIn) {
      return 'Browse the shared unit catalog publicly. Signed-in admins can create and update units.';
    }
    if (isAdmin) {
      return 'Signed in as ${currentUserEmail ?? 'admin'}. This account is an admin and can edit the shared unit catalog.';
    }
    return 'Signed in as ${currentUserEmail ?? 'reader'}, but this account is not marked as admin in Firestore. You have read-only access.';
  }

  Future<bool> signIn() async {
    if (!supportsAuthentication || _auth == null) {
      return false;
    }

    _errorMessage = null;
    _isSigningIn = true;
    notifyListeners();

    try {
      final GoogleAuthProvider provider = GoogleAuthProvider()
        ..addScope('email');
      await _auth.signInWithPopup(provider);
      return true;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'popup-closed-by-user') {
        _errorMessage = _describeSignInError(error);
      }
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in right now.';
      return false;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_auth == null) {
      return;
    }

    _errorMessage = null;
    await _auth.signOut();
  }

  Future<void> _syncFromUser(User? user) async {
    _currentUser = user;
    _errorMessage = null;

    if (!supportsAuthentication || user == null) {
      _canEditUnits = false;
      _isAdmin = false;
      notifyListeners();
      return;
    }

    final String? email = user.email;
    if (email == null || !user.emailVerified) {
      _canEditUnits = false;
      _isAdmin = false;
      notifyListeners();
      return;
    }

    _isRefreshingAccess = true;
    notifyListeners();

    try {
      final DocumentReference<Map<String, dynamic>> userDocument = _firestore!
          .collection('users')
          .doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await userDocument.get();
      final bool admin = (userSnapshot.data()?['admin'] as bool?) == true;

      await userDocument.set(<String, dynamic>{
        'uid': user.uid,
        'email': email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'admin': admin,
        'lastSeenAt': FieldValue.serverTimestamp(),
        if (!userSnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isAdmin = admin;
      _canEditUnits = admin;
      if (admin) {
        await _catalogRepository?.seedIfEmpty();
      }
    } catch (_) {
      _isAdmin = false;
      _canEditUnits = false;
      _errorMessage = 'Could not verify admin permissions.';
    } finally {
      _isRefreshingAccess = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _describeSignInError(FirebaseAuthException error) {
    return switch (error.code) {
      'operation-not-allowed' =>
        'Google sign-in is not enabled for this Firebase project yet.',
      'unauthorized-domain' =>
        'This site domain is not authorized for Firebase sign-in yet.',
      'popup-blocked' =>
        'The browser blocked the sign-in popup. Allow popups and try again.',
      'network-request-failed' =>
        'A network error interrupted sign-in. Please try again.',
      _ => error.message ?? 'Unable to sign in right now.',
    };
  }
}
