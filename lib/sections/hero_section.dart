import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeroSection extends StatelessWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onLearnMore;
  const HeroSection({super.key, this.onGetStarted, this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Container(
      width: double.infinity,
      height: size.height,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HeroBgPainter())),

          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 24 : size.width * 0.08,
                right: isMobile ? 24 : size.width * 0.08,
                top: 80, 
              ),
              child: isMobile
                  ? _buildMobileContent(size)
                  : _buildDesktopContent(size),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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

  Widget _buildDesktopContent(Size size) {
    return Row(
      children: [
        Expanded(
          flex: 55,
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
        const SizedBox(width: 40),
        Expanded(
          flex: 45,
          child: _buildPCBHero(),
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
        SizedBox(height: 200, child: _buildPCBHero()),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF00E5FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '8 HOUR PCB DELIVERY',
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
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -2,
            ),
          ),
          TextSpan(
            text: 'Future ',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00E5FF),
              height: 1.05,
              letterSpacing: -2,
            ),
          ),
          TextSpan(
            text: 'of\nElectronics.',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.05,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(bool center) {
    return SizedBox(
      width: center ? double.infinity : 520,
      child: Text(
        '8HRPCB delivers high-performance Power PCB Design & Manufacturing — engineered for reliability, thermal efficiency, and scale.',
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(color: Color(0xFFB0B0C0), fontSize: 17, height: 1.7),
      ),
    );
  }

  Widget _buildButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ElevatedButton(
          onPressed: onGetStarted,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Get Instant Quote', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onLearnMore,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Learn More', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
                color: Color(0xFF00E5FF), fontWeight: FontWeight.w900, fontSize: 24)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12)),
      ],
    );
  }

  Widget _statDivider() => Container(
      width: 1, height: 36, color: Colors.white.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 24));

  Widget _buildPCBHero() {
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _HeroPCBPainter(),
      ),
    );
  }
}


class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF07070A),
    );

  
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.03);
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeroBgPainter old) => false;
}


class _HeroPCBPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bw = size.width * 0.85;
    final bh = size.height * 0.75;

    
    canvas.drawCircle(
      Offset(cx, cy),
      math.min(bw, bh) * 0.62,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

  
    final board = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      board,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF0D2E1A), const Color(0xFF071A0D)],
        ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh)),
    );

    canvas.drawRRect(
      board,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    
    final tracePaint = Paint()
      ..color = const Color(0xFFFF6B35).withOpacity(0.75)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final traces = [
      [Offset(cx - 120, cy - 50), Offset(cx - 50, cy - 50)],
      [Offset(cx - 50, cy - 50), Offset(cx - 50, cy + 40)],
      [Offset(cx + 60, cy - 70), Offset(cx + 60, cy + 10)],
      [Offset(cx - 100, cy + 50), Offset(cx + 100, cy + 50)],
      [Offset(cx + 100, cy + 50), Offset(cx + 100, cy - 30)],
      [Offset(cx - 80, cy - 10), Offset(cx - 20, cy - 10)],
      [Offset(cx - 20, cy - 10), Offset(cx + 30, cy - 10)],
      [Offset(cx + 30, cy - 10), Offset(cx + 30, cy - 70)],
    ];
    for (final t in traces) canvas.drawLine(t[0], t[1], tracePaint);

    
    final tracePaint2 = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final traces2 = [
      [Offset(cx - 120, cy + 10), Offset(cx - 20, cy + 10)],
      [Offset(cx + 80, cy - 20), Offset(cx + 80, cy + 50)],
      [Offset(cx - 60, cy - 70), Offset(cx + 10, cy - 70)],
    ];
    for (final t in traces2) canvas.drawLine(t[0], t[1], tracePaint2);

    
    _drawIC(canvas, cx + 15, cy - 22, 80, 55, const Color(0xFF1A1A2E));

    
    _drawCap(canvas, cx - 110, cy - 30, const Color(0xFF252540));
    _drawCap(canvas, cx + 100, cy + 20, const Color(0xFF252540));

    
    final padPositions = [
      Offset(cx - 120, cy - 50), Offset(cx - 50, cy - 50),
      Offset(cx + 60, cy - 70), Offset(cx + 60, cy + 10),
      Offset(cx - 80, cy - 10), Offset(cx + 30, cy - 70),
      Offset(cx - 100, cy + 50), Offset(cx + 100, cy - 30),
    ];
    for (final pos in padPositions) {
      canvas.drawCircle(pos, 6, Paint()..color = const Color(0xFFFF6B35).withOpacity(0.9));
      canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFF071A0D));
    }

    
    for (final pos in [
      Offset(cx - bw / 2 + 18, cy - bh / 2 + 18),
      Offset(cx + bw / 2 - 18, cy - bh / 2 + 18),
      Offset(cx - bw / 2 + 18, cy + bh / 2 - 18),
      Offset(cx + bw / 2 - 18, cy + bh / 2 - 18),
    ]) {
      canvas.drawCircle(pos, 7,
          Paint()..color = const Color(0xFF00E5FF).withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFF071A0D));
    }
  }

  void _drawIC(Canvas canvas, double x, double y, double w, double h, Color color) {
    final ic = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h), const Radius.circular(4));
    canvas.drawRRect(ic, Paint()..color = color);
    canvas.drawRRect(
        ic,
        Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    
    final p = Paint()..color = const Color(0xFFFF6B35).withOpacity(0.7)..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
          Offset(x - w / 2 - 8, y - h / 4 + i * (h / 3)), Offset(x - w / 2, y - h / 4 + i * (h / 3)), p);
      canvas.drawLine(
          Offset(x + w / 2, y - h / 4 + i * (h / 3)), Offset(x + w / 2 + 8, y - h / 4 + i * (h / 3)), p);
    }
  }

  void _drawCap(Canvas canvas, double x, double y, Color color) {
    canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 16, height: 22),
        Paint()..color = color);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 16, height: 22),
        Paint()..color = const Color(0xFF00E5FF).withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_HeroPCBPainter old) => false;
}
