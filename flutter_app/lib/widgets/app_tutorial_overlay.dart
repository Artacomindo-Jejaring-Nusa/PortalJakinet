import 'package:flutter/material.dart';

class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;

  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = 16,
  });
}

class AppTutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onFinish;
  final VoidCallback? onSkip;

  const AppTutorialOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
    this.onSkip,
  });

  static void show({
    required BuildContext context,
    required List<TutorialStep> steps,
    required VoidCallback onFinish,
    VoidCallback? onSkip,
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => AppTutorialOverlay(
        steps: steps,
        onFinish: () {
          overlayEntry.remove();
          onFinish();
        },
        onSkip: () {
          overlayEntry.remove();
          if (onSkip != null) {
            onSkip();
          } else {
            onFinish();
          }
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<AppTutorialOverlay> createState() => _AppTutorialOverlayState();
}

class _AppTutorialOverlayState extends State<AppTutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.steps.length - 1) {
      _animController.reverse().then((_) {
        setState(() {
          _currentIndex++;
        });
        _animController.forward();
      });
    } else {
      widget.onFinish();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _animController.reverse().then((_) {
        setState(() {
          _currentIndex--;
        });
        _animController.forward();
      });
    }
  }

  Rect? _getTargetRect(TutorialStep step) {
    final context = step.targetKey.currentContext;
    if (context == null) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Rect.fromLTWH(
      offset.dx - step.padding.left,
      offset.dy - step.padding.top,
      size.width + step.padding.horizontal,
      size.height + step.padding.vertical,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final currentStep = widget.steps[_currentIndex];
    final targetRect = _getTargetRect(currentStep);
    final screenSize = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).primaryColor;

    // Tentukan apakah tooltip berada di atas atau di bawah target
    bool isTargetInTopHalf = true;
    if (targetRect != null) {
      isTargetInTopHalf = targetRect.center.dy < (screenSize.height * 0.55);
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background gelap dengan cutout transparan
          CustomPaint(
            size: screenSize,
            painter: _HolePainter(
              targetRect: targetRect,
              borderRadius: currentStep.borderRadius,
            ),
          ),

          // Glowing border di sekeliling target
          if (targetRect != null)
            Positioned(
              left: targetRect.left,
              top: targetRect.top,
              width: targetRect.width,
              height: targetRect.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(currentStep.borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Tutorial Card
          Positioned(
            left: 20,
            right: 20,
            top: targetRect != null
                ? (isTargetInTopHalf
                    ? (targetRect.bottom + 20).clamp(60.0, screenSize.height - 240.0)
                    : null)
                : screenSize.height * 0.35,
            bottom: targetRect != null
                ? (!isTargetInTopHalf
                    ? (screenSize.height - targetRect.top + 20).clamp(80.0, screenSize.height - 220.0)
                    : null)
                : null,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Step count & Skip button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentStep.icon ?? Icons.help_outline_rounded,
                                size: 14,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Langkah ${_currentIndex + 1} dari ${widget.steps.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onSkip ?? widget.onFinish,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      currentStep.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      currentStep.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bottom Navigation Buttons & Dots Indicator
                    Row(
                      children: [
                        // Dots Indicator
                        Row(
                          children: List.generate(widget.steps.length, (idx) {
                            final isActive = idx == _currentIndex;
                            return Container(
                              margin: const EdgeInsets.only(right: 5),
                              width: isActive ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? primaryColor
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),

                        // Back Button
                        if (_currentIndex > 0)
                          OutlinedButton(
                            onPressed: _prev,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Kembali',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        if (_currentIndex > 0) const SizedBox(width: 8),

                        // Next / Selesai Button
                        ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentIndex == widget.steps.length - 1
                                ? 'Selesai'
                                : 'Lanjut',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect? targetRect;
  final double borderRadius;

  _HolePainter({
    required this.targetRect,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xCC0B132B) // Semi-transparan elegan (80% opacity)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            targetRect!,
            Radius.circular(borderRadius),
          ),
        );
      final combinedPath = Path.combine(
        PathOperation.difference,
        backgroundPath,
        holePath,
      );
      canvas.drawPath(combinedPath, paint);
    } else {
      canvas.drawPath(backgroundPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius;
  }
}
