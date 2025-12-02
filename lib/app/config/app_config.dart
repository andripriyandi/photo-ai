import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photo_ai/firebase_options.dart';

class AppConfig {
  static late FirebaseApp app;
  static late FirebaseAuth auth;
  static late FirebaseFirestore firestore;
  static late FirebaseStorage storage;
  static late FirebaseFunctions functions;
  static const String functionsRegion = 'us-central1';

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    auth = FirebaseAuth.instanceFor(app: app);
    firestore = FirebaseFirestore.instanceFor(app: app);
    storage = FirebaseStorage.instanceFor(app: app);
    functions = FirebaseFunctions.instanceFor(
      app: app,
      region: functionsRegion,
    );

    const host = '10.0.2.2';
    const authPort = 9099;
    const firestorePort = 8080;
    const storagePort = 9199;
    const functionsPort = 5001;

    auth.useAuthEmulator(host, authPort);
    firestore.useFirestoreEmulator(host, firestorePort);
    storage.useStorageEmulator(host, storagePort);
    functions.useFunctionsEmulator(host, functionsPort);

    if (auth.currentUser == null) {
      final cred = await auth.signInAnonymously();
      debugPrint('Signed in anonymously as ${cred.user?.uid}');
    } else {
      debugPrint('Already signed in as ${auth.currentUser!.uid}');
    }
  }
}
