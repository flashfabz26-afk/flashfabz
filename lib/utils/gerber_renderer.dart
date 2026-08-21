import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'gerber_parser.dart';
import 'dart:ui';
import 'gerber_drc_validator.dart';

class GerberPCBPainter extends CustomPainter {
  final GerberParseResult parseResult;
  final Set<String> visibleLayers;
  final Color maskColor;
  final bool isTop;

  final double zoom;
  final Offset pan;
  final double rotationAngle;

  final Size viewSize;

  final double gridSpacingMm;
  final bool showGrid;

  final List<DfmViolation> violations;
  final DfmViolation? selectedViolation;
  final Offset? measurementStart;
  final Offset? measurementEnd;
  final Offset mouseHoverGerber;

  const GerberPCBPainter({
    required this.parseResult,
    required this.visibleLayers,
    required this.maskColor,
    required this.isTop,
    required this.zoom,
    required this.pan,
    required this.rotationAngle,
    required this.viewSize,
    required this.gridSpacingMm,
    required this.showGrid,
    required this.violations,
    required this.selectedViolation,
    required this.measurementStart,
    required this.measurementEnd,
    required this.mouseHoverGerber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Debug summary (remove once rendering is confirmed working) ──────────
    final topT = parseResult.topCopper?.traces.length ?? 0;
    final topP = parseResult.topCopper?.pads.length ?? 0;
    final topR = parseResult.topCopper?.regions.length ?? 0;
    final botT = parseResult.bottomCopper?.traces.length ?? 0;
    final botP = parseResult.bottomCopper?.pads.length ?? 0;
    final outT = parseResult.boardOutline?.traces.length ?? 0;
    final drills = parseResult.drills.length;
    final tlT = parseResult.topLayer?.traces.length ?? 0;
    final tlP = parseResult.topLayer?.pads.length ?? 0;
    final tlR = parseResult.topLayer?.regions.length ?? 0;
    final debugMsg =
        'topCu: ${topT}tr ${topP}p ${topR}r | botCu: ${botT}tr ${botP}p | outline: ${outT}tr | drills: $drills\n'
        'topLayer: ${tlT}tr ${tlP}p ${tlR}r | bbox: ${parseResult.topLayer?.bbox}';
    final dbgPainter = TextPainter(
      text: TextSpan(
        text: debugMsg,
        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, backgroundColor: Color(0xCC000000)),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 16);
    // ────────────────────────────────────────────────────────────────────────

    Rect bbox = parseResult.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);

    if (parseResult.boardOutline != null && parseResult.boardOutline!.hasData) {
      bbox = parseResult.boardOutline!.bbox;
    } else if (parseResult.topCopper != null && parseResult.topCopper!.hasData) {
      bbox = parseResult.topCopper!.bbox;
    } else if (parseResult.bottomCopper != null && parseResult.bottomCopper!.hasData) {
      bbox = parseResult.bottomCopper!.bbox;
    } else if (parseResult.topLayer != null && parseResult.topLayer!.hasData) {
      bbox = parseResult.topLayer!.bbox;
    }

    if (bbox.width <= 0 || bbox.height <= 0 || bbox.width.isInfinite) {
      _drawPlaceholder(canvas, size, 'No Gerber geometry detected in upload');
      dbgPainter.paint(canvas, const Offset(8, 8));
      return;
    }

    const margin = 24.0;
    final double baseScale = math.min(
      (size.width - margin * 2) / bbox.width,
      (size.height - margin * 2) / bbox.height,
    );

    final Offset screenCenter = Offset(size.width / 2, size.height / 2);
    final Offset gerberCenter = bbox.center;

    Offset toScreen(Offset gerberPt) {
      double dx = gerberPt.dx - gerberCenter.dx;
      double dy = gerberPt.dy - gerberCenter.dy;

      // Invert Y axis: Gerber is Y-up, Canvas is Y-down
      dy = -dy;

      if (rotationAngle != 0.0) {
        final double rx = dx * math.cos(rotationAngle) - dy * math.sin(rotationAngle);
        final double ry = dx * math.sin(rotationAngle) + dy * math.cos(rotationAngle);
        dx = rx;
        dy = ry;
      }

      final double sx = dx * baseScale * zoom + screenCenter.dx + pan.dx;
      final double sy = dy * baseScale * zoom + screenCenter.dy + pan.dy;
      return Offset(sx, sy);
    }

    Offset toGerber(Offset screenPt) {
      double dx = (screenPt.dx - screenCenter.dx - pan.dx) / (baseScale * zoom);
      double dy = (screenPt.dy - screenCenter.dy - pan.dy) / (baseScale * zoom);

      if (rotationAngle != 0.0) {
        final double angle = -rotationAngle;
        final double rx = dx * math.cos(angle) - dy * math.sin(angle);
        final double ry = dx * math.sin(angle) + dy * math.cos(angle);
        dx = rx;
        dy = ry;
      }

      dy = -dy;
      return Offset(dx + gerberCenter.dx, dy + gerberCenter.dy);
    }

    // Clear Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF07070B),
    );

    // Draw Engineering Grid
    if (showGrid && gridSpacingMm > 0) {
      final gridPaint = Paint()
        ..color = const Color(0xFF404050).withOpacity(0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final gTopLeft = toGerber(Offset.zero);
      final gBottomRight = toGerber(Offset(size.width, size.height));

      final xMin = math.min(gTopLeft.dx, gBottomRight.dx);
      final xMax = math.max(gTopLeft.dx, gBottomRight.dx);
      final yMin = math.min(gTopLeft.dy, gBottomRight.dy);
      final yMax = math.max(gTopLeft.dy, gBottomRight.dy);

      double yStart = (yMin / gridSpacingMm).floor() * gridSpacingMm;
      double xStart = (xMin / gridSpacingMm).floor() * gridSpacingMm;

      final points = <Offset>[];
      for (double gy = yStart; gy <= yMax; gy += gridSpacingMm) {
        for (double gx = xStart; gx <= xMax; gx += gridSpacingMm) {
          points.add(toScreen(Offset(gx, gy)));
        }
      }
      canvas.drawPoints(PointMode.points, points, gridPaint);
    }

    // ─── Substrate & Board Outline ──────────────────────────────────────────

    final outlineTraces = parseResult.boardOutline?.traces ?? [];
    final boardPath = Path();
    bool hasBoardOutline = false;

    if (outlineTraces.isNotEmpty) {
      hasBoardOutline = true;
      for (final seg in outlineTraces) {
        if (seg.isArc && seg.center != null && seg.radius != null) {
          _addArcToPath(boardPath, seg, toScreen);
        } else {
          boardPath.moveTo(toScreen(seg.start).dx, toScreen(seg.start).dy);
          boardPath.lineTo(toScreen(seg.end).dx, toScreen(seg.end).dy);
        }
      }
    } else {
      final tl = toScreen(Offset(bbox.left, bbox.top));
      final tr = toScreen(Offset(bbox.right, bbox.top));
      final br = toScreen(Offset(bbox.right, bbox.bottom));
      final bl = toScreen(Offset(bbox.left, bbox.bottom));
      boardPath.moveTo(tl.dx, tl.dy);
      boardPath.lineTo(tr.dx, tr.dy);
      boardPath.lineTo(br.dx, br.dy);
      boardPath.lineTo(bl.dx, bl.dy);
      boardPath.close();
      hasBoardOutline = true;
    }

    // A. Substrate base fill
    if (hasBoardOutline) {
      canvas.drawPath(boardPath, Paint()..color = const Color(0xFF1B1D1F));
    }

    // B. Bottom Copper (if inspecting bottom)
    if (!isTop && visibleLayers.contains('bottom_copper')) {
      final layer = parseResult.bottomCopper ?? parseResult.bottomLayer;
      if (layer != null) {
        _drawCopperLayer(canvas, layer, toScreen, baseScale, color: const Color(0xFFD4933B));
      }
    }

    // C. Top Copper (if inspecting top)
    if (isTop && visibleLayers.contains('top_copper')) {
      final layer = parseResult.topCopper ?? parseResult.topLayer;
      if (layer != null) {
        _drawCopperLayer(canvas, layer, toScreen, baseScale, color: const Color(0xFFE5A440));
      }
    }

    // D. Solder Mask Layer (with openings cut out over pads and mask traces)
    final maskVisible = isTop
        ? visibleLayers.contains('top_soldermask')
        : visibleLayers.contains('bottom_soldermask');

    if (maskVisible) {
      final maskData = isTop ? parseResult.topSolderMask : parseResult.bottomSolderMask;
      final copperData = isTop ? parseResult.topCopper : parseResult.bottomCopper;

      canvas.saveLayer(null, Paint());

      // Solder Mask Fill
      if (hasBoardOutline) {
        canvas.drawPath(boardPath, Paint()..color = maskColor.withOpacity(0.92));
      } else {
        canvas.drawPaint(Paint()..color = maskColor.withOpacity(0.92));
      }

      final clearPaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;
      final clearStroke = Paint()
        ..blendMode = BlendMode.clear
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Mask openings defined in solder mask file
      if (maskData != null && maskData.hasData) {
        for (final pad in maskData.pads) {
          final sc = toScreen(pad.center);
          final sw = math.max(pad.width * baseScale * zoom, 1.5);
          final sh = math.max(pad.height * baseScale * zoom, 1.5);
          if (pad.isCircle) {
            canvas.drawCircle(sc, sw / 2, clearPaint);
          } else {
            canvas.drawRect(Rect.fromCenter(center: sc, width: sw, height: sh), clearPaint);
          }
        }
        for (final t in maskData.traces) {
          clearStroke.strokeWidth = math.max(t.width * baseScale * zoom, 1.5);
          if (t.isArc && t.center != null && t.radius != null) {
            final arcPath = Path();
            _addArcToPath(arcPath, t, toScreen);
            canvas.drawPath(arcPath, clearStroke);
          } else {
            canvas.drawLine(toScreen(t.start), toScreen(t.end), clearStroke);
          }
        }
        for (final r in maskData.regions) {
          final path = Path();
          bool first = true;
          for (final pt in r.points) {
            final sp = toScreen(pt);
            if (first) {
              path.moveTo(sp.dx, sp.dy);
              first = false;
            } else {
              path.lineTo(sp.dx, sp.dy);
            }
          }
          path.close();
          canvas.drawPath(path, clearPaint);
        }
      } else {
        // Fallback: clear ONLY over pads. Do NOT clear over traces and regions!
        final fallbackCopper = copperData ?? (isTop ? parseResult.topLayer : parseResult.bottomLayer);
        if (fallbackCopper != null) {
          // Clear pads
          for (final pad in fallbackCopper.pads) {
            final sc = toScreen(pad.center);
            final sw = math.max(pad.width * 1.05 * baseScale * zoom, 2.0);
            final sh = math.max(pad.height * 1.05 * baseScale * zoom, 2.0);
            if (pad.isCircle) {
              canvas.drawCircle(sc, sw / 2, clearPaint);
            } else {
              canvas.drawRect(Rect.fromCenter(center: sc, width: sw, height: sh), clearPaint);
            }
          }
        }
      }

      canvas.restore();
    }

    // E. Exposed Copper Highlights over Mask Openings (pads exposed through solder mask)
    final activeCopper = (isTop ? parseResult.topCopper : parseResult.bottomCopper) ??
        (isTop ? parseResult.topLayer : parseResult.bottomLayer);
    final copperLayerVisible = isTop
        ? visibleLayers.contains('top_copper')
        : visibleLayers.contains('bottom_copper');
    if (activeCopper != null && copperLayerVisible) {
      final shinyPadPaint = Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.fill;
      for (final p in activeCopper.pads) {
        final sc = toScreen(p.center);
        final sw = math.max(p.width * baseScale * zoom, 1.5);
        final sh = math.max(p.height * baseScale * zoom, 1.5);
        if (p.isCircle) {
          canvas.drawCircle(sc, sw / 2, shinyPadPaint);
        } else {
          canvas.drawRect(Rect.fromCenter(center: sc, width: sw, height: sh), shinyPadPaint);
        }
      }
    }

    // F. Silkscreen Layer (White text, reference designators, component outlines, logos)
    final silkVisible = isTop
        ? visibleLayers.contains('top_silkscreen')
        : visibleLayers.contains('bottom_silkscreen');

    if (silkVisible) {
      final silkData = isTop ? parseResult.topSilkscreen : parseResult.bottomSilkscreen;
      if (silkData != null) {
        final silkPaint = Paint()
          ..color = Colors.white
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        for (final t in silkData.traces) {
          silkPaint.strokeWidth = (t.width * baseScale * zoom).clamp(1.0, 14.0);
          if (t.isArc && t.center != null && t.radius != null) {
            final arcPath = Path();
            _addArcToPath(arcPath, t, toScreen);
            canvas.drawPath(arcPath, silkPaint);
          } else {
            canvas.drawLine(toScreen(t.start), toScreen(t.end), silkPaint);
          }
        }
        for (final p in silkData.pads) {
          final sc = toScreen(p.center);
          final sw = math.max(p.width * baseScale * zoom, 1.5);
          final sh = math.max(p.height * baseScale * zoom, 1.5);
          if (p.isCircle) {
            canvas.drawCircle(sc, sw / 2, Paint()..color = Colors.white);
          } else {
            canvas.drawRect(Rect.fromCenter(center: sc, width: sw, height: sh), Paint()..color = Colors.white);
          }
        }
        for (final r in silkData.regions) {
          final path = Path();
          bool first = true;
          for (final pt in r.points) {
            final sp = toScreen(pt);
            if (first) {
              path.moveTo(sp.dx, sp.dy);
              first = false;
            } else {
              path.lineTo(sp.dx, sp.dy);
            }
          }
          path.close();
          canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.fill);
        }
      }
    }

    // F. Board Outline Stroke
    if (visibleLayers.contains('outline')) {
      final outlinePaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = (0.25 * baseScale * zoom).clamp(1.2, 5.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(boardPath, outlinePaint);
    }

    // G. Drill Holes Layer
    if (visibleLayers.contains('drill') && parseResult.drills.isNotEmpty) {
      final drillPaint = Paint()
        ..color = const Color(0xFF050508)
        ..style = PaintingStyle.fill;
      final platingPaint = Paint()
        ..color = const Color(0xFFDE9F4D).withOpacity(0.8)
        ..style = PaintingStyle.stroke;

      for (final drill in parseResult.drills) {
        final sc = toScreen(drill.center);
        final sr = math.max((drill.diameter / 2) * baseScale * zoom, 1.2);

        platingPaint.strokeWidth = (0.15 * baseScale * zoom).clamp(0.6, 6.0);
        canvas.drawCircle(sc, sr + platingPaint.strokeWidth / 2, platingPaint);
        canvas.drawCircle(sc, sr, drillPaint);
      }
    }

    // ─── Interactive Overlay Tools ───────────────────────────────────────────

    if (selectedViolation != null) {
      final v = selectedViolation!;
      if (!((v.layerName.contains('Top') && !isTop) ||
            (v.layerName.contains('Bottom') && isTop))) {
        
        final sc = toScreen(v.position);

        final violationPaint = Paint()
          ..color = const Color(0xFFFF4D4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

        const double markerSize = 20.0;

        canvas.drawCircle(sc, markerSize, violationPaint);
        canvas.drawLine(Offset(sc.dx - markerSize * 1.5, sc.dy),
            Offset(sc.dx + markerSize * 1.5, sc.dy), violationPaint);
        canvas.drawLine(Offset(sc.dx, sc.dy - markerSize * 1.5),
            Offset(sc.dx, sc.dy + markerSize * 1.5), violationPaint);

        canvas.drawCircle(
            sc,
            markerSize * 1.5,
            Paint()
              ..color = const Color(0xFFFF4D4D).withOpacity(0.2)
              ..style = PaintingStyle.fill);
      }
    }

    if (measurementStart != null) {
      final p1 = toScreen(measurementStart!);
      final p2 = toScreen(measurementEnd ?? mouseHoverGerber);

      final measurePaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, measurePaint);
      canvas.drawCircle(p1, 4.0, Paint()..color = const Color(0xFF00E5FF));
      canvas.drawCircle(p2, 4.0, Paint()..color = const Color(0xFF00E5FF));

      final dist = (measurementStart! - (measurementEnd ?? mouseHoverGerber)).distance;
      final label =
          '${dist.toStringAsFixed(3)} mm (${(dist * 39.3701).toStringAsFixed(1)} mil)';

      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black87,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset((p1.dx + p2.dx) / 2 + 8, (p1.dy + p2.dy) / 2 - 8));
    }

    final sc = toScreen(mouseHoverGerber);
    final crosshairPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.18)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, sc.dy), Offset(size.width, sc.dy), crosshairPaint);
    canvas.drawLine(Offset(sc.dx, 0), Offset(sc.dx, size.height), crosshairPaint);

    // ── Debug overlay (remove after diagnosis) ───────────────────────────────
    dbgPainter.paint(canvas, Offset(8, size.height - dbgPainter.height - 8));
    // ─────────────────────────────────────────────────────────────────────────
  }

  void _drawCopperLayer(
      Canvas canvas, PCBLayerData layer, Offset Function(Offset) toScreen, double baseScale,
      {Color color = const Color(0xFFDE9F4D)}) {
    final tracePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final padPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Traces
    for (final t in layer.traces) {
      final double widthPx = (t.width * baseScale * zoom).clamp(0.8, 100.0);
      tracePaint.strokeWidth = widthPx;

      if (t.isArc && t.center != null && t.radius != null) {
        final arcPath = Path();
        _addArcToPath(arcPath, t, toScreen);
        canvas.drawPath(arcPath, tracePaint);
      } else {
        canvas.drawLine(toScreen(t.start), toScreen(t.end), tracePaint);
      }
    }

    // Pads
    for (final p in layer.pads) {
      final sc = toScreen(p.center);
      final sw = math.max(p.width * baseScale * zoom, 1.5);
      final sh = math.max(p.height * baseScale * zoom, 1.5);

      if (p.isCircle) {
        canvas.drawCircle(sc, sw / 2, padPaint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(center: sc, width: sw, height: sh), padPaint);
      }
    }

    // Copper Fills / Regions
    for (final r in layer.regions) {
      final path = Path();
      bool first = true;
      for (final pt in r.points) {
        final sp = toScreen(pt);
        if (first) {
          path.moveTo(sp.dx, sp.dy);
          first = false;
        } else {
          path.lineTo(sp.dx, sp.dy);
        }
      }
      path.close();
      canvas.drawPath(path, padPaint);
    }
  }

  void _addArcToPath(Path path, PCBTrace t, Offset Function(Offset) toScreen) {
    final cx = t.center!.dx;
    final cy = t.center!.dy;
    final radius = t.radius!;

    final double startAngle = t.startAngle ?? 0;
    final double sweepAngle = t.sweepAngle ?? (2 * math.pi);

    final int steps = (sweepAngle.abs() * 32).clamp(12, 60).toInt();
    for (int step = 0; step <= steps; step++) {
      final double angle = startAngle + (sweepAngle * step / steps);
      final pt = Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle));
      final sp = toScreen(pt);
      if (step == 0) {
        path.moveTo(sp.dx, sp.dy);
      } else {
        path.lineTo(sp.dx, sp.dy);
      }
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
  bool shouldRepaint(covariant GerberPCBPainter old) => true;
}

class GerberPCB3DPainter extends CustomPainter {
  final GerberParseResult parseResult;
  final Color maskColor;
  final Set<String> hiddenLayers;
  final double rotY;
  final double tiltX;
  final double zoom;

  const GerberPCB3DPainter({
    required this.parseResult,
    required this.maskColor,
    this.hiddenLayers = const {},
    required this.rotY,
    required this.tiltX,
    this.zoom = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bbox = parseResult.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);
    final aspectRaw = (bbox.width > 0 && bbox.height > 0) ? bbox.height / bbox.width : 0.65;
    final aspect = aspectRaw.clamp(0.35, 2.5);

    final boardW = size.width * 0.52 * zoom;
    final boardH = boardW * aspect;
    const thick = 8.0;

    Offset proj(double lx, double ly, double lz) {
      final rx = lx * math.cos(rotY) + lz * math.sin(rotY);
      final rz = -lx * math.sin(rotY) + lz * math.cos(rotY);
      final ry = ly * math.cos(tiltX) - rz * math.sin(tiltX);
      return Offset(cx + rx, cy + ry * 0.82);
    }

    final outlineTraces = parseResult.boardOutline?.traces ?? [];

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A12),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    if (outlineTraces.isNotEmpty) {
      final shadowPath = Path();
      bool first = true;
      for (final seg in outlineTraces) {
        final double lx = ((seg.start.dx - bbox.left) / bbox.width - 0.5) * boardW;
        final double ly = ((seg.start.dy - bbox.top) / bbox.height - 0.5) * boardH;
        final sp = proj(lx + 10, -ly + 16, -thick / 2);
        if (first) {
          shadowPath.moveTo(sp.dx, sp.dy);
          first = false;
        } else {
          shadowPath.lineTo(sp.dx, sp.dy);
        }
      }
      shadowPath.close();
      canvas.drawPath(shadowPath, shadowPaint);
    } else {
      final tl = proj(-boardW / 2 + 10, -boardH / 2 + 16, -thick / 2);
      final tr = proj(boardW / 2 + 10, -boardH / 2 + 16, -thick / 2);
      final br = proj(boardW / 2 + 10, boardH / 2 + 16, -thick / 2);
      final bl = proj(-boardW / 2 + 10, boardH / 2 + 16, -thick / 2);
      final shadowPath = Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(bl.dx, bl.dy)
        ..close();
      canvas.drawPath(shadowPath, shadowPaint);
    }

    final wallColor = const Color(0xFF8A5A12).withOpacity(0.9);

    if (outlineTraces.isNotEmpty) {
      for (final seg in outlineTraces) {
        final double lx1 = ((seg.start.dx - bbox.left) / bbox.width - 0.5) * boardW;
        final double ly1 = -((seg.start.dy - bbox.top) / bbox.height - 0.5) * boardH;
        final double lx2 = ((seg.end.dx - bbox.left) / bbox.width - 0.5) * boardW;
        final double ly2 = -((seg.end.dy - bbox.top) / bbox.height - 0.5) * boardH;

        final t1 = proj(lx1, ly1, thick / 2);
        final t2 = proj(lx2, ly2, thick / 2);
        final b2 = proj(lx2, ly2, -thick / 2);
        final b1 = proj(lx1, ly1, -thick / 2);

        final p = Path()
          ..moveTo(t1.dx, t1.dy)
          ..lineTo(t2.dx, t2.dy)
          ..lineTo(b2.dx, b2.dy)
          ..lineTo(b1.dx, b1.dy)
          ..close();
        canvas.drawPath(p, Paint()..color = wallColor);
      }
    } else {
      final corners = [
        Offset(-boardW / 2, -boardH / 2),
        Offset(boardW / 2, -boardH / 2),
        Offset(boardW / 2, boardH / 2),
        Offset(-boardW / 2, boardH / 2),
      ];
      for (int i = 0; i < 4; i++) {
        final c1 = corners[i];
        final c2 = corners[(i + 1) % 4];
        final t1 = proj(c1.dx, c1.dy, thick / 2);
        final t2 = proj(c2.dx, c2.dy, thick / 2);
        final b2 = proj(c2.dx, c2.dy, -thick / 2);
        final b1 = proj(c1.dx, c1.dy, -thick / 2);
        final p = Path()
          ..moveTo(t1.dx, t1.dy)
          ..lineTo(t2.dx, t2.dy)
          ..lineTo(b2.dx, b2.dy)
          ..lineTo(b1.dx, b1.dy)
          ..close();
        canvas.drawPath(p, Paint()..color = wallColor);
      }
    }

    final topPath = Path();
    final topPaint = Paint()..color = maskColor.withOpacity(0.92)..style = PaintingStyle.fill;

    if (outlineTraces.isNotEmpty) {
      bool first = true;
      for (final seg in outlineTraces) {
        final double lx = ((seg.start.dx - bbox.left) / bbox.width - 0.5) * boardW;
        final double ly = -((seg.start.dy - bbox.top) / bbox.height - 0.5) * boardH;
        final sp = proj(lx, ly, thick / 2);
        if (first) {
          topPath.moveTo(sp.dx, sp.dy);
          first = false;
        } else {
          topPath.lineTo(sp.dx, sp.dy);
        }
      }
      topPath.close();
      canvas.drawPath(topPath, topPaint);
    } else {
      final tl = proj(-boardW / 2, -boardH / 2, thick / 2);
      final tr = proj(boardW / 2, -boardH / 2, thick / 2);
      final br = proj(boardW / 2, boardH / 2, thick / 2);
      final bl = proj(-boardW / 2, boardH / 2, thick / 2);
      topPath.moveTo(tl.dx, tl.dy);
      topPath.lineTo(tr.dx, tr.dy);
      topPath.lineTo(br.dx, br.dy);
      topPath.lineTo(bl.dx, bl.dy);
      topPath.close();
      canvas.drawPath(topPath, topPaint);
    }

    Offset surfPt(Offset mm, double heightOffset) {
      final nx = ((mm.dx - bbox.left) / bbox.width - 0.5) * boardW;
      final ny = -((mm.dy - bbox.top) / bbox.height - 0.5) * boardH;
      return proj(nx, ny, thick / 2 + heightOffset);
    }

    if (!hiddenLayers.contains('Top.copper') && parseResult.topCopper != null) {
      final copperPaint = Paint()
        ..color = const Color(0xFFDE9F4D).withOpacity(0.85)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final t in parseResult.topCopper!.traces.take(1000)) {
        copperPaint.strokeWidth = (t.width * (boardW / bbox.width)).clamp(0.6, 8.0);

        if (t.isArc && t.center != null && t.radius != null) {
          final cx = t.center!.dx;
          final cy = t.center!.dy;
          final radius = t.radius!;
          final int steps = 12;
          final path = Path();
          final double startAngle = t.startAngle ?? 0;
          final double sweepAngle = t.sweepAngle ?? (2 * math.pi);
          for (int step = 0; step <= steps; step++) {
            final double angle = startAngle + (sweepAngle * step / steps);
            final pt = Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle));
            final sp = surfPt(pt, 0.4);
            if (step == 0) {
              path.moveTo(sp.dx, sp.dy);
            } else {
              path.lineTo(sp.dx, sp.dy);
            }
          }
          canvas.drawPath(path, copperPaint);
        } else {
          canvas.drawLine(surfPt(t.start, 0.4), surfPt(t.end, 0.4), copperPaint);
        }
      }

      final padPaint = Paint()
        ..color = const Color(0xFFDE9F4D).withOpacity(0.85)
        ..style = PaintingStyle.fill;
      for (final p in parseResult.topCopper!.pads.take(1000)) {
        final sp = surfPt(p.center, 0.4);
        final rad = (p.width / 2 * (boardW / bbox.width)).clamp(1.0, 10.0);
        canvas.drawCircle(sp, rad, padPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GerberPCB3DPainter old) => true;
}
