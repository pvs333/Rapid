import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Optional import. We'll ship a stub in lib/firebase_options.dart so this compiles
// and is later replaced by `flutterfire configure`.
import '../firebase_options.dart';

/// Lightweight Firebase sync for cross-device progression.
///
/// Contract:
/// - Initializes Firebase and signs in anonymously.
/// - Mirrors local solves to `users/{uid}/solves/{docId}` where docId is a stable key.
/// - Listens to remote changes and notifies the app via [onRemoteUpdate].
class FirebaseSyncService {
  FirebaseSyncService._();
  static final FirebaseSyncService instance = FirebaseSyncService._();

  bool _initialized = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// Called whenever remote solves snapshot changes.
  /// The payload is a list of maps with keys: `time`, `date`.
  void Function(List<Map<String, String>> solves)? onRemoteUpdate;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Try with generated options (preferred)
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        // Fallback for environments where options aren't provided. This will work
        // only if platform-native configs (google-services.json/GoogleService-Info.plist)
        // are present; otherwise Firebase will stay uninitialized but the app runs.
        debugPrint('[FirebaseSync] initializeApp without options: $e');
        await Firebase.initializeApp();
      }

      // Ensure we have a user (anonymous is fine for this app)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      _listenToRemote();
      _initialized = true;
      debugPrint('[FirebaseSync] Initialized');
    } catch (e, st) {
      debugPrint('[FirebaseSync] Initialization skipped: $e\n$st');
      _initialized = false;
    }
  }

  void _listenToRemote() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('solves')
        .orderBy('date')
        .snapshots()
        .listen(
          (snapshot) {
            final remote = snapshot.docs.map((d) {
              final data = d.data();
              return <String, String>{
                'time': (data['time'] ?? '').toString(),
                'date': (data['date'] ?? '').toString(),
              };
            }).toList();
            onRemoteUpdate?.call(remote);
          },
          onError: (e) {
            debugPrint('[FirebaseSync] listen error: $e');
          },
        );
  }

  /// Push a new solve to Firestore. No-op if Firebase not initialized.
  Future<void> pushAdd(Map<String, String> solve) async {
    if (!_initialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docId = _docId(solve);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('solves')
        .doc(docId)
        .set({
          'time': solve['time'],
          'date': solve['date'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Remove a solve from Firestore. No-op if Firebase not initialized.
  Future<void> pushDelete(Map<String, String> solve) async {
    if (!_initialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docId = _docId(solve);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('solves')
        .doc(docId)
        .delete();
  }

  /// Creates a stable, URL-safe doc id from the pair (date,time).
  String _docId(Map<String, String> solve) {
    final date = solve['date'] ?? '';
    final time = solve['time'] ?? '';
    return base64Url.encode(utf8.encode('$date|$time'));
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
