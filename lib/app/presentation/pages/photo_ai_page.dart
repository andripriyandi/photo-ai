import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
    });

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 92,
    );

    if (picked == null) return;

    setState(() {
      _localImage = File(picked.path);
      _originalUrl = null;
      _generatedUrls = [];
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

      // Mapping error quota Gemini (seperti message yang kamu kirim)
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
            // ✅ Bungkus konten utama dengan LayoutBuilder + SingleChildScrollView
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
                            // Karena sudah ada scroll di luar, tidak perlu Expanded di sini.
                            // Supaya struktur tetap mirip, kita ganti Expanded dengan SizedBox + batas tinggi.
                            SizedBox(
                              height:
                                  360, // tinggi kira-kira; bisa kamu adjust kalau mau
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
                ? "Tap a scene to preview, then long-press to save or share."
                : "Drop in a simple portrait. We’ll turn it into travel-ready,\nsocial-ready scenes with one tap.",
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

  // ---------- Upload card ----------

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _localImage == null
                ? Colors.white.withValues(alpha: .16)
                : Colors.blueAccent.withValues(alpha: .7),
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
          hasLocal ? "Change source photo" : "Drop in your portrait",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          hasLocal
              ? _localImage!.path.split("/").last
              : "Use a clear, front-facing photo. One person works best.",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
        ),
      ],
    );
  }

  // ---------- Hint / error ----------

  Widget _buildErrorOrHint() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
      );
    }

    return Text(
      _localImage == null
          ? "Your photo stays private: processing runs through a secured Firebase Cloud Function."
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
            Text("Remixing your photo…", style: TextStyle(fontSize: 13)),
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
            "Once generated, your original and remixed scenes will appear here in a responsive grid.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ),
      );
    }

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
              aspectRatio: 3 / 4,
              child: Image.network(_originalUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (_generatedUrls.isNotEmpty) ...[
          const Text(
            "Remixed scenes",
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
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  final url = _generatedUrls[index];
                  return _buildGeneratedTile(url, index);
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGeneratedTile(String url, int index) {
    return GestureDetector(
      onLongPress: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(url, fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: .45),
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
                const Text(
                  "Generate remix",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
