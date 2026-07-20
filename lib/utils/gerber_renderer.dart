import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'gerber_parser.dart';
class GerberPCBPainter extends CustomPainter {
  final PCBLayerData layerData;
  final Color maskColor;
  final bool isTop;
  final Set<String> hiddenLayers;

  const GerberPCBPainter({
    required this.layerData,
    required this.maskColor,
    required this.isTop,
    this.hiddenLayers = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bbox = layerData.bbox;
    if (bbox.width <= 0 || bbox.height <= 0) {
      _drawPlaceholder(canvas, size, 'No Gerber geometry detected');
      return;
    }
    const margin = 28.0;
    final scale = math.min(
      (size.width - margin * 2) / bbox.width,
      (size.height - margin * 2) / bbox.height,
    );
    final boardW = bbox.width * scale;
    final boardH = bbox.height * scale;
    final ox = (size.width - boardW) / 2;
    final oy = (size.height - boardH) / 2;
    Offset c(Offset mm) => Offset(
      (mm.dx - bbox.left) * scale + ox,
      boardH - (mm.dy - bbox.top) * scale + oy,
    );

    final boardRect = Rect.fromLTWH(ox, oy, boardW, boardH);
    final boardR = math.max(2.0, math.min(6.0, scale * 0.8));
    final boardRRect = RRect.fromRectAndRadius(boardRect, Radius.circular(boardR));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A12),
    );
    canvas.drawRRect(boardRRect, Paint()..color = const Color(0xFFD6943C));
 if (!hiddenLayers.contains(isTop ? 'Top.copper' : 'Bottom.copper')) {
      final tracePaint = Paint()
        ..color = const Color(0xFFDE9F4D)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.save();
      canvas.clipRRect(boardRRect);
      final traces = layerData.traces.toList();
      if (traces.length > 8000) traces.removeRange(8000, traces.length);
      for (final t in traces) {
        tracePaint.strokeWidth = (t.width * scale).clamp(1.0, 18.0);
        canvas.drawLine(c(t.start), c(t.end), tracePaint);
      }
      canvas.restore();
    }
    if (!hiddenLayers.contains(isTop ? 'Top.copper' : 'Bottom.copper')) {
      final padPaint = Paint()
        ..color = const Color(0xFFDE9F4D)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.clipRRect(boardRRect);
      for (final p in layerData.pads) {
        final cx = c(p.center);
        final w = (p.width * scale).clamp(2.0, 50.0);
        final h = (p.height * scale).clamp(2.0, 50.0);
        if (p.isCircle) {
          canvas.drawCircle(cx, w / 2, padPaint);
        } else {
          canvas.drawRect(Rect.fromCenter(center: cx, width: w, height: h), padPaint);
        }
      }
      canvas.restore();
    }
    final showMask = !hiddenLayers.contains(isTop ? 'Top.soldermask' : 'Bottom.soldermask');
    if (showMask) {
      canvas.saveLayer(boardRect, Paint());

       canvas.drawRRect(
        boardRRect,
        Paint()..color = maskColor.withOpacity(0.85),
      );

      final clearFill = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;
      
      final clearStroke = Paint()
        ..blendMode = BlendMode.clear
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

  
      for (final p in layerData.soldermaskPads) {
        final cx = c(p.center);
        final w = (p.width * scale).clamp(1.0, 100.0);
        final h = (p.height * scale).clamp(1.0, 100.0);
        if (p.isCircle) {
          canvas.drawCircle(cx, w / 2, clearFill);
        } else {
          canvas.drawRect(Rect.fromCenter(center: cx, width: w, height: h), clearFill);
        }
      }
      for (final t in layerData.soldermaskTraces) {
        clearStroke.strokeWidth = (t.width * scale).clamp(0.5, 50.0);
        canvas.drawLine(c(t.start), c(t.end), clearStroke);
      }
      
      if (layerData.soldermaskPads.isEmpty && layerData.soldermaskTraces.isEmpty) {
        for (final p in layerData.pads) {
          final cx = c(p.center);
          final w = (p.width * scale * 0.9).clamp(2.0, 50.0);
          final h = (p.height * scale * 0.9).clamp(2.0, 50.0);
          if (p.isCircle) {
            canvas.drawCircle(cx, w / 2, clearFill);
          } else {
            canvas.drawRect(Rect.fromCenter(center: cx, width: w, height: h), clearFill);
          }
        }
      }

      canvas.restore();
    }

    if (!hiddenLayers.contains('All.outline')) {
      final outlinePaint = Paint()
        ..color = Colors.amber.shade300.withOpacity(0.7)
        ..strokeWidth = (1.5 * scale).clamp(1.0, 4.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (layerData.outline.isNotEmpty) {
        for (final seg in layerData.outline) {
          canvas.drawLine(c(seg.start), c(seg.end), outlinePaint);
        }
      } else {
        canvas.drawRRect(boardRRect, outlinePaint);
      }
    }

    if (!hiddenLayers.contains('All.drill')) {
      final ringPaint = Paint()
        ..color = const Color(0xFFDE9F4D)
        ..style = PaintingStyle.fill;
      final holePaint = Paint()
        ..color = const Color(0xFF050508)
        ..style = PaintingStyle.fill;

      for (final d in layerData.drills) {
        final cc = c(d.center);
        final r = ((d.diameter / 2) * scale).clamp(1.5, 14.0);
        canvas.drawCircle(cc, r + 1.5, ringPaint);
        canvas.drawCircle(cc, r, holePaint);
      }
    }

   
    if (!hiddenLayers.contains(isTop ? 'Top.silkscreen' : 'Bottom.silkscreen')) {
      final silkPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..strokeWidth = (0.15 * scale).clamp(0.8, 2.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.save();
      canvas.clipRRect(boardRRect);
      for (final s in layerData.silkscreen) {
        canvas.drawLine(c(s.start), c(s.end), silkPaint);
      }
      canvas.restore();
    }

  }

  void _drawPlaceholder(Canvas canvas, Size size, String msg) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A12),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: msg,
        style: const TextStyle(color: Color(0xFF3A3A55), fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GerberPCBPainter old) =>
      old.layerData != layerData ||
      old.maskColor != maskColor ||
      old.isTop != isTop ||
      old.hiddenLayers != hiddenLayers;
}


class GerberPCB3DPainter extends CustomPainter {
  final PCBLayerData topLayer;
  final Color maskColor;
  final Set<String> hiddenLayers;
  final double rotY;
  final double tiltX;

  const GerberPCB3DPainter({
    required this.topLayer,
    required this.maskColor,
    this.hiddenLayers = const {},
    this.rotY = 28 * math.pi / 180,
    this.tiltX = 32 * math.pi / 180,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bbox = topLayer.bbox;
    final aspectRaw = (bbox.width > 0 && bbox.height > 0)
        ? bbox.height / bbox.width
        : 0.65;
    final aspect = aspectRaw.clamp(0.35, 2.5);

    final boardW = size.width * 0.52;
    final boardH = boardW * aspect;
    const thick = 10.0;
    Offset proj(double lx, double ly, double lz) {
      final rx = lx * math.cos(rotY) + lz * math.sin(rotY);
      final rz = -lx * math.sin(rotY) + lz * math.cos(rotY);
      final ry = ly * math.cos(tiltX) - rz * math.sin(tiltX);
      return Offset(cx + rx, cy + ry * 0.82);
    }


    final tl = proj(-boardW / 2, -boardH / 2, thick / 2);
    final tr = proj(boardW / 2, -boardH / 2, thick / 2);
    final br = proj(boardW / 2, boardH / 2, thick / 2);
    final bl = proj(-boardW / 2, boardH / 2, thick / 2);
    final tlb = proj(-boardW / 2, -boardH / 2, -thick / 2);
    final trb = proj(boardW / 2, -boardH / 2, -thick / 2);
    final brb = proj(boardW / 2, boardH / 2, -thick / 2);
    final blb = proj(-boardW / 2, boardH / 2, -thick / 2);
    final shadowPath = Path()
      ..moveTo(tl.dx + 12, tl.dy + 18)
      ..lineTo(tr.dx + 12, tr.dy + 18)
      ..lineTo(br.dx + 12, br.dy + 18)
      ..lineTo(bl.dx + 12, bl.dy + 18)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    _quad(canvas, [tlb, trb, brb, blb], const Color(0xFF9A6218));

    _quad(canvas, [tl, tlb, blb, bl], const Color(0xFF7A4E10)); 
    _quad(canvas, [tr, trb, brb, br], const Color(0xFFBB7A1C)); 
    _quad(canvas, [tl, tr, trb, tlb], const Color(0xFF8A5A12)); 
    _quad(canvas, [bl, br, brb, blb], const Color(0xFF6A4510)); 

  
    final topPath = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(topPath, Paint()..color = maskColor.withOpacity(0.90));

    if (!hiddenLayers.contains('Top.copper') &&
        topLayer.traces.isNotEmpty &&
        bbox.width > 0) {
      Offset surfPt(Offset mm) {
        final nx = ((mm.dx - bbox.left) / bbox.width - 0.5) * boardW;
        final ny = ((mm.dy - bbox.top) / bbox.height - 0.5) * boardH;
        return proj(nx, ny, thick / 2 + 0.8);
      }

      final tp = Paint()
        ..color = const Color(0xFFDE9F4D).withOpacity(0.7)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final t in topLayer.traces.take(400)) {
        canvas.drawLine(surfPt(t.start), surfPt(t.end), tp);
      }

 
      if (!hiddenLayers.contains('Top.solderpaste')) {
        final pp = Paint()..color = const Color(0xFFDE9F4D)..style = PaintingStyle.fill;
        for (final p in topLayer.pads.take(200)) {
          canvas.drawCircle(surfPt(p.center), 2.2, pp);
        }
      }
    }

    
    if (!hiddenLayers.contains('Top.silkscreen') &&
        topLayer.silkscreen.isNotEmpty &&
        bbox.width > 0) {
      Offset surfPt(Offset mm) {
        final nx = ((mm.dx - bbox.left) / bbox.width - 0.5) * boardW;
        final ny = ((mm.dy - bbox.top) / bbox.height - 0.5) * boardH;
        return proj(nx, ny, thick / 2 + 1.0);
      }

      final sp = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final s in topLayer.silkscreen.take(200)) {
        canvas.drawLine(surfPt(s.start), surfPt(s.end), sp);
      }
    }

 
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withOpacity(0.14)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _quad(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant GerberPCB3DPainter old) =>
      old.topLayer != topLayer ||
      old.maskColor != maskColor ||
      old.hiddenLayers != hiddenLayers ||
      old.rotY != rotY ||
      old.tiltX != tiltX;
}
