import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_ai/app/config/app_config.dart';
import 'package:photo_ai/app/domain/entities/photo_session.dart';
import 'package:photo_ai/app/domain/repositories/photo_session_repository.dart';

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
  }) : _auth = auth ?? AppConfig.auth,
       _firestore = firestore ?? AppConfig.firestore,
       _storage = storage ?? AppConfig.storage,
       _functions = functions ?? AppConfig.functions;

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

    debugPrint('Uploading original image to: ${ref.fullPath}');
    await ref.putFile(file);
    return ref.fullPath;
  }

  @override
  Future<GenerateResult> createSessionAndGenerate({
    required File originalFile,
    required List<String> styles,
  }) async {
    if (styles.isEmpty) {
      throw ArgumentError('At least one style must be provided');
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final originalPath = await _uploadOriginal(originalFile, sessionId);

    final selectedScenes = List<String>.from(styles);

    debugPrint(
      'Calling generateImages as uid=$_uid, originalPath=$originalPath, sessionId=$sessionId, styles=$selectedScenes',
    );

    final callable = _functions.httpsCallable("generateImages");
    final response = await callable.call<Map<String, dynamic>>({
      "originalImagePath": originalPath,
      "sessionId": sessionId,
      "styles": selectedScenes,
    });

    final data = response.data;
    final List<dynamic> generatedPathsDynamic =
        data["generatedImagePaths"] as List<dynamic>? ?? [];

    final generatedPaths = generatedPathsDynamic
        .map((e) => e.toString())
        .toList();

    debugPrint('Generated paths: $generatedPaths');

    final docRef = _firestore
        .collection("users")
        .doc(_uid)
        .collection("sessions")
        .doc(sessionId);

    await docRef.set({
      "uid": _uid,
      "originalPath": originalPath,
      "generatedPaths": generatedPaths,
      "styles": selectedScenes,
      "createdAt": FieldValue.serverTimestamp(),
    });

    final originalUrlFuture = _storage
        .ref()
        .child(originalPath)
        .getDownloadURL();

    final generatedUrlsFuture = Future.wait(
      generatedPaths.map((path) async {
        try {
          return await _storage.ref().child(path).getDownloadURL();
        } on FirebaseException catch (e) {
          debugPrint(
            'Failed to get download URL for $path: ${e.code} ${e.message}',
          );
          return null;
        }
      }),
    );

    final originalUrl = await originalUrlFuture;
    final generatedUrls = (await generatedUrlsFuture)
        .whereType<String>()
        .toList();

    debugPrint(
      'Got originalUrl length=${originalUrl.length}, generatedUrls=${generatedUrls.length}',
    );

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
