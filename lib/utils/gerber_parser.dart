import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PCB Layer Data Structures
// ═══════════════════════════════════════════════════════════════════════════

class PCBTrace {
  final Offset start;
  final Offset end;
  final double width; // mm
  const PCBTrace({required this.start, required this.end, required this.width});
}

class PCBPad {
  final Offset center;
  final double width;  // mm
  final double height; // mm
  final bool isCircle;
  const PCBPad({
    required this.center,
    required this.width,
    required this.height,
    required this.isCircle,
  });
}

class PCBDrill {
  final Offset center;
  final double diameter; // mm
  const PCBDrill({required this.center, required this.diameter});
}

class PCBLayerData {
  final List<PCBTrace> traces;
  final List<PCBPad> pads;
  final List<PCBDrill> drills;
  final List<PCBTrace> outline;    // board edge-cut segments
  final List<PCBTrace> silkscreen; // silk layer
  final List<PCBTrace> soldermaskTraces; // mask openings (traces)
  final List<PCBPad> soldermaskPads;     // mask openings (pads)
  final Rect bbox;                 // bounding box in mm

  const PCBLayerData({
    required this.traces,
    required this.pads,
    required this.drills,
    required this.outline,
    required this.silkscreen,
    required this.soldermaskTraces,
    required this.soldermaskPads,
    required this.bbox,
  });

  static PCBLayerData empty({Rect? bbox}) => PCBLayerData(
    traces: const [],
    pads: const [],
    drills: const [],
    outline: const [],
    silkscreen: const [],
    soldermaskTraces: const [],
    soldermaskPads: const [],
    bbox: bbox ?? const Rect.fromLTWH(0, 0, 100, 80),
  );

  bool get hasData => traces.isNotEmpty || pads.isNotEmpty;

  static Rect computeBBox(
    List<PCBTrace> traces,
    List<PCBPad> pads,
    List<PCBTrace> outline,
    List<PCBTrace> silkscreen,
  ) {
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    void upd(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    for (final t in [...traces, ...outline, ...silkscreen]) {
      upd(t.start.dx, t.start.dy);
      upd(t.end.dx, t.end.dy);
    }
    for (final p in pads) {
      upd(p.center.dx - p.width / 2, p.center.dy - p.height / 2);
      upd(p.center.dx + p.width / 2, p.center.dy + p.height / 2);
    }

    if (minX.isInfinite) return const Rect.fromLTWH(0, 0, 100, 80);

    final padding = math.max((maxX - minX) * 0.05, 3.0);
    return Rect.fromLTRB(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GerberParseResult
// ═══════════════════════════════════════════════════════════════════════════

class GerberParseResult {
  final String dimensions;
  final int layerCount;
  final String copperWeight;
  final String minTraceSpace;
  final String minHoleSize;
  final String material;
  final String solderMask;
  final int unitPrice;
  final int totalPrice;
  final String pcbThickness;
  final String copperThickness;
  final String pcbFinish;
  final String boardType;
  final String discreteDesign;
  final String minLineWidth;
  
  // API URLs for rendered assets
  final String? topImageUrl;
  final String? bottomImageUrl;
  final String? model3dUrl;

  // Local PCB visualization (optional, if rendered locally)
  final PCBLayerData? topLayer;
  final PCBLayerData? bottomLayer;
  final String uploadId; // unique per upload, used as ValueKey cache-buster

  const GerberParseResult({
    required this.dimensions,
    required this.layerCount,
    required this.copperWeight,
    required this.minTraceSpace,
    required this.minHoleSize,
    required this.material,
    required this.solderMask,
    required this.unitPrice,
    required this.totalPrice,
    required this.pcbThickness,
    required this.copperThickness,
    required this.pcbFinish,
    required this.boardType,
    required this.discreteDesign,
    required this.minLineWidth,
    this.topImageUrl,
    this.bottomImageUrl,
    this.model3dUrl,
    this.topLayer,
    this.bottomLayer,
    required this.uploadId,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  Internal aperture model
// ═══════════════════════════════════════════════════════════════════════════

class _Aperture {
  final String shape; // 'C', 'R', 'O', 'P'
  final double sizeX;
  final double sizeY;
  const _Aperture({required this.shape, required this.sizeX, required this.sizeY});
}

// ═══════════════════════════════════════════════════════════════════════════
//  Gerber Layer Parser — extracts traces, pads from one RS-274X file
// ═══════════════════════════════════════════════════════════════════════════

class _GerberLayerParser {
  final String content;

  double _div = 1e6;
  bool _imperial = false;
  double _x = 0.0;
  double _y = 0.0;
  int _apt = -1;
  bool _inRegion = false;

  final _apertures = <int, _Aperture>{};
  final traces = <PCBTrace>[];
  final pads = <PCBPad>[];

  _GerberLayerParser(this.content);

  void parse() {
    // Units
    _imperial = content.contains('%MOIN*%');

    // Format spec: %FSLAXabYcd*%  → decimal digits = b
    final fsm = RegExp(r'%FSL[AILTMN]*X\d(\d)Y\d\d\*%').firstMatch(content);
    if (fsm != null) {
      _div = math.pow(10, int.tryParse(fsm.group(1) ?? '6') ?? 6).toDouble();
    }

    // Aperture definitions: %ADDnC,d*% / %ADDnR,wxh*% / %ADDnO,wxh*%
    final aptRe = RegExp(r'%ADD(\d+)([CROP]),([^*]*)\*%');
    for (final m in aptRe.allMatches(content)) {
      final n = int.parse(m.group(1)!);
      final shape = m.group(2)!;
      // Parameters are separated by 'X' — handle optional secondary params
      final rawParam = m.group(3) ?? '0.1';
      // Split on X that is followed by a digit (not part of exponent)
      final parts = rawParam.split(RegExp(r'X(?=[\d.])'));
      double sx = (double.tryParse(parts[0]) ?? 0.1).abs();
      double sy = (parts.length > 1 ? double.tryParse(parts[1]) ?? sx : sx).abs();
      if (_imperial) {
        sx *= 25.4;
        sy *= 25.4;
      }
      _apertures[n] = _Aperture(shape: shape, sizeX: sx, sizeY: sy);
    }

    // Process command statements (split on '*')
    final stmts = content.split('*');
    for (final rawStmt in stmts) {
      final s = rawStmt.replaceAll(RegExp(r'[\r\n\s]'), '');
      if (s.isEmpty || s.startsWith('%')) continue;

      // Region mode
      if (s.endsWith('G36')) { _inRegion = true; continue; }
      if (s.endsWith('G37')) { _inRegion = false; continue; }

      // Main coordinate command: [Gnn][Xnnn][Ynnn][Inn][Jnn]Dnn
      final coordMatch = RegExp(
        r'^(?:G\d+)*(?:X([+-]?\d+))?(?:Y([+-]?\d+))?(?:I[+-]?\d+)?(?:J[+-]?\d+)?D(\d+)$',
      ).firstMatch(s);
      if (coordMatch != null) {
        final xStr = coordMatch.group(1);
        final yStr = coordMatch.group(2);
        final d = int.parse(coordMatch.group(3)!);

        if (d >= 10) {
          _apt = d;
          continue;
        }

        final nx = xStr != null ? _mm(int.parse(xStr)) : _x;
        final ny = yStr != null ? _mm(int.parse(yStr)) : _y;
        _execD(d, nx, ny);
        _x = nx;
        _y = ny;
        continue;
      }

      // Standalone aperture select: Dnn
      final aptSel = RegExp(r'^D(\d+)$').firstMatch(s);
      if (aptSel != null) {
        final n = int.parse(aptSel.group(1)!);
        if (n >= 10) _apt = n;
      }
    }

    // Trim for performance
    if (traces.length > 1500) traces.removeRange(1500, traces.length);
    if (pads.length > 500) pads.removeRange(500, pads.length);
  }

  void _execD(int d, double nx, double ny) {
    if (_inRegion) return;
    final ap = _apertures[_apt];
    switch (d) {
      case 1: // Draw line
        if (ap != null && (_x != nx || _y != ny)) {
          traces.add(PCBTrace(
            start: Offset(_x, _y),
            end: Offset(nx, ny),
            width: ap.sizeX.clamp(0.01, 10.0),
          ));
        }
        break;
      case 3: // Flash pad
        if (ap != null) {
          final h = (ap.sizeY > 0 ? ap.sizeY : ap.sizeX).clamp(0.05, 30.0);
          pads.add(PCBPad(
            center: Offset(nx, ny),
            width: ap.sizeX.clamp(0.05, 30.0),
            height: h,
            isCircle: ap.shape == 'C' || ap.shape == 'O',
          ));
        }
        break;
    }
  }

  double _mm(int raw) {
    double v = raw / _div;
    if (_imperial) v *= 25.4;
    return v;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Main Gerber Parser
// ═══════════════════════════════════════════════════════════════════════════

class GerberParser {
  // ── Layer file-extension matchers ────────────────────────────────────────
  static bool _isTopCopper(String n) =>
      n.endsWith('.gtl') || n.endsWith('.cmp') || 
      n.contains('f.cu') || n.contains('f_cu') ||
      (n.contains('front') && n.endsWith('.gbr')) ||
      (n.contains('top') && n.endsWith('.gbr')) ||
      (n.contains('top_copper'));

  static bool _isBottomCopper(String n) =>
      n.endsWith('.gbl') || n.endsWith('.sol') || 
      n.contains('b.cu') || n.contains('b_cu') ||
      (n.contains('back') && n.endsWith('.gbr')) ||
      (n.contains('bottom') && n.endsWith('.gbr')) ||
      (n.contains('bottom_copper'));

  static bool _isInnerCopper(String n) {
    const exts = [
      '.g1', '.g2', '.g3', '.g4', '.g5', '.g6', '.g7', '.g8',
      '.in1.cu', '.in2.cu', '.in3.cu', '.in4.cu',
      '_in1_cu', '_in2_cu', '_in3_cu', '_in4_cu',
      '.gl1', '.gl2', '.gl3', '.gl4', '.gl5', '.gl6',
    ];
    return exts.any(n.endsWith);
  }

  static bool _isOutline(String n) =>
      n.endsWith('.gko') || n.endsWith('.gm1') || n.endsWith('.gm') ||
      n.endsWith('.outline') || n.endsWith('.boardoutline') ||
      n.contains('edge.cuts') || n.contains('edge_cuts') ||
      n.contains('edgecuts') || n.contains('profile') ||
      (n.contains('outline') && n.endsWith('.gbr')) ||
      (n.contains('keepout') && n.endsWith('.gbr'));

  static bool _isDrill(String n) =>
      n.endsWith('.drl') || n.endsWith('.xln') || n.endsWith('.exc') ||
      n.endsWith('.ncd') || n.endsWith('.drd') || n.contains('pth') || n.contains('npth') ||
      (n.endsWith('.txt') && (n.contains('drill') || n.contains('nc')));

  static bool _isTopSilk(String n) =>
      n.endsWith('.gto') || n.endsWith('.plc') || 
      (n.contains('silkscreen') && (n.contains('top') || n.contains('front'))) ||
      n.contains('f.silkscreen') || n.contains('f_silkscreen') || 
      n.contains('f.silk') || n.contains('f_silk');

  static bool _isBottomSilk(String n) =>
      n.endsWith('.gbo') || n.endsWith('.pls') || 
      (n.contains('silkscreen') && (n.contains('bottom') || n.contains('back'))) ||
      n.contains('b.silkscreen') || n.contains('b_silkscreen') || 
      n.contains('b.silk') || n.contains('b_silk');

  static bool _isTopSolderMask(String n) =>
      n.endsWith('.gts') || n.endsWith('.stc') || 
      n.contains('f.mask') || n.contains('f_mask') ||
      (n.contains('mask') && (n.contains('top') || n.contains('front')));

  static bool _isBottomSolderMask(String n) =>
      n.endsWith('.gbs') || n.endsWith('.sts') || 
      n.contains('b.mask') || n.contains('b_mask') ||
      (n.contains('mask') && (n.contains('bottom') || n.contains('back')));

  static bool _isGerber(String n) =>
      n.endsWith('.gbr') || n.endsWith('.ger') || n.endsWith('.gtl') ||
      n.endsWith('.gbl') || n.endsWith('.gko') || n.endsWith('.gm1') ||
      n.endsWith('.gm') || n.endsWith('.g1') || n.endsWith('.g2') ||
      n.endsWith('.g3') || n.endsWith('.g4') || n.endsWith('.gts') ||
      n.endsWith('.gbs') || n.endsWith('.gto') || n.endsWith('.gbo') ||
      n.endsWith('.gtp') || n.endsWith('.gbp');

  static String? _tryDecode(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }

  // ── Entry point ──────────────────────────────────────────────────────────
  static GerberParseResult parseZipBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    int topLayers = 0, bottomLayers = 0, innerLayers = 0;
    String? outlineContent;
    String? drillContent;
    String? topCopperContent;
    String? bottomCopperContent;
    String? topSilkContent;
    String? bottomSilkContent;
    String? topMaskContent;
    String? bottomMaskContent;
    final allGerberContents = <String>[];

    for (final file in archive) {
      if (!file.isFile) continue;
      final raw = file.content as List<int>;
      final name = file.name.toLowerCase();

      if (_isTopCopper(name)) {
        topLayers++;
        topCopperContent ??= _tryDecode(raw);
      }
      if (_isBottomCopper(name)) {
        bottomLayers++;
        bottomCopperContent ??= _tryDecode(raw);
      }
      if (_isInnerCopper(name)) innerLayers++;
      if (outlineContent == null && _isOutline(name)) {
        outlineContent = _tryDecode(raw);
      }
      if (drillContent == null && _isDrill(name)) {
        drillContent = _tryDecode(raw);
      }
      if (topSilkContent == null && _isTopSilk(name)) {
        topSilkContent = _tryDecode(raw);
      }
      if (bottomSilkContent == null && _isBottomSilk(name)) {
        bottomSilkContent = _tryDecode(raw);
      }
      if (topMaskContent == null && _isTopSolderMask(name)) {
        topMaskContent = _tryDecode(raw);
      }
      if (bottomMaskContent == null && _isBottomSolderMask(name)) {
        bottomMaskContent = _tryDecode(raw);
      }
      if (_isGerber(name)) {
        final decoded = _tryDecode(raw);
        if (decoded != null) allGerberContents.add(decoded);
      }
    }

    if (allGerberContents.isEmpty) {
      throw Exception('No valid Gerber files found in the uploaded ZIP.');
    }

    // ── Spec calculations (existing logic) ─────────────────────────────────
    String dims;
    if (outlineContent != null) {
      dims = _parseDimensions(outlineContent);
    } else {
      dims = 'Unknown';
    }
    if (dims == 'Unknown' && allGerberContents.isNotEmpty) {
      dims = _parseDimensionsFromMultiple(allGerberContents);
    }

    final layerCount = _computeLayerCount(topLayers, bottomLayers, innerLayers, archive.length);
    final holeSize = _parseMinHole(drillContent);
    final minLine = _detectMinLineWidth(allGerberContents);
    final area = _areaFromDims(dims);
    final unitPrice = _calcPrice(area, layerCount);
    final copperUm = layerCount >= 4 ? '2 oz / 70 µm' : '1 oz / 35 µm';

    // ── Geometry extraction ────────────────────────────────────────────────

    // Outline segments
    final outlineSegs = <PCBTrace>[];
    if (outlineContent != null) {
      final p = _GerberLayerParser(outlineContent);
      p.parse();
      outlineSegs.addAll(p.traces);
      // Flashed pads on outline layers are rare, ignore pads here
    }

    // Top copper
    final topTraces = <PCBTrace>[], topPads = <PCBPad>[];
    if (topCopperContent != null) {
      final p = _GerberLayerParser(topCopperContent);
      p.parse();
      topTraces.addAll(p.traces);
      topPads.addAll(p.pads);
    }

    // Bottom copper
    final botTraces = <PCBTrace>[], botPads = <PCBPad>[];
    if (bottomCopperContent != null) {
      final p = _GerberLayerParser(bottomCopperContent);
      p.parse();
      botTraces.addAll(p.traces);
      botPads.addAll(p.pads);
    }

    // Silkscreen
    final topSilkTraces = <PCBTrace>[];
    if (topSilkContent != null) {
      final p = _GerberLayerParser(topSilkContent);
      p.parse();
      topSilkTraces.addAll(p.traces);
    }
    final botSilkTraces = <PCBTrace>[];
    if (bottomSilkContent != null) {
      final p = _GerberLayerParser(bottomSilkContent);
      p.parse();
      botSilkTraces.addAll(p.traces);
    }

    // Solder Mask
    final topMaskTraces = <PCBTrace>[], topMaskPads = <PCBPad>[];
    if (topMaskContent != null) {
      final p = _GerberLayerParser(topMaskContent);
      p.parse();
      topMaskTraces.addAll(p.traces);
      topMaskPads.addAll(p.pads);
    }
    final botMaskTraces = <PCBTrace>[], botMaskPads = <PCBPad>[];
    if (bottomMaskContent != null) {
      final p = _GerberLayerParser(bottomMaskContent);
      p.parse();
      botMaskTraces.addAll(p.traces);
      botMaskPads.addAll(p.pads);
    }

    // Drill holes
    final drills = _parseDrillList(drillContent);

    // Compute unified bbox across both layers + outline
    final Rect overallBbox;
    final allTraces = [...topTraces, ...botTraces, ...outlineSegs];
    final allPads = [...topPads, ...botPads];
    if (allTraces.isNotEmpty || allPads.isNotEmpty) {
      overallBbox = PCBLayerData.computeBBox(allTraces, allPads, outlineSegs, []);
    } else {
      // Fallback: derive from dimension string
      final m = RegExp(r'([\d.]+)\s*mm\s*x\s*([\d.]+)\s*mm').firstMatch(dims);
      final w = double.tryParse(m?.group(1) ?? '') ?? 100;
      final h = double.tryParse(m?.group(2) ?? '') ?? 80;
      overallBbox = Rect.fromLTWH(0, 0, w, h);
    }

    final topLayerData = PCBLayerData(
      traces: topTraces,
      pads: topPads,
      drills: drills,
      outline: outlineSegs,
      silkscreen: topSilkTraces,
      soldermaskTraces: topMaskTraces,
      soldermaskPads: topMaskPads,
      bbox: overallBbox,
    );
    final botLayerData = PCBLayerData(
      traces: botTraces,
      pads: botPads,
      drills: drills,
      outline: outlineSegs,
      silkscreen: botSilkTraces,
      soldermaskTraces: botMaskTraces,
      soldermaskPads: botMaskPads,
      bbox: overallBbox,
    );

    return GerberParseResult(
      dimensions:      dims,
      layerCount:      layerCount,
      copperWeight:    layerCount >= 4 ? '2 oz' : '1 oz',
      minTraceSpace:   layerCount >= 4 ? '4/4 mil' : '6/6 mil',
      minHoleSize:     holeSize,
      material:        'FR-4',
      solderMask:      'Green',
      unitPrice:       unitPrice,
      totalPrice:      unitPrice * 10,
      pcbThickness:    '1.6 mm',
      copperThickness: copperUm,
      pcbFinish:       'HASL (with lead)',
      boardType:       'Single Piece',
      discreteDesign:  '1 Design',
      minLineWidth:    minLine,
      topLayer:        topLayerData,
      bottomLayer:     botLayerData,
      uploadId:        'upload_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(99999)}',
    );
  }

  // ── Excellon drill file parser ───────────────────────────────────────────
  static List<PCBDrill> _parseDrillList(String? content) {
    if (content == null) return [];
    final drills = <PCBDrill>[];
    final toolDefs = <int, double>{};

    // Tool diameter definitions: T01C0.300
    final toolRe = RegExp(r'T(\d+)C([\d.]+)');
    for (final m in toolRe.allMatches(content)) {
      double d = double.tryParse(m.group(2) ?? '0.3') ?? 0.3;
      if (d < 0.1) d *= 25.4; // inches → mm
      toolDefs[int.parse(m.group(1)!)] = d;
    }

    final isMetric = content.contains('METRIC') ||
        content.contains(',LZ') ||
        content.contains('M71') ||
        content.contains('G71');
    int currentTool = 1;

    for (final line in content.split(RegExp(r'\r?\n'))) {
      final t = line.trim();
      if (t.startsWith(';') || t.startsWith('%') || t.startsWith('M48') || t.isEmpty) continue;

      // Tool select: T01
      final ts = RegExp(r'^T(\d+)$').firstMatch(t);
      if (ts != null) {
        currentTool = int.parse(ts.group(1)!);
        continue;
      }

      // Drill hit: X...Y...
      final dh = RegExp(r'X([+-]?[\d.]+)Y([+-]?[\d.]+)').firstMatch(t);
      if (dh != null) {
        double x = double.tryParse(dh.group(1)!) ?? 0;
        double y = double.tryParse(dh.group(2)!) ?? 0;

        // Auto-scale integer coordinates (no decimal point → legacy format)
        if (!dh.group(1)!.contains('.')) {
          if (x.abs() > 10000) {
            x /= 100000;
            y /= 100000;
          } else if (x.abs() > 1000) {
            x /= 10000;
            y /= 10000;
          } else if (x.abs() > 100) {
            x /= 1000;
            y /= 1000;
          }
        }

        // Convert inches to mm if imperial
        if (!isMetric && x.abs() < 100) {
          x *= 25.4;
          y *= 25.4;
        }

        if (x.abs() < 600 && y.abs() < 600 && (x != 0 || y != 0)) {
          drills.add(PCBDrill(
            center: Offset(x, y),
            diameter: toolDefs[currentTool] ?? 0.3,
          ));
        }
      }
    }

    return drills.take(600).toList();
  }

  // ── Spec helpers (unchanged from original) ───────────────────────────────

  static int _computeLayerCount(int top, int bottom, int inner, int totalFiles) {
    if (top > 0 || bottom > 0 || inner > 0) {
      final detected = (top > 0 ? 1 : 0) + (bottom > 0 ? 1 : 0) + inner;
      if (detected <= 2) return 2;
      if (detected <= 4) return 4;
      if (detected <= 6) return 6;
      return 8;
    }
    if (totalFiles >= 14) return 6;
    if (totalFiles >= 8) return 4;
    return 2;
  }

  static String _parseDimensions(String content) => _extractBBox(content);

  static String _parseDimensionsFromMultiple(List<String> contents) {
    double bestW = 0, bestH = 0;
    for (final c in contents) {
      final r = _extractBBox(c);
      if (r == 'Unknown') continue;
      final m = RegExp(r'([\d.]+)\s*mm\s*x\s*([\d.]+)\s*mm').firstMatch(r);
      if (m == null) continue;
      final w = double.tryParse(m.group(1) ?? '') ?? 0;
      final h = double.tryParse(m.group(2) ?? '') ?? 0;
      if (w * h > bestW * bestH) {
        bestW = w;
        bestH = h;
      }
    }
    if (bestW == 0 || bestH == 0) return 'Unknown';
    return '${bestW.toStringAsFixed(2)} mm x ${bestH.toStringAsFixed(2)} mm';
  }

  static String _extractBBox(String content) {
    bool isImperial = content.contains('%MOIN*%') ||
        content.contains('MOIN') ||
        (!content.contains('%MOMM*%') && !content.contains('MOMM'));

    int decimalDigits = 6;
    final fsMatch = RegExp(r'%FSLA[LT]?X(\d)(\d)Y(\d)(\d)').firstMatch(content);
    if (fsMatch != null) {
      decimalDigits = int.tryParse(fsMatch.group(2) ?? '6') ?? 6;
    } else {
      final fs2 = RegExp(r'%FSLA.*?X\d(\d)').firstMatch(content);
      if (fs2 != null) {
        decimalDigits = int.tryParse(fs2.group(1) ?? '6') ?? 6;
      }
    }
    final divisor = math.pow(10, decimalDigits).toDouble();

    final coordLine = RegExp(r'X([+-]?\d+)Y([+-]?\d+)');
    final matches = coordLine.allMatches(content);
    if (matches.isEmpty) return 'Unknown';

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final m in matches) {
      final xRaw = int.tryParse(m.group(1) ?? '');
      final yRaw = int.tryParse(m.group(2) ?? '');
      if (xRaw == null || yRaw == null) continue;
      final x = xRaw / divisor;
      final y = yRaw / divisor;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    if (minX.isInfinite || minY.isInfinite) return 'Unknown';

    double width = (maxX - minX).abs();
    double height = (maxY - minY).abs();
    if (isImperial) {
      width *= 25.4;
      height *= 25.4;
    }
    if (width < 1 || height < 1 || width > 800 || height > 800) return 'Unknown';
    return '${width.toStringAsFixed(2)} mm x ${height.toStringAsFixed(2)} mm';
  }

  static String _parseMinHole(String? content) {
    if (content == null) return '0.30 mm';
    final toolPattern = RegExp(r'T\d+C([\d.]+)');
    final matches = toolPattern.allMatches(content);
    double minDia = double.infinity;
    for (final m in matches) {
      final dia = double.tryParse(m.group(1) ?? '');
      if (dia != null && dia > 0 && dia < minDia) minDia = dia;
    }
    if (minDia.isInfinite) return '0.30 mm';
    if (minDia < 0.1) minDia *= 25.4;
    return '${minDia.toStringAsFixed(2)} mm';
  }

  static String _detectMinLineWidth(List<String> contents) {
    double minWidth = double.infinity;
    final circleAperture = RegExp(r'%ADD\d+C,([\d.]+)');
    final rectAperture = RegExp(r'%ADD\d+R,([\d.]+)X([\d.]+)');
    for (final content in contents) {
      for (final m in circleAperture.allMatches(content)) {
        final d = double.tryParse(m.group(1) ?? '');
        if (d != null && d > 0.01 && d < minWidth) minWidth = d;
      }
      for (final m in rectAperture.allMatches(content)) {
        final w = double.tryParse(m.group(1) ?? '');
        final h = double.tryParse(m.group(2) ?? '');
        if (w != null && h != null) {
          final s = math.min(w, h);
          if (s > 0.01 && s < minWidth) minWidth = s;
        }
      }
    }
    if (minWidth.isInfinite || minWidth > 10) return '0.20 mm';
    if (minWidth < 0.05) minWidth *= 25.4;
    return '${minWidth.toStringAsFixed(2)} mm';
  }

  static double _areaFromDims(String dims) {
    final m = RegExp(r'([\d.]+)\s*mm\s*x\s*([\d.]+)\s*mm').firstMatch(dims);
    if (m == null) return 5000;
    final w = double.tryParse(m.group(1) ?? '') ?? 70;
    final h = double.tryParse(m.group(2) ?? '') ?? 70;
    return w * h;
  }

  static int _calcPrice(double areaMm2, int layers) {
    final cm2 = areaMm2 / 100.0;
    final raw = (cm2 * 2.0 * layers).round();
    return math.max(raw, 80);
  }
}
