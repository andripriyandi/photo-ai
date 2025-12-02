import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photo_ai/firebase_options.dart';

class AppConfig {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      name: 'photo_ai',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final host = '10.0.2.2';
    const authPort = 9099;
    const firestorePort = 8080;
    const storagePort = 9199;
    const functionsPort = 5001;

    FirebaseAuth.instance.useAuthEmulator(host, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    FirebaseStorage.instance.useStorageEmulator(host, storagePort);
    FirebaseFunctions.instance.useFunctionsEmulator(host, functionsPort);

    // Anonymous auth
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }
}
