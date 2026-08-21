import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PCBTrace {
  final Offset start;
  final Offset end;
  final double width;
  final bool isArc;
  final Offset? center;
  final double? radius;
  final double? startAngle;
  final double? sweepAngle;
  final bool dark;

  const PCBTrace({
    required this.start,
    required this.end,
    required this.width,
    this.isArc = false,
    this.center,
    this.radius,
    this.startAngle,
    this.sweepAngle,
    this.dark = true,
  });
}

class PCBPad {
  final Offset center;
  final double width;
  final double height;
  final bool isCircle;
  final bool dark;
  final double rotation;

  const PCBPad({
    required this.center,
    required this.width,
    required this.height,
    required this.isCircle,
    this.dark = true,
    this.rotation = 0.0,
  });
}

class PCBDrill {
  final Offset center;
  final double diameter;
  const PCBDrill({required this.center, required this.diameter});
}

class PCBRegion {
  final List<Offset> points;
  final bool dark;
  const PCBRegion({required this.points, this.dark = true});
}

class PCBLayerData {
  final List<PCBTrace> traces;
  final List<PCBPad> pads;
  final List<PCBDrill> drills;
  final List<PCBTrace> outline;
  final List<PCBTrace> silkscreen;
  final List<PCBTrace> soldermaskTraces;
  final List<PCBPad> soldermaskPads;
  final List<PCBRegion> regions;
  final Rect bbox;

  const PCBLayerData({
    required this.traces,
    required this.pads,
    required this.drills,
    required this.outline,
    required this.silkscreen,
    required this.soldermaskTraces,
    required this.soldermaskPads,
    required this.regions,
    required this.bbox,
  });

  bool get hasData =>
      traces.isNotEmpty ||
      pads.isNotEmpty ||
      regions.isNotEmpty ||
      outline.isNotEmpty ||
      drills.isNotEmpty;

  static PCBLayerData empty({Rect? bbox}) => PCBLayerData(
        traces: const [],
        pads: const [],
        drills: const [],
        outline: const [],
        silkscreen: const [],
        soldermaskTraces: const [],
        soldermaskPads: const [],
        regions: const [],
        bbox: bbox ?? const Rect.fromLTWH(0, 0, 100, 80),
      );

  static Rect computeBBox(
    List<PCBTrace> traces,
    List<PCBPad> pads,
    List<PCBTrace> outline,
    List<PCBTrace> silkscreen,
    List<PCBRegion> regions,
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
    for (final r in regions) {
      for (final p in r.points) {
        upd(p.dx, p.dy);
      }
    }

    if (minX.isInfinite) return const Rect.fromLTWH(0, 0, 100, 80);

    final padding = math.max((maxX - minX) * 0.05, 2.0);
    return Rect.fromLTRB(
        minX - padding, minY - padding, maxX + padding, maxY + padding);
  }
}

class GerberFileDebugInfo {
  final String fileName;
  final String layerType;
  final int fileSize;
  final int parsedCommandCount;
  final int parsedGeometryCount;
  final int apertureCount;
  final int coordinateCount;

  GerberFileDebugInfo({
    required this.fileName,
    required this.layerType,
    required this.fileSize,
    required this.parsedCommandCount,
    required this.parsedGeometryCount,
    required this.apertureCount,
    required this.coordinateCount,
  });

  void log() {
    debugPrint('''
==================================================
GERBER FILE PARSE SUMMARY
FILE NAME:             $fileName
LAYER TYPE:            $layerType
FILE SIZE:             $fileSize bytes
PARSED COMMAND COUNT:  $parsedCommandCount
PARSED GEOMETRY COUNT: $parsedGeometryCount
APERTURE COUNT:        $apertureCount
COORDINATE COUNT:      $coordinateCount
==================================================''');
  }
}

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
  final String? topImageUrl;
  final String? bottomImageUrl;
  final String? model3dUrl;
  final String uploadId;

  final PCBLayerData? topCopper;
  final PCBLayerData? bottomCopper;
  final PCBLayerData? topSolderMask;
  final PCBLayerData? bottomSolderMask;
  final PCBLayerData? topSilkscreen;
  final PCBLayerData? bottomSilkscreen;
  final PCBLayerData? topPaste;
  final PCBLayerData? bottomPaste;
  final PCBLayerData? boardOutline;
  final List<PCBDrill> drills;

  final PCBLayerData? topLayer;
  final PCBLayerData? bottomLayer;
  final List<GerberFileDebugInfo> debugLogs;

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
    this.topCopper,
    this.bottomCopper,
    required this.topSolderMask,
    required this.bottomSolderMask,
    required this.topSilkscreen,
    required this.bottomSilkscreen,
    required this.topPaste,
    required this.bottomPaste,
    required this.boardOutline,
    required this.drills,
    this.topLayer,
    this.bottomLayer,
    required this.uploadId,
    this.debugLogs = const [],
  });
}

class _Aperture {
  final String shape; // 'C' (circle), 'R' (rect), 'O' (oval), 'P' (poly)
  final double sizeX;
  final double sizeY;
  final List<double> params;

  const _Aperture({
    required this.shape,
    required this.sizeX,
    required this.sizeY,
    this.params = const [],
  });
}

class _GerberLayerParser {
  final String content;

  int _intX = 4, _decX = 4;
  int _intY = 4, _decY = 4;
  double _divX = 10000.0, _divY = 10000.0;
  bool _imperial = false; // MOIN
  bool _isTrailingZeroSuppression = false;
  bool _isLeadingZeroSuppression = true;

  double _x = 0.0;
  double _y = 0.0;
  int _apt = -1;
  bool _inRegion = false;
  bool _dark = true;
  int _lastD = 2; // Default to Move
  int _interpolationMode = 1; // 1=Linear, 2=CW, 3=CCW

  final _apertures = <int, _Aperture>{};
  final traces = <PCBTrace>[];
  final pads = <PCBPad>[];
  final regions = <PCBRegion>[];
  final List<Offset> _activeRegionPoints = [];

  int parsedCommandCount = 0;
  int coordinateCount = 0;

  _GerberLayerParser(this.content);

  void parse() {
    final List<String> stmts = [];
    int i = 0;
    while (i < content.length) {
      final code = content.codeUnitAt(i);
      if (code == 32 || code == 9 || code == 10 || code == 13) {
        i++;
        continue;
      }

      if (content[i] == '%') {
        int nextPct = content.indexOf('%', i + 1);
        if (nextPct == -1) {
          stmts.add(content.substring(i));
          break;
        }
        stmts.add(content.substring(i, nextPct + 1));
        i = nextPct + 1;
      } else {
        int nextStar = content.indexOf('*', i);
        if (nextStar == -1) {
          final s = content.substring(i).trim();
          if (s.isNotEmpty) stmts.add(s);
          break;
        }
        stmts.add(content.substring(i, nextStar));
        i = nextStar + 1;
      }
    }

    parsedCommandCount = stmts.length;

    for (var stmt in stmts) {
      final s = stmt.replaceAll(RegExp(r'[\r\n\s]'), '');
      if (s.isEmpty) continue;

      if (s.startsWith('%')) {
        final inner = s.substring(1, s.length - (s.endsWith('%') ? 1 : 0));
        final params = inner.split('*').where((e) => e.isNotEmpty);
        for (final p in params) {
          _parseParameter(p);
        }
      } else {
        _parseDataStatement(s);
      }
    }
  }

  void _parseParameter(String p) {
    if (p.startsWith('FS')) {
      _isTrailingZeroSuppression = p.contains('T');
      _isLeadingZeroSuppression = p.contains('L') || !_isTrailingZeroSuppression;
      final mx = RegExp(r'X(\d)(\d)').firstMatch(p);
      final my = RegExp(r'Y(\d)(\d)').firstMatch(p);
      if (mx != null) {
        _intX = int.parse(mx.group(1)!);
        _decX = int.parse(mx.group(2)!);
        _divX = math.pow(10, _decX).toDouble();
      }
      if (my != null) {
        _intY = int.parse(my.group(1)!);
        _decY = int.parse(my.group(2)!);
        _divY = math.pow(10, _decY).toDouble();
      }
    } else if (p.startsWith('MO')) {
      if (p.contains('IN')) _imperial = true;
      if (p.contains('MM')) _imperial = false;
    } else if (p.startsWith('AD')) {
      final aptMatch = RegExp(r'^ADD(\d+)([a-zA-Z_0-9]+),?([^*]+)?').firstMatch(p);
      if (aptMatch != null) {
        final code = int.parse(aptMatch.group(1)!);
        final shape = aptMatch.group(2)!;
        final rawParams = aptMatch.group(3) ?? '';
        final paramParts = rawParams.split(RegExp(r'[xX,]'));

        final params = paramParts
            .map((e) => double.tryParse(e) ?? 0.0)
            .where((v) => v > 0)
            .toList();

        double sx = params.isNotEmpty ? params[0] : 0.2;
        double sy = params.length > 1 ? params[1] : sx;

        if (_imperial) {
          sx *= 25.4;
          sy *= 25.4;
          for (int idx = 0; idx < params.length; idx++) {
            params[idx] *= 25.4;
          }
        }

        _apertures[code] = _Aperture(
          shape: shape,
          sizeX: math.max(sx, 0.05),
          sizeY: math.max(sy, 0.05),
          params: params,
        );
      }
    } else if (p.startsWith('LP')) {
      _dark = p.contains('D');
    }
  }

  void _parseDataStatement(String rawStmt) {
    var s = rawStmt;

    if (s.startsWith('G04') || s.startsWith('G4')) return; // Comment

    if (s == 'G36') {
      _inRegion = true;
      _activeRegionPoints.clear();
      return;
    }
    if (s == 'G37') {
      _inRegion = false;
      if (_activeRegionPoints.length >= 3) {
        regions.add(PCBRegion(
          points: List.from(_activeRegionPoints),
          dark: _dark,
        ));
      }
      _activeRegionPoints.clear();
      return;
    }

    // Strip leading G-codes & update state
    if (s.startsWith('G01') || s.startsWith('G1')) {
      _interpolationMode = 1;
      s = s.replaceAll(RegExp(r'^G0?1'), '');
    } else if (s.startsWith('G02') || s.startsWith('G2')) {
      _interpolationMode = 2;
      s = s.replaceAll(RegExp(r'^G0?2'), '');
    } else if (s.startsWith('G03') || s.startsWith('G3')) {
      _interpolationMode = 3;
      s = s.replaceAll(RegExp(r'^G0?3'), '');
    } else if (s.startsWith('G54') || s.startsWith('G55')) {
      s = s.replaceAll(RegExp(r'^G5[45]'), '');
    } else if (s.startsWith('G70')) {
      _imperial = true;
      s = s.substring(3);
    } else if (s.startsWith('G71')) {
      _imperial = false;
      s = s.substring(3);
    }

    if (s.isEmpty) return;

    // Check standalone D-code aperture select like D10, D11...
    final standAloneApt = RegExp(r'^D([1-9]\d+)$').firstMatch(s);
    if (standAloneApt != null) {
      final code = int.parse(standAloneApt.group(1)!);
      if (code >= 10) _apt = code;
      return;
    }

    final xMatch = RegExp(r'X([+-]?[\d.]+)').firstMatch(s);
    final yMatch = RegExp(r'Y([+-]?[\d.]+)').firstMatch(s);
    final iMatch = RegExp(r'I([+-]?[\d.]+)').firstMatch(s);
    final jMatch = RegExp(r'J([+-]?[\d.]+)').firstMatch(s);
    final dMatch = RegExp(r'D(\d+)').firstMatch(s);

    if (xMatch == null && yMatch == null && dMatch == null) {
      return;
    }

    final xStr = xMatch?.group(1);
    final yStr = yMatch?.group(1);
    final iStr = iMatch?.group(1);
    final jStr = jMatch?.group(1);
    final dVal = dMatch != null ? int.tryParse(dMatch.group(1)!) : null;

    if (xStr != null || yStr != null) {
      coordinateCount++;
    }

    final nx = _parseCoord(xStr, _x, _decX, _intX + _decX, _divX);
    final ny = _parseCoord(yStr, _y, _decY, _intY + _decY, _divY);

    if (dVal != null && dVal >= 10) {
      _apt = dVal;
    }

    final activeD = (dVal != null && dVal >= 1 && dVal <= 3) ? dVal : _lastD;
    if (dVal != null && dVal >= 1 && dVal <= 3) {
      _lastD = dVal;
    }

    if (activeD == 1) { // Draw Trace or Arc
      double traceWidth = _apertures[_apt]?.sizeX ?? 0.2;
      if (traceWidth <= 0) traceWidth = 0.2;

      if (_interpolationMode == 2 || _interpolationMode == 3) {
        final I = _parseCoord(iStr, 0.0, _decX, _intX + _decX, _divX, isOffset: true);
        final J = _parseCoord(jStr, 0.0, _decY, _intY + _decY, _divY, isOffset: true);
        final cx = _x + I;
        final cy = _y + J;
        final radius = math.sqrt(I * I + J * J);
        final startAngle = math.atan2(_y - cy, _x - cx);
        final endAngle = math.atan2(ny - cy, nx - cx);
        final isClockwise = _interpolationMode == 2;

        double sweep = endAngle - startAngle;
        if (isClockwise) {
          if (sweep > 0) sweep -= 2 * math.pi;
        } else {
          if (sweep < 0) sweep += 2 * math.pi;
        }

        if (_inRegion) {
          _activeRegionPoints.add(Offset(nx, ny));
        } else {
          traces.add(PCBTrace(
            start: Offset(_x, _y),
            end: Offset(nx, ny),
            width: traceWidth,
            isArc: true,
            center: Offset(cx, cy),
            radius: radius,
            startAngle: startAngle,
            sweepAngle: sweep,
            dark: _dark,
          ));
        }
      } else {
        if (_inRegion) {
          if (_activeRegionPoints.isEmpty) {
            _activeRegionPoints.add(Offset(_x, _y));
          }
          _activeRegionPoints.add(Offset(nx, ny));
        } else {
          traces.add(PCBTrace(
            start: Offset(_x, _y),
            end: Offset(nx, ny),
            width: traceWidth,
            dark: _dark,
          ));
        }
      }
    } else if (activeD == 2) { // Move
      if (_inRegion) {
        if (_activeRegionPoints.isNotEmpty) {
          regions.add(PCBRegion(
            points: List.from(_activeRegionPoints),
            dark: _dark,
          ));
          _activeRegionPoints.clear();
        }
        _activeRegionPoints.add(Offset(nx, ny));
      }
    } else if (activeD == 3) { // Flash Pad
      final ap = _apertures[_apt];
      double w = ap?.sizeX ?? 0.8;
      double h = ap?.sizeY ?? w;
      if (w <= 0) w = 0.8;
      if (h <= 0) h = w;

      pads.add(PCBPad(
        center: Offset(nx, ny),
        width: w,
        height: h,
        isCircle: ap == null || ap.shape.startsWith('C') || ap.shape.startsWith('O'),
        dark: _dark,
      ));
    }

    _x = nx;
    _y = ny;
  }

  double _parseCoord(
      String? s, double prev, int decDigits, int totalDigits, double divisor,
      {bool isOffset = false}) {
    if (s == null) return isOffset ? 0.0 : prev;
    if (s.contains('.')) {
      double val = double.tryParse(s) ?? (isOffset ? 0.0 : prev);
      if (_imperial) val *= 25.4;
      return val;
    }

    final isNegative = s.startsWith('-');
    var digitsStr = s.replaceAll(RegExp(r'[+-]'), '');

    if (digitsStr.isEmpty) return isOffset ? 0.0 : prev;

    if (_isTrailingZeroSuppression) {
      // Trailing zeros suppressed: pad trailing zeros until totalDigits
      while (digitsStr.length < totalDigits) {
        digitsStr += '0';
      }
    } else {
      // Leading zeros suppressed: pad leading zeros until totalDigits
      while (digitsStr.length < totalDigits) {
        digitsStr = '0' + digitsStr;
      }
    }

    final raw = int.tryParse(digitsStr) ?? 0;
    double val = (isNegative ? -raw : raw) / divisor;
    if (_imperial) val *= 25.4;
    return val;
  }

  int get apertureCount => _apertures.length;
}

class LayerDetector {
  static String? detect(String filename, String content) {
    filename = filename.toLowerCase();

    final fileFuncMatch =
        RegExp(r'%TF\.FileFunction,([^*]*)%\*?').firstMatch(content);
    if (fileFuncMatch != null) {
      final func = fileFuncMatch.group(1)!.toLowerCase();
      if (func.contains('copper,l1,top') || func.contains('copper,l1,t')) {
        return 'top_copper';
      }
      if (func.contains('copper,') &&
          (func.contains(',bot') || func.contains(',b'))) {
        return 'bottom_copper';
      }
      if (func.contains('soldermask,top') ||
          func.contains('soldermask,l1,top')) {
        return 'top_soldermask';
      }
      if (func.contains('soldermask,bot') ||
          func.contains('soldermask,l2,bot')) {
        return 'bottom_soldermask';
      }
      if (func.contains('legend,top') || func.contains('legend,l1,top')) {
        return 'top_silkscreen';
      }
      if (func.contains('legend,bot') || func.contains('legend,l2,bot')) {
        return 'bottom_silkscreen';
      }
      if (func.contains('paste,top') || func.contains('paste,l1,top')) {
        return 'top_paste';
      }
      if (func.contains('paste,bot') || func.contains('paste,l2,bot')) {
        return 'bottom_paste';
      }
      if (func.contains('profile') ||
          func.contains('boardoutline') ||
          func.contains('outline')) return 'outline';
    }

    if (content.contains('M48') ||
        filename.contains('npth') ||
        filename.contains('pth') ||
        filename.endsWith('.drl') ||
        filename.endsWith('.xln') ||
        filename.endsWith('.drd') ||
        filename.endsWith('.txt') ||
        filename.endsWith('.exc')) {
      return 'drill';
    }

    if (filename.endsWith('.gtl') ||
        filename.endsWith('.top') ||
        filename.endsWith('.cmp') ||
        filename.endsWith('.art01') ||
        filename.endsWith('.g1') ||
        filename.endsWith('.l1') ||
        filename.contains('f.cu') ||
        filename.contains('f_cu') ||
        filename.contains('f-cu') ||
        filename.contains('topcopper') ||
        filename.contains('top_copper') ||
        filename.contains('top.copper') ||
        filename.contains('top_cu') ||
        filename.contains('top.cu') ||
        filename.contains('top_layer') ||
        filename.contains('top.layer') ||
        filename.contains('layer_1') ||
        filename.contains('layer1') ||
        filename.contains('signal1') ||
        (filename.contains('top') && !filename.contains('silk') && !filename.contains('mask') && !filename.contains('paste'))) {
      return 'top_copper';
    }

    if (filename.endsWith('.gbl') ||
        filename.endsWith('.bot') ||
        filename.endsWith('.sol') ||
        filename.endsWith('.art02') ||
        filename.endsWith('.g2') ||
        filename.endsWith('.l2') ||
        filename.contains('b.cu') ||
        filename.contains('b_cu') ||
        filename.contains('b-cu') ||
        filename.contains('botcopper') ||
        filename.contains('bottom_copper') ||
        filename.contains('bottom.copper') ||
        filename.contains('bot_copper') ||
        filename.contains('bottom_cu') ||
        filename.contains('bottom.cu') ||
        filename.contains('bottom_layer') ||
        filename.contains('bottom.layer') ||
        filename.contains('layer_2') ||
        filename.contains('layer2') ||
        filename.contains('signal2') ||
        (filename.contains('bot') && !filename.contains('silk') && !filename.contains('mask') && !filename.contains('paste'))) {
      return 'bottom_copper';
    }

    if (filename.contains('in1.cu') ||
        filename.contains('in2.cu') ||
        filename.contains('in3.cu') ||
        filename.contains('in4.cu') ||
        filename.contains('inner') ||
        filename.endsWith('.g1') ||
        filename.endsWith('.g2') ||
        filename.endsWith('.g3') ||
        filename.endsWith('.g4') ||
        filename.endsWith('.gl1') ||
        filename.endsWith('.gl2') ||
        filename.endsWith('.gp1') ||
        filename.endsWith('.gp2')) {
      return 'inner_copper';
    }

    if (filename.endsWith('.gts') ||
        filename.endsWith('.smc') ||
        filename.endsWith('.smt') ||
        filename.endsWith('.stc') ||
        filename.contains('f.mask') ||
        filename.contains('f_mask') ||
        filename.contains('f-mask') ||
        filename.contains('topmask') ||
        filename.contains('top_mask') ||
        filename.contains('top.mask') ||
        filename.contains('mask_top') ||
        filename.contains('mask.top') ||
        filename.contains('stopmask_top') ||
        filename.contains('soldermask_top') ||
        filename.contains('soldermasktop')) {
      return 'top_soldermask';
    }

    if (filename.endsWith('.gbs') ||
        filename.endsWith('.sms') ||
        filename.endsWith('.smb') ||
        filename.endsWith('.sts') ||
        filename.contains('b.mask') ||
        filename.contains('b_mask') ||
        filename.contains('b-mask') ||
        filename.contains('botmask') ||
        filename.contains('bottom_mask') ||
        filename.contains('bottom.mask') ||
        filename.contains('mask_bot') ||
        filename.contains('mask.bot') ||
        filename.contains('stopmask_bot') ||
        filename.contains('soldermask_bot') ||
        filename.contains('soldermaskbot')) {
      return 'bottom_soldermask';
    }

    if (filename.endsWith('.gto') ||
        filename.endsWith('.sst') ||
        filename.endsWith('.plc') ||
        filename.endsWith('.silk_top') ||
        filename.endsWith('.silktop') ||
        filename.contains('f.silkscreen') ||
        filename.contains('f_silkscreen') ||
        filename.contains('f-silkscreen') ||
        filename.contains('f.silk') ||
        filename.contains('f_silk') ||
        filename.contains('f-silk') ||
        filename.contains('topsilk') ||
        filename.contains('top_silk') ||
        filename.contains('top.silk') ||
        filename.contains('silk_top') ||
        filename.contains('silk.top') ||
        filename.contains('legend_top') ||
        filename.contains('legend.top') ||
        filename.contains('silkscreen_top') ||
        filename.contains('silkscreentop') ||
        filename.contains('overlay_top') ||
        filename.contains('topoverlay')) {
      return 'top_silkscreen';
    }

    if (filename.endsWith('.gbo') ||
        filename.endsWith('.ssb') ||
        filename.endsWith('.pls') ||
        filename.endsWith('.silk_bot') ||
        filename.endsWith('.silkbot') ||
        filename.contains('b.silkscreen') ||
        filename.contains('b_silkscreen') ||
        filename.contains('b-silkscreen') ||
        filename.contains('b.silk') ||
        filename.contains('b_silk') ||
        filename.contains('b-silk') ||
        filename.contains('botsilk') ||
        filename.contains('bottom_silk') ||
        filename.contains('bottom.silk') ||
        filename.contains('silk_bot') ||
        filename.contains('silk.bot') ||
        filename.contains('legend_bot') ||
        filename.contains('legend.bot') ||
        filename.contains('silkscreen_bot') ||
        filename.contains('silkscreenbot') ||
        filename.contains('overlay_bot') ||
        filename.contains('bottomoverlay')) {
      return 'bottom_silkscreen';
    }

    if (filename.endsWith('.gtp') ||
        filename.endsWith('.spt') ||
        filename.endsWith('.crc') ||
        filename.contains('f.paste') ||
        filename.contains('f_paste') ||
        filename.contains('f-paste') ||
        filename.contains('toppaste') ||
        filename.contains('top_paste') ||
        filename.contains('paste_top')) {
      return 'top_paste';
    }

    if (filename.endsWith('.gbp') ||
        filename.endsWith('.spb') ||
        filename.endsWith('.crs') ||
        filename.contains('b.paste') ||
        filename.contains('b_paste') ||
        filename.contains('b-paste') ||
        filename.contains('botpaste') ||
        filename.contains('bottom_paste') ||
        filename.contains('paste_bot')) {
      return 'bottom_paste';
    }

    if (filename.endsWith('.gko') ||
        filename.endsWith('.gm1') ||
        filename.endsWith('.gm2') ||
        filename.endsWith('.gm3') ||
        filename.endsWith('.gm') ||
        filename.endsWith('.gml') ||
        filename.endsWith('.out') ||
        filename.endsWith('.mil') ||
        filename.endsWith('.fab') ||
        filename.contains('edge.cuts') ||
        filename.contains('edge_cuts') ||
        filename.contains('edge-cuts') ||
        filename.contains('edgecuts') ||
        filename.contains('profile') ||
        filename.contains('outline') ||
        filename.contains('border') ||
        filename.contains('mechanical') ||
        filename.contains('boardoutline') ||
        filename.contains('contour')) {
      return 'outline';
    }

    // Content-assisted fallbacks if extension/filename was ambiguous
    if (content.contains('ADD') || content.contains('FSLA') || content.contains('%MO')) {
      final lc = content.toLowerCase();
      if (lc.contains('silk') || lc.contains('legend') || filename.contains('silk') || filename.contains('legend')) {
        return filename.contains('bot') || filename.contains('b.') || filename.contains('b_') ? 'bottom_silkscreen' : 'top_silkscreen';
      }
      if (lc.contains('mask') || filename.contains('mask')) {
        return filename.contains('bot') || filename.contains('b.') || filename.contains('b_') ? 'bottom_soldermask' : 'top_soldermask';
      }
      if (lc.contains('copper') || lc.contains('layer') || filename.contains('cu') || filename.contains('art')) {
        return filename.contains('bot') || filename.contains('b.') || filename.contains('b_') ? 'bottom_copper' : 'top_copper';
      }
      // If still ambiguous but valid Gerber, default to top_copper
      return 'top_copper';
    }

    return null;
  }
}

class GerberParser {
  static String? _tryDecode(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }

  static GerberParseResult parseZipBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    int topLayers = 0, bottomLayers = 0, innerLayers = 0;

    String? topCopperContent;
    String? bottomCopperContent;
    String? topMaskContent;
    String? bottomMaskContent;
    String? topSilkContent;
    String? bottomSilkContent;
    String? topPasteContent;
    String? bottomPasteContent;
    String? outlineContent;
    String? drillContent;

    final debugLogs = <GerberFileDebugInfo>[];
    final allGerberContents = <String>[];

    debugPrint('''
==================================================
STARTING GERBER ZIP PACKAGE PARSING
TOTAL ZIP ENTRIES: ${archive.length}
==================================================''');

    for (final file in archive) {
      if (!file.isFile) continue;
      final raw = file.content as List<int>;
      final name = file.name;
      final decoded = _tryDecode(raw);
      if (decoded == null) continue;

      final type = LayerDetector.detect(name, decoded);
      if (type == null) continue;

      if (type == 'top_copper') {
        topLayers++;
        topCopperContent = (topCopperContent ?? '') + '\n' + decoded;
      } else if (type == 'bottom_copper') {
        bottomLayers++;
        bottomCopperContent = (bottomCopperContent ?? '') + '\n' + decoded;
      } else if (type == 'top_soldermask') {
        topMaskContent = (topMaskContent ?? '') + '\n' + decoded;
      } else if (type == 'bottom_soldermask') {
        bottomMaskContent = (bottomMaskContent ?? '') + '\n' + decoded;
      } else if (type == 'top_silkscreen') {
        topSilkContent = (topSilkContent ?? '') + '\n' + decoded;
      } else if (type == 'bottom_silkscreen') {
        bottomSilkContent = (bottomSilkContent ?? '') + '\n' + decoded;
      } else if (type == 'top_paste') {
        topPasteContent = (topPasteContent ?? '') + '\n' + decoded;
      } else if (type == 'bottom_paste') {
        bottomPasteContent = (bottomPasteContent ?? '') + '\n' + decoded;
      } else if (type == 'outline') {
        outlineContent = (outlineContent ?? '') + '\n' + decoded;
      } else if (type == 'drill') {
        drillContent = (drillContent ?? '') + '\n' + decoded;
      }

      if (type != 'drill') {
        final parser = _GerberLayerParser(decoded);
        parser.parse();
        final geometryCount =
            parser.traces.length + parser.pads.length + parser.regions.length;

        final info = GerberFileDebugInfo(
          fileName: name,
          layerType: type,
          fileSize: raw.length,
          parsedCommandCount: parser.parsedCommandCount,
          parsedGeometryCount: geometryCount,
          apertureCount: parser.apertureCount,
          coordinateCount: parser.coordinateCount,
        );
        info.log();
        debugLogs.add(info);
        allGerberContents.add(decoded);
      } else {
        final drills = _parseDrillList(decoded);
        final info = GerberFileDebugInfo(
          fileName: name,
          layerType: type,
          fileSize: raw.length,
          parsedCommandCount: decoded.split('\n').length,
          parsedGeometryCount: drills.length,
          apertureCount: 0,
          coordinateCount: drills.length,
        );
        info.log();
        debugLogs.add(info);
      }
    }

    final parsedTopCopper = _parseLayer(topCopperContent);
    final parsedBottomCopper = _parseLayer(bottomCopperContent);
    final parsedTopMask = _parseLayer(topMaskContent);
    final parsedBottomMask = _parseLayer(bottomMaskContent);
    final parsedTopSilk = _parseLayer(topSilkContent);
    final parsedBottomSilk = _parseLayer(bottomSilkContent);
    final parsedTopPaste = _parseLayer(topPasteContent);
    final parsedBottomPaste = _parseLayer(bottomPasteContent);
    final parsedOutline = _parseLayer(outlineContent);
    final parsedDrills = _parseDrillList(drillContent);

    Rect overallBbox = const Rect.fromLTWH(0, 0, 100, 80);
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    void includeBBox(Rect rect) {
      if (rect.width > 0 &&
          rect.height > 0 &&
          rect != const Rect.fromLTWH(0, 0, 100, 80)) {
        if (rect.left < minX) minX = rect.left;
        if (rect.right > maxX) maxX = rect.right;
        if (rect.top < minY) minY = rect.top;
        if (rect.bottom > maxY) maxY = rect.bottom;
      }
    }

    if (parsedOutline != null && parsedOutline.hasData) {
      includeBBox(parsedOutline.bbox);
    }
    if (parsedTopCopper != null && parsedTopCopper.hasData) {
      includeBBox(parsedTopCopper.bbox);
    }
    if (parsedBottomCopper != null && parsedBottomCopper.hasData) {
      includeBBox(parsedBottomCopper.bbox);
    }
    if (parsedTopSilk != null && parsedTopSilk.hasData) {
      includeBBox(parsedTopSilk.bbox);
    }

    for (final drill in parsedDrills) {
      final r = drill.diameter / 2;
      if (drill.center.dx - r < minX) minX = drill.center.dx - r;
      if (drill.center.dx + r > maxX) maxX = drill.center.dx + r;
      if (drill.center.dy - r < minY) minY = drill.center.dy - r;
      if (drill.center.dy + r > maxY) maxY = drill.center.dy + r;
    }

    String dims = 'Unknown';
    if (!minX.isInfinite && minX < maxX && minY < maxY) {
      final padding = math.max((maxX - minX) * 0.05, 2.0);
      overallBbox = Rect.fromLTRB(
          minX - padding, minY - padding, maxX + padding, maxY + padding);
      dims =
          '${(maxX - minX).toStringAsFixed(3)} mm x ${(maxY - minY).toStringAsFixed(3)} mm';
    } else {
      overallBbox = const Rect.fromLTWH(0, 0, 100, 80);
      dims = '100 mm x 80 mm';
    }

    final layerCount =
        _computeLayerCount(topLayers, bottomLayers, innerLayers, archive.length);

    final combinedTop = PCBLayerData(
      traces: parsedTopCopper?.traces ?? [],
      pads: parsedTopCopper?.pads ?? [],
      drills: parsedDrills,
      outline: parsedOutline?.traces ?? [],
      silkscreen: parsedTopSilk?.traces ?? [],
      soldermaskTraces: parsedTopMask?.traces ?? [],
      soldermaskPads: parsedTopMask?.pads ?? [],
      regions: parsedTopCopper?.regions ?? [],
      bbox: overallBbox,
    );

    final combinedBottom = PCBLayerData(
      traces: parsedBottomCopper?.traces ?? [],
      pads: parsedBottomCopper?.pads ?? [],
      drills: parsedDrills,
      outline: parsedOutline?.traces ?? [],
      silkscreen: parsedBottomSilk?.traces ?? [],
      soldermaskTraces: parsedBottomMask?.traces ?? [],
      soldermaskPads: parsedBottomMask?.pads ?? [],
      regions: parsedBottomCopper?.regions ?? [],
      bbox: overallBbox,
    );

    return GerberParseResult(
      dimensions: dims,
      layerCount: layerCount,
      copperWeight: layerCount >= 4 ? '2 oz' : '1 oz',
      minTraceSpace: layerCount >= 4 ? '4/4 mil' : '8/8 mil',
      minHoleSize: _parseMinHole(drillContent),
      material: 'FR-4',
      solderMask: 'Green',
      unitPrice: _calcPrice(_areaFromDims(dims), layerCount),
      totalPrice: _calcPrice(_areaFromDims(dims), layerCount) * 10,
      pcbThickness: '1.6 mm',
      copperThickness: layerCount >= 4 ? '2 oz / 70 µm' : '1 oz / 35 µm',
      pcbFinish: 'HASL (with lead)',
      boardType: 'Single Piece',
      discreteDesign: '1 Design',
      minLineWidth: _detectMinLineWidth(allGerberContents),
      uploadId:
          'upload_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(99999)}',
      topCopper: parsedTopCopper,
      bottomCopper: parsedBottomCopper,
      topSolderMask: parsedTopMask,
      bottomSolderMask: parsedBottomMask,
      topSilkscreen: parsedTopSilk,
      bottomSilkscreen: parsedBottomSilk,
      topPaste: parsedTopPaste,
      bottomPaste: parsedBottomPaste,
      boardOutline: parsedOutline,
      drills: parsedDrills,
      topLayer: combinedTop,
      bottomLayer: combinedBottom,
      debugLogs: debugLogs,
    );
  }

  static PCBLayerData? _parseLayer(String? content) {
    if (content == null) return null;
    final parser = _GerberLayerParser(content);
    parser.parse();
    final bbox = PCBLayerData.computeBBox(
      parser.traces,
      parser.pads,
      const [],
      const [],
      parser.regions,
    );
    return PCBLayerData(
      traces: parser.traces,
      pads: parser.pads,
      drills: const [],
      outline: const [],
      silkscreen: const [],
      soldermaskTraces: const [],
      soldermaskPads: const [],
      regions: parser.regions,
      bbox: bbox,
    );
  }

  static List<PCBDrill> _parseDrillList(String? content) {
    if (content == null) return [];
    final drills = <PCBDrill>[];
    final toolDefs = <int, double>{};

    bool isMetric = true;
    int decimalPlaces = 3;

    final lines = content.split(RegExp(r'\r?\n'));
    bool headerMode = true;
    int currentTool = -1;
    double currentX = 0.0;
    double currentY = 0.0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith(';')) continue;

      if (line == '%') {
        headerMode = false;
        continue;
      }

      if (headerMode) {
        final upper = line.toUpperCase();
        if (upper.contains('METRIC') || upper.contains('M71') || upper.contains('G71')) {
          isMetric = true;
          decimalPlaces = 3;
        } else if (upper.contains('INCH') || upper.contains('M72') || upper.contains('G72')) {
          isMetric = false;
          decimalPlaces = 4;
        }

        final tMatch = RegExp(r'T(\d+)(?:F\d+S\d+)?C([\d.]+)').firstMatch(line);
        if (tMatch != null) {
          final tId = int.parse(tMatch.group(1)!);
          double diameter = double.parse(tMatch.group(2)!);
          if (!isMetric) diameter *= 25.4;
          toolDefs[tId] = diameter;
        }

        if (line == 'M48') headerMode = true;
        if (line == 'M95') headerMode = false;
      } else {
        final upper = line.toUpperCase();
        if (upper.startsWith('T') && !upper.contains('C')) {
          final tIdStr = upper.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
          currentTool = int.tryParse(tIdStr) ?? currentTool;
          continue;
        }

        if (upper.startsWith('M30') || upper.startsWith('M00')) break;

        final xyMatch = RegExp(r'(X[+-]?[\d.]+)?(Y[+-]?[\d.]+)?').firstMatch(upper);
        if (xyMatch != null && (xyMatch.group(1) != null || xyMatch.group(2) != null)) {
          final xStr = xyMatch.group(1)?.substring(1);
          final yStr = xyMatch.group(2)?.substring(1);

          double parseValue(String s) {
            if (s.contains('.')) {
              double v = double.tryParse(s) ?? 0.0;
              return isMetric ? v : v * 25.4;
            }
            final val = double.tryParse(s) ?? 0.0;
            double divisor = math.pow(10, decimalPlaces).toDouble();
            if (val.abs() > 100000) divisor = 10000.0;
            else if (val.abs() > 10000) divisor = 1000.0;
            double v = val / divisor;
            return isMetric ? v : v * 25.4;
          }

          if (xStr != null) currentX = parseValue(xStr);
          if (yStr != null) currentY = parseValue(yStr);

          if (currentTool != -1 && (xStr != null || yStr != null)) {
            drills.add(PCBDrill(
              center: Offset(currentX, currentY),
              diameter: toolDefs[currentTool] ?? 0.5,
            ));
          }
        }
      }
    }

    return drills;
  }

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

  static String _parseMinHole(String? content) {
    if (content == null) return '0.50 mm';
    final toolPattern = RegExp(r'T\d+C([\d.]+)');
    final matches = toolPattern.allMatches(content);
    double minDia = double.infinity;
    for (final m in matches) {
      final dia = double.tryParse(m.group(1) ?? '');
      if (dia != null && dia > 0 && dia < minDia) minDia = dia;
    }
    if (minDia.isInfinite) return '0.50 mm';
    if (minDia < 0.1) minDia *= 25.4;
    return '${minDia.toStringAsFixed(3)} mm';
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
    if (minWidth.isInfinite || minWidth > 10) return '0.2032 mm';
    if (minWidth < 0.05) minWidth *= 25.4;
    return '${minWidth.toStringAsFixed(3)} mm';
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
    final raw = (cm2 * 1.8 * layers).round();
    return math.max(raw, 75);
  }
}
