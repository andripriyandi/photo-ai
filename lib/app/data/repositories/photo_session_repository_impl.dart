import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/photo_session.dart';
import '../../domain/repositories/photo_session_repository.dart';

class PhotoSessionRepositoryImpl implements PhotoSessionRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  PhotoSessionRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    return user.uid;
  }

  Future<String> _uploadOriginal(File file, String sessionId) async {
    final ref = _storage
        .ref()
        .child("users")
        .child(_uid)
        .child("sessions")
        .child(sessionId)
        .child("original.jpg");

    await ref.putFile(file);
    return ref.fullPath;
  }

  @override
  Future<GenerateResult> createSessionAndGenerate({
    required File originalFile,
  }) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final originalPath = await _uploadOriginal(originalFile, sessionId);

    final callable = _functions.httpsCallable("generateImages");
    final response = await callable.call<Map<String, dynamic>>({
      "originalImagePath": originalPath,
      "sessionId": sessionId,
      "styles": [
        "Beach vacation, golden hour portrait",
        "Night city walk, neon lights",
        "Cozy cafe, laptop, lifestyle shot",
      ],
    });

    final data = response.data;
    final List<dynamic> generatedPathsDynamic =
        data["generatedImagePaths"] as List<dynamic>? ?? [];

    final generatedPaths = generatedPathsDynamic
        .map((e) => e.toString())
        .toList();

    final docRef = _firestore
        .collection("users")
        .doc(_uid)
        .collection("sessions")
        .doc(sessionId);

    await docRef.set({
      "uid": _uid,
      "originalPath": originalPath,
      "generatedPaths": generatedPaths,
      "createdAt": FieldValue.serverTimestamp(),
    });

    final originalUrl = await _storage
        .ref()
        .child(originalPath)
        .getDownloadURL();

    final generatedUrls = <String>[];
    for (final path in generatedPaths) {
      final url = await _storage.ref().child(path).getDownloadURL();
      generatedUrls.add(url);
    }

    return GenerateResult(
      sessionId: sessionId,
      originalUrl: originalUrl,
      generatedUrls: generatedUrls,
    );
  }

  @override
  Stream<List<PhotoSession>> watchSessions() {
    return _firestore
        .collection("users")
        .doc(_uid)
        .collection("sessions")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            return PhotoSession(
              id: doc.id,
              originalPath: data["originalPath"] as String? ?? "",
              generatedPaths: (data["generatedPaths"] as List<dynamic>? ?? [])
                  .cast<String>(),
              createdAt:
                  (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }
}
