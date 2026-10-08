import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HeroSection — Premium PCB with circuit scanning animation
// ─────────────────────────────────────────────────────────────────────────────
class HeroSection extends StatefulWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onLearnMore;
  const HeroSection({super.key, this.onGetStarted, this.onLearnMore});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {

  bool _imageLoaded = false;

  // ── Float: 7s organic hover (prime duration = never feels mechanical) ──
  late final AnimationController _floatCtrl;

  // ── Tilt: 11s slow 3D sway ─────────────────────────────────────────────
  late final AnimationController _tiltCtrl;

  // ── Scan: 3.5s vertical scanning beam sweeps top→bottom ───────────────
  late final AnimationController _scanCtrl;

  // ── Glow: 5s ambient cyan radial pulse ────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // ── Pulse: 2s energy ring burst from center ────────────────────────────
  late final AnimationController _pulseCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload image into cache so it appears instantly on first render
    precacheImage(
      const AssetImage('assets/images/pcb_hero_v2.jpg'),
      context,
    );
  }

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    _tiltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11000),
    )..repeat();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.04, end: 0.16).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _tiltCtrl.dispose();
    _scanCtrl.dispose();
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Container(
      width: double.infinity,
      height: size.height,
      color: const Color(0xFF07070A),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 24 : size.width * 0.07,
                right: isMobile ? 24 : size.width * 0.04,
                top: 80,
              ),
              child: isMobile
                  ? _buildMobileContent(size)
                  : _buildDesktopContent(size),
            ),
          ),
          // Bottom page-blend gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF07070A)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopContent(Size size) {
    return Row(
      children: [
        Expanded(
          flex: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadge(),
              const SizedBox(height: 28),
              _buildHeadline(false),
              const SizedBox(height: 24),
              _buildSubtitle(false),
              const SizedBox(height: 48),
              _buildButtons(),
              const SizedBox(height: 60),
              _buildStats(),
            ],
          ),
        ),
        Expanded(
          flex: 60,
          child: Center(child: _buildAnimatedPCBHero()),
        ),
      ],
    );
  }

  Widget _buildMobileContent(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBadge(),
        const SizedBox(height: 24),
        _buildHeadline(true),
        const SizedBox(height: 20),
        _buildSubtitle(true),
        const SizedBox(height: 40),
        _buildButtons(),
        const SizedBox(height: 40),
        SizedBox(height: 320, child: _buildAnimatedPCBHero()),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ★ Premium Animated PCB Hero
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnimatedPCBHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatCtrl, _tiltCtrl, _scanCtrl, _glowAnim, _pulseCtrl,
      ]),
      builder: (context, _) {
        final ft = _floatCtrl.value * 2 * math.pi;
        final tt = _tiltCtrl.value * 2 * math.pi;

        // Organic multi-frequency float — never repeats perfectly
        final floatY = math.sin(ft) * 9.0 + math.sin(ft * 1.7) * 3.0;

        // Very subtle 3D perspective tilt (rocking in zero-gravity)
        final tiltX = math.sin(tt * 0.8) * 0.025;
        final tiltY = math.cos(tt * 0.6) * 0.035;

        // Scale breathes at float frequency for a living feel
        final scale = 1.0 + math.sin(ft * 0.5) * 0.012;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(tiltX)
            ..rotateY(tiltY)
            ..translate(0.0, floatY)
            ..scale(scale),
          child: _buildPCBStack(),
        );
      },
    );
  }

  Widget _buildPCBStack() {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── PCB image — precached so loads instantly ────────────────
          Image.asset(
            'assets/images/pcb_hero_v2.jpg',
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if ((frame != null || wasSynchronouslyLoaded) && !_imageLoaded) {
                // Mark loaded on the very first frame — synchronous when precached
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _imageLoaded = true);
                });
              }
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),

          // ── Edge fades to melt into background ───────────────────────
          // LEFT
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF07070A),
                    const Color(0xFF07070A).withOpacity(0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.1, 0.28],
                ),
              ),
            ),
          ),
          // RIGHT
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    const Color(0xFF07070A),
                    const Color(0xFF07070A).withOpacity(0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.1, 0.28],
                ),
              ),
            ),
          ),
          // TOP
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF07070A),
                    const Color(0xFF07070A).withOpacity(0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.1, 0.28],
                ),
              ),
            ),
          ),
          // BOTTOM
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF07070A),
                    const Color(0xFF07070A).withOpacity(0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.1, 0.28],
                ),
              ),
            ),
          ),

          // ── ★ Custom animated overlays — only after image is ready ────
          if (_imageLoaded)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_scanCtrl, _glowAnim, _pulseCtrl]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _PCBEffectPainter(
                      scanProgress: _scanCtrl.value,
                      glowOpacity: _glowAnim.value,
                      pulseProgress: _pulseCtrl.value,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI elements
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF00E5FF), shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'FLASHFABZ PCB DELIVERY',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline(bool center) {
    return RichText(
      textAlign: center ? TextAlign.center : TextAlign.left,
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Powering the\n',
            style: TextStyle(
              fontSize: 72, fontWeight: FontWeight.w900,
              color: Colors.white, height: 1.05, letterSpacing: -2,
            ),
          ),
          TextSpan(
            text: 'Future ',
            style: TextStyle(
              fontSize: 72, fontWeight: FontWeight.w900,
              color: Color(0xFF00E5FF), height: 1.05, letterSpacing: -2,
            ),
          ),
          TextSpan(
            text: 'of\nElectronics.',
            style: TextStyle(
              fontSize: 72, fontWeight: FontWeight.w900,
              color: Colors.white, height: 1.05, letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(bool center) {
    return SizedBox(
      width: center ? double.infinity : 480,
      child: Text(
        'Flashfabz delivers high-performance PCBs engineered for speed, precision, and reliability. From rapid prototypes to scalable production, we turn innovative designs into dependable electronic solutions.',
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
            color: Color(0xFFB0B0C0), fontSize: 17, height: 1.7),
      ),
    );
  }

  Widget _buildButtons() {
    return Wrap(
      spacing: 16, runSpacing: 16,
      children: [
        ElevatedButton(
          onPressed: widget.onGetStarted,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Get Instant Quote',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: widget.onLearnMore,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Learn More',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              SizedBox(width: 10),
              Icon(Icons.play_circle_outline, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _stat('10K+', 'Boards Shipped'),
        _statDivider(),
        _stat('99.8%', 'Quality Rate'),
        _statDivider(),
        _stat('5–7', 'Day Delivery'),
        _statDivider(),
        _stat('ISO', 'Certified'),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.w900,
                fontSize: 24)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12)),
      ],
    );
  }

  Widget _statDivider() => Container(
      width: 1, height: 36,
      color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 24));
}

// ─────────────────────────────────────────────────────────────────────────────
// ★ PCB Effect Painter
// Draws three layers of custom effects on top of the PCB image:
//   1. Vertical scan beam  — cyan line sweeping top → bottom with a glow trail
//   2. Energy pulse rings  — concentric rings bursting from center periodically
//   3. Corner node lights  — 4 glowing circuit nodes that pulse in sequence
// ─────────────────────────────────────────────────────────────────────────────
class _PCBEffectPainter extends CustomPainter {
  final double scanProgress;   // 0.0 → 1.0
  final double glowOpacity;    // 0.04 → 0.16
  final double pulseProgress;  // 0.0 → 1.0

  const _PCBEffectPainter({
    required this.scanProgress,
    required this.glowOpacity,
    required this.pulseProgress,
  });

  static const _cyan = Color(0xFF00E5FF);
  static const _cyanDim = Color(0xFF007A8C);

  @override
  void paint(Canvas canvas, Size size) {
    _drawPulseRings(canvas, size);
    _drawCornerNodes(canvas, size);
    _drawAmbientGlow(canvas, size);
  }

  // ── 1. Vertical cyan scan beam ──────────────────────────────────────────
  void _drawScanBeam(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(scanProgress);
    final y = t * size.height;

    // The bright beam line — thin glowing cyan line
    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _cyan.withOpacity(0.6),
          _cyan.withOpacity(0.9),
          _cyan.withOpacity(0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), beamPaint);

    // Bright centre flare at beam midpoint
    final flarePaint = Paint()
      ..color = _cyan.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.width / 2, y), 3, flarePaint);
  }

  // ── 2. Concentric energy rings from centre ──────────────────────────────
  void _drawPulseRings(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.55;

    // Three staggered rings offset by 1/3 cycle each
    for (int i = 0; i < 3; i++) {
      final phase = (pulseProgress + i / 3.0) % 1.0;
      final radius = phase * maxRadius;
      final opacity = (1.0 - phase) * 0.25; // fades as it expands

      if (opacity <= 0) continue;

      final ringPaint = Paint()
        ..color = _cyan.withOpacity(opacity)
        ..strokeWidth = 1.2 * (1.0 - phase)
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(centre, radius, ringPaint);
    }
  }

  // ── 3. Corner circuit node lights ──────────────────────────────────────
  void _drawCornerNodes(Canvas canvas, Size size) {
    const inset = 0.22; // how far in from each edge (fraction of size)

    final nodes = [
      Offset(size.width * inset, size.height * inset),           // top-left
      Offset(size.width * (1 - inset), size.height * inset),     // top-right
      Offset(size.width * (1 - inset), size.height * (1 - inset)),// bottom-right
      Offset(size.width * inset, size.height * (1 - inset)),     // bottom-left
    ];

    for (int i = 0; i < nodes.length; i++) {
      // Each node pulses with a staggered phase (quarter-cycle apart)
      final phase = (pulseProgress + i * 0.25) % 1.0;
      final pulse = (math.sin(phase * 2 * math.pi) + 1) / 2; // 0→1→0
      final opacity = 0.3 + pulse * 0.5;
      final nodeRadius = 2.5 + pulse * 2.0;

      // Outer glow halo
      final haloPaint = Paint()
        ..color = _cyan.withOpacity(opacity * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + pulse * 4);
      canvas.drawCircle(nodes[i], nodeRadius + 4, haloPaint);

      // Core dot
      final dotPaint = Paint()..color = _cyan.withOpacity(opacity);
      canvas.drawCircle(nodes[i], nodeRadius, dotPaint);

      // Cross-hair tick marks (tiny circuit connector lines)
      final tickPaint = Paint()
        ..color = _cyanDim.withOpacity(opacity * 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      const tickLen = 10.0;
      canvas.drawLine(nodes[i].translate(-tickLen, 0),
          nodes[i].translate(-3, 0), tickPaint);
      canvas.drawLine(nodes[i].translate(3, 0),
          nodes[i].translate(tickLen, 0), tickPaint);
      canvas.drawLine(nodes[i].translate(0, -tickLen),
          nodes[i].translate(0, -3), tickPaint);
      canvas.drawLine(nodes[i].translate(0, 3),
          nodes[i].translate(0, tickLen), tickPaint);
    }
  }

  // ── 4. Ambient central cyan radial glow ────────────────────────────────
  void _drawAmbientGlow(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _cyan.withOpacity(glowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: centre, radius: size.width * 0.55));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(_PCBEffectPainter old) =>
      old.scanProgress != scanProgress ||
      old.glowOpacity != glowOpacity ||
      old.pulseProgress != pulseProgress;
}
