import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_ai/app/presentation/widgets/shimmer_placeholder.dart';

import '../../domain/repositories/photo_session_repository.dart';
import '../widgets/aspect_control.dart';
import '../widgets/error_hint_banner.dart';
import '../widgets/error_image_placeholder.dart';
import '../widgets/generate_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/header.dart';
import '../widgets/result_section.dart';
import '../widgets/scene.dart';
import '../widgets/top_pill.dart';
import '../widgets/uploads.dart';

class PhotoAiPage extends StatefulWidget {
  final PhotoSessionRepository repository;

  const PhotoAiPage({super.key, required this.repository});

  @override
  State<PhotoAiPage> createState() => _PhotoAiPageState();
}

class _PhotoAiPageState extends State<PhotoAiPage> {
  final _picker = ImagePicker();

  File? _localImage;
  bool _isGenerating = false;
  String? _errorMessage;

  String? _originalUrl;
  List<String> _generatedUrls = [];

  static const List<SceneOption> _sceneOptions = [
    SceneOption(
      id: "Travel",
      label: "Travel",
      description: "Beach / landmarks",
      icon: Icons.flight_takeoff_rounded,
    ),
    SceneOption(
      id: "CityNight",
      label: "City night",
      description: "Neon / street",
      icon: Icons.nightlife_rounded,
    ),
    SceneOption(
      id: "CozyCafe",
      label: "Cozy café",
      description: "Coffee / laptop",
      icon: Icons.local_cafe_rounded,
    ),
    SceneOption(
      id: "LuxuryCar",
      label: "Luxury car",
      description: "Sports / premium",
      icon: Icons.directions_car_filled_rounded,
    ),
    SceneOption(
      id: "Office",
      label: "Office",
      description: "Desk / skyline",
      icon: Icons.apartment_rounded,
    ),
    SceneOption(
      id: "Gym",
      label: "Gym",
      description: "Weights / active",
      icon: Icons.fitness_center_rounded,
    ),
  ];

  Set<String> _selectedScenes = {};
  String _focusedScene = "Travel";

  List<String> _currentResultStyles = [];

  String _selectedAspect = "4:5";

  Future<void> _pickImage() async {
    if (_isGenerating) return;

    setState(() {
      _errorMessage = null;
    });

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 65,
    );

    if (picked == null) return;

    setState(() {
      _localImage = File(picked.path);
      _originalUrl = null;
      _generatedUrls = [];
      _currentResultStyles = [];
      _selectedScenes = {};
      _focusedScene = "Travel";
    });
  }

  Future<void> _generate() async {
    if (_localImage == null || _isGenerating || _selectedScenes.isEmpty) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final stylesToGenerate = _selectedScenes.toList();

      final result = await widget.repository.createSessionAndGenerate(
        originalFile: _localImage!,
        styles: stylesToGenerate,
      );

      setState(() {
        _originalUrl = result.originalUrl;
        _generatedUrls = result.generatedUrls;
        _currentResultStyles = stylesToGenerate;
        if (_currentResultStyles.isNotEmpty) {
          _focusedScene = _currentResultStyles.first;
        }
      });
    } catch (e) {
      final raw = e.toString();
      debugPrint('Photo AI error: $raw');

      String friendlyMessage = "Something went wrong. Please try again.";

      if (raw.contains("You exceeded your current quota") ||
          raw.contains("Quota exceeded for metric") ||
          raw.contains("generate_content_free_tier_requests")) {
        friendlyMessage =
            "The Gemini API free-tier quota for this test project has been exceeded. "
            "Please provide a Gemini API key or update the plan to continue generating images.";
      }

      setState(() {
        _errorMessage = friendlyMessage;
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  int _styleIndexFor(String styleId) {
    if (_generatedUrls.isEmpty) return 0;
    final idx = _currentResultStyles.indexOf(styleId);
    if (idx < 0 || idx >= _generatedUrls.length) return 0;
    return idx;
  }

  double _aspectRatioFromString(String aspect) {
    switch (aspect) {
      case "1:1":
        return 1.0;
      case "9:16":
        return 9 / 16;
      case "4:5":
      default:
        return 4 / 5;
    }
  }

  String _labelForStyleId(String id) {
    for (final s in _sceneOptions) {
      if (s.id == id) return s.label;
    }
    return id;
  }

  int get _selectedCount => _selectedScenes.length;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;
    final horizontalPadding = isWide ? size.width * 0.12 : 20.0;

    final hasPhoto = _localImage != null;
    final hasScenes = _selectedScenes.isNotEmpty;
    final hasResult = _generatedUrls.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding - 4),
          child: const TopPill(),
        ),
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Header(hasResult: hasResult),
                  const SizedBox(height: 16),
                  UploadCard(localImage: _localImage, onTap: _pickImage),
                  const SizedBox(height: 14),
                  SceneSelectorRow(
                    sceneOptions: _sceneOptions,
                    selectedScenes: _selectedScenes,
                    selectedCount: _selectedCount,
                    onToggleScene: (id) {
                      setState(() {
                        if (_selectedScenes.contains(id)) {
                          _selectedScenes.remove(id);
                          if (_focusedScene == id &&
                              _selectedScenes.isNotEmpty) {
                            _focusedScene = _selectedScenes.first;
                          }
                        } else {
                          _selectedScenes.add(id);
                          if (_selectedScenes.length == 1) {
                            _focusedScene = id;
                          }
                        }
                      });
                    },
                    onSelectRecommended: () {
                      setState(() {
                        _selectedScenes = {"Travel", "CityNight", "CozyCafe"};
                        _focusedScene = "Travel";
                      });
                    },
                    onClearAll: () {
                      setState(() {
                        _selectedScenes.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  AspectControl(
                    value: _selectedAspect,
                    onChanged: (v) {
                      setState(() => _selectedAspect = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  ErrorHintBanner(
                    errorMessage: _errorMessage,
                    hasLocalImage: hasPhoto,
                    hasScenes: hasScenes,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: ResultSection(
                        key: ValueKey(
                          "${_isGenerating}_${_originalUrl}_${_generatedUrls.length}",
                        ),
                        isGenerating: _isGenerating,
                        originalUrl: _originalUrl,
                        generatedUrls: _generatedUrls,
                        currentResultStyles: _currentResultStyles,
                        focusedScene: _focusedScene,
                        aspectRatio: _aspectRatioFromString(_selectedAspect),
                        labelForStyleId: _labelForStyleId,
                        styleIndexFor: _styleIndexFor,
                        onFocusScene: (styleId) {
                          setState(() {
                            _focusedScene = styleId;
                          });
                        },
                        onShowActions: (url, styleLabel) =>
                            _showImageActionsSheet(
                              url: url,
                              styleLabel: styleLabel,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GenerateButton(
                    isGenerating: _isGenerating,
                    hasImage: hasPhoto,
                    hasScenes: hasScenes,
                    hasResult: hasResult,
                    onPressed: _generate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageActionsSheet({
    required String url,
    required String styleLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050509),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                ),
                title: Text(
                  "View $styleLabel in full screen",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showFullScreenPreview(url, styleLabel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: Colors.white),
                title: const Text(
                  "Copy image link",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Image link copied to clipboard"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenPreview(String url, String styleLabel) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: url,
                  child: InteractiveViewer(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const ShimmerPlaceholder(
                              borderRadius: 20,
                              showLabelSkeleton: false,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const ErrorImagePlaceholder(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.style_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            styleLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
