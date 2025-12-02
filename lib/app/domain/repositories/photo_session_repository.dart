import 'dart:io';

import '../entities/photo_session.dart';

abstract class PhotoSessionRepository {
  Future<GenerateResult> createSessionAndGenerate({required File originalFile});
  Stream<List<PhotoSession>> watchSessions();
}

class GenerateResult {
  final String sessionId;
  final String originalUrl;
  final List<String> generatedUrls;

  const GenerateResult({
    required this.sessionId,
    required this.originalUrl,
    required this.generatedUrls,
  });
}
