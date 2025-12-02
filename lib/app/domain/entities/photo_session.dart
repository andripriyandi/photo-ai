class PhotoSession {
  final String id;
  final String originalPath;
  final List<String> generatedPaths;
  final DateTime createdAt;

  const PhotoSession({
    required this.id,
    required this.originalPath,
    required this.generatedPaths,
    required this.createdAt,
  });
}
