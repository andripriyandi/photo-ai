import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../domain/repositories/photo_session_repository.dart';

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

  String _selectedStyle = "Travel";
  String _selectedAspect = "4:5";

  static const List<String> _styleOrder = ["Travel", "City", "Cozy"];

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
      _selectedStyle = "Travel";
      _selectedAspect = "4:5";
    });
  }

  Future<void> _generate() async {
    if (_localImage == null || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.createSessionAndGenerate(
        originalFile: _localImage!,
      );

      setState(() {
        _originalUrl = result.originalUrl;
        _generatedUrls = result.generatedUrls;
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

  int _styleIndexFor(String style) {
    final idx = _styleOrder.indexOf(style);
    if (idx < 0) return 0;
    if (idx >= _generatedUrls.length) return 0;
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

  String _styleLabelForIndex(int index) {
    if (index >= 0 && index < _styleOrder.length) {
      return _styleOrder[index];
    }
    return "Scene ${index + 1}";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;
    final horizontalPadding = isWide ? size.width * 0.12 : 20.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding - 4),
          child: _buildTopPill(),
        ),
      ),
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildControlsRow(),
                            const SizedBox(height: 16),
                            _buildUploadCard(),
                            const SizedBox(height: 16),
                            _buildErrorOrHint(),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 380,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: _buildResultSection(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildBottomButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Background & header ----------

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060712), Color(0xFF050509)],
        ),
      ),
    );
  }

  Widget _buildTopPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16),
              const SizedBox(width: 8),
              const Text(
                "Photon Remix",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: .08),
                ),
                child: const Text("Prototype", style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasResult = _originalUrl != null || _generatedUrls.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Column(
        key: ValueKey(hasResult),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasResult ? "Remix complete" : "Remix your everyday photos",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasResult
                ? "Tap a scene style to preview, then long-press a tile to save or share."
                : "Add a simple portrait and we’ll turn it into travel-ready, social-ready scenes with one tap.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Controls ----------

  Widget _buildControlsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSegmentedControl(
            label: "Style",
            options: const ["Travel", "City", "Cozy"],
            value: _selectedStyle,
            onChanged: (v) {
              setState(() => _selectedStyle = v);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSegmentedControl(
            label: "Aspect",
            options: const ["4:5", "1:1", "9:16"],
            value: _selectedAspect,
            onChanged: (v) {
              setState(() => _selectedAspect = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl({
    required String label,
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.4,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: .04),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: options.map((option) {
              final isSelected = option == value;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isSelected
                        ? Colors.white.withValues(alpha: .18)
                        : Colors.transparent,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onChanged(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    final hasLocal = _localImage != null;

    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasLocal
                ? Colors.blueAccent.withValues(alpha: .7)
                : Colors.white.withValues(alpha: .16),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: .03),
              Colors.white.withValues(alpha: .02),
            ],
          ),
        ),
        child: Row(
          children: [
            _buildUploadThumbnail(),
            const SizedBox(width: 14),
            Expanded(child: _buildUploadTexts()),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: .5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadThumbnail() {
    final hasLocal = _localImage != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 64,
        height: 64,
        color: Colors.white.withValues(alpha: .04),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: hasLocal
              ? Image.file(
                  _localImage!,
                  key: const ValueKey("local"),
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.photo_camera_outlined,
                  key: const ValueKey("placeholder"),
                  size: 28,
                  color: Colors.white.withValues(alpha: .7),
                ),
        ),
      ),
    );
  }

  Widget _buildUploadTexts() {
    final hasLocal = _localImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasLocal ? "Use a different photo" : "Add a portrait photo",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          hasLocal
              ? "${_localImage!.path.split("/").last}\nTap to replace this photo."
              : "Use a clear, front-facing photo of one person for best results.",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildErrorOrHint() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
      );
    }

    return Text(
      _localImage == null
          ? "Your photo stays private: processing is handled through a secured Firebase Cloud Function."
          : "Ready when you are. Tap “Generate remix” and we’ll create multiple scenes.",
      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
    );
  }

  // ---------- Result section ----------

  Widget _buildResultSection() {
    if (_isGenerating) {
      return Center(
        key: const ValueKey("loading"),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              "Remixing your photo…\nThis can take a few moments.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_originalUrl == null && _generatedUrls.isEmpty) {
      return Align(
        key: const ValueKey("empty"),
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Once generated, your original and remixed scenes will appear here. "
            "Choose a style above to focus on Travel, City, or Cozy scenes.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ),
      );
    }

    final aspectRatio = _aspectRatioFromString(_selectedAspect);

    return ListView(
      key: const ValueKey("results"),
      children: [
        if (_originalUrl != null) ...[
          const Text(
            "Original",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image.network(
                _originalUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildShimmerPlaceholder(
                    borderRadius: 20,
                    showLabelSkeleton: false,
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorImagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (_generatedUrls.isNotEmpty) ...[
          Text(
            "$_selectedStyle scene",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildFocusedGeneratedScene(aspectRatio),
          const SizedBox(height: 16),
          const Text(
            "All remixed scenes",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 480;
              final crossAxisCount = isWide ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedUrls.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final url = _generatedUrls[index];
                  final styleLabel = _styleLabelForIndex(index);
                  final isSelected =
                      _styleOrder.indexOf(_selectedStyle) == index;
                  return _buildGeneratedTile(
                    url: url,
                    index: index,
                    styleLabel: styleLabel,
                    isSelected: isSelected,
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFocusedGeneratedScene(double aspectRatio) {
    final index = _styleIndexFor(_selectedStyle);
    final url = _generatedUrls[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildShimmerPlaceholder(
                  borderRadius: 20,
                  showLabelSkeleton: true,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorImagePlaceholder(),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withValues(alpha: .45),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.style_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedStyle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedTile({
    required String url,
    required int index,
    required String styleLabel,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (index >= 0 && index < _styleOrder.length) {
          setState(() {
            _selectedStyle = _styleOrder[index];
          });
        }
      },
      onLongPress: () {
        _showImageActionsSheet(url: url, styleLabel: styleLabel);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildShimmerPlaceholder(
                  borderRadius: 18,
                  showLabelSkeleton: true,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorImagePlaceholder(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: .55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: .45),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: .9),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  "#${index + 1}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: .55),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withValues(alpha: .9),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      styleLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final isDisabled = _localImage == null || _isGenerating;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.4 : 1,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: isDisabled ? null : _generate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGenerating) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Generating…",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ] else ...[
                const Icon(Icons.auto_awesome_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  _originalUrl == null && _generatedUrls.isEmpty
                      ? "Generate remix"
                      : "Generate new remix",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
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
                            return _buildShimmerPlaceholder(
                              borderRadius: 20,
                              showLabelSkeleton: false,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildErrorImagePlaceholder(),
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

  // ---------- Shimmer & error placeholders ----------

  Widget _buildShimmerPlaceholder({
    double borderRadius = 20,
    bool showLabelSkeleton = false,
  }) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF181826),
      highlightColor: Colors.white.withValues(alpha: 0.20),
      period: const Duration(milliseconds: 1100),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10101A), Color(0xFF151522)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius - 6),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (showLabelSkeleton)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    Container(
                      height: 14,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImagePlaceholder() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: Colors.redAccent,
        size: 32,
      ),
    );
  }
}
