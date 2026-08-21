import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'gerber_parser.dart';

class DfmViolation {
  final String ruleName; // e.g., "MINIMUM CLEARANCE VIOLATION"
  final String description;
  final Offset position; // Coordinate in Gerber coordinates
  final double actualValue;
  final double requiredValue;
  final String unit; // 'mm' or 'mil'
  final String layerName;

  const DfmViolation({
    required this.ruleName,
    required this.description,
    required this.position,
    required this.actualValue,
    required this.requiredValue,
    required this.unit,
    required this.layerName,
  });
}

class DfmRules {
  final double boardThickness; // mm
  final double copperThicknessOz; // oz
  final double minDrillSize; // mm
  final double minTrackWidth; // mm
  final double minClearance; // mm
  final double minAnnularRing; // mm
  final double minCopperToEdge; // mm

  const DfmRules({
    this.boardThickness = 1.6,
    this.copperThicknessOz = 1.0,
    this.minDrillSize = 0.5,
    this.minTrackWidth = 0.2032, // 8 mil
    this.minClearance = 0.2032,  // 8 mil
    this.minAnnularRing = 0.15,
    this.minCopperToEdge = 0.3,
  });
}

class DfmReport {
  final bool passed;
  final List<DfmViolation> violations;
  final Map<String, String> statusMap; // {'Board Outline': 'PASS', ...}

  const DfmReport({
    required this.passed,
    required this.violations,
    required this.statusMap,
  });
}

class CopperFeature {
  final bool isPad;
  final Offset start; // Pad center or Trace start
  final Offset end;   // Pad center or Trace end
  final double width;
  final double height;
  final bool isCircle;
  final String layerName;

  CopperFeature({
    required this.isPad,
    required this.start,
    required this.end,
    required this.width,
    required this.height,
    required this.isCircle,
    required this.layerName,
  });

  Rect get bbox {
    if (isPad) {
      return Rect.fromCenter(center: start, width: width, height: height);
    } else {
      final left = math.min(start.dx, end.dx) - width / 2;
      final right = math.max(start.dx, end.dx) + width / 2;
      final top = math.min(start.dy, end.dy) - width / 2;
      final bottom = math.max(start.dy, end.dy) + width / 2;
      return Rect.fromLTRB(left, top, right, bottom);
    }
  }
}

class GerberDrcValidator {
  
  static DfmReport runDfm(GerberParseResult result, DfmRules rules) {
    final violations = <DfmViolation>[];
    final statusMap = <String, String>{
      'Board Outline': 'PASS',
      'Drill Size': 'PASS',
      'Track Width': 'PASS',
      'Clearance': 'PASS',
      'Copper-to-Edge': 'PASS',
      'Annular Ring': 'PASS',
    };

    // 1. Board Outline Check
    final hasOutline = result.boardOutline != null && result.boardOutline!.traces.isNotEmpty;
    if (!hasOutline) {
      statusMap['Board Outline'] = 'WARNING';
      violations.add(const DfmViolation(
        ruleName: 'BOARD OUTLINE MISSING',
        description: 'No explicit board outline layer detected. Bounding box coordinates used as fallback.',
        position: Offset(0, 0),
        actualValue: 0.0,
        requiredValue: 1.0,
        unit: 'layer',
        layerName: 'Board Outline',
      ));
    }

    // 2. Drill Size Check
    if (result.drills.isNotEmpty) {
      for (final drill in result.drills) {
        if (drill.diameter < rules.minDrillSize) {
          statusMap['Drill Size'] = 'REJECTED';
          violations.add(DfmViolation(
            ruleName: 'MINIMUM DRILL VIOLATION',
            description: 'Drill hole diameter is ${drill.diameter.toStringAsFixed(3)} mm (requires ≥ ${rules.minDrillSize.toStringAsFixed(2)} mm).',
            position: drill.center,
            actualValue: drill.diameter,
            requiredValue: rules.minDrillSize,
            unit: 'mm',
            layerName: 'Drill',
          ));
        }
      }
    }

    // 3. Track Width Check
    void checkLayerTrackWidth(PCBLayerData? layer, String layerName) {
      if (layer == null) return;
      for (final trace in layer.traces) {
        if (!trace.isArc && trace.width < rules.minTrackWidth) {
          statusMap['Track Width'] = 'REJECTED';
          violations.add(DfmViolation(
            ruleName: 'MINIMUM TRACK WIDTH VIOLATION',
            description: 'Copper trace width is ${trace.width.toStringAsFixed(4)} mm (requires ≥ ${rules.minTrackWidth.toStringAsFixed(4)} mm).',
            position: Offset((trace.start.dx + trace.end.dx) / 2, (trace.start.dy + trace.end.dy) / 2),
            actualValue: trace.width,
            requiredValue: rules.minTrackWidth,
            unit: 'mm',
            layerName: layerName,
          ));
        }
      }
    }
    checkLayerTrackWidth(result.topCopper, 'Top Copper');
    checkLayerTrackWidth(result.bottomCopper, 'Bottom Copper');

    // 4. Clearance Check (Copper-to-Copper)
    List<CopperFeature> extractFeatures(PCBLayerData? layer, String layerName) {
      if (layer == null) return [];
      final list = <CopperFeature>[];
      for (final t in layer.traces) {
        list.add(CopperFeature(
          isPad: false,
          start: t.start,
          end: t.end,
          width: t.width,
          height: t.width,
          isCircle: true,
          layerName: layerName,
        ));
      }
      for (final p in layer.pads) {
        list.add(CopperFeature(
          isPad: true,
          start: p.center,
          end: p.center,
          width: p.width,
          height: p.height,
          isCircle: p.isCircle,
          layerName: layerName,
        ));
      }
      return list;
    }

    void runClearanceForLayer(PCBLayerData? layer, String layerName) {
      if (layer == null) return;
      final features = extractFeatures(layer, layerName);
      final layerViolations = _checkClearance(features, rules.minClearance);
      if (layerViolations.isNotEmpty) {
        statusMap['Clearance'] = 'REJECTED';
        violations.addAll(layerViolations);
      }
    }
    runClearanceForLayer(result.topCopper, 'Top Copper');
    runClearanceForLayer(result.bottomCopper, 'Bottom Copper');

    // 5. Copper-to-Edge Check
    void checkCopperToEdge(PCBLayerData? layer, String layerName, List<PCBTrace> outlineSegs, Rect bbox) {
      if (layer == null) return;
      final features = extractFeatures(layer, layerName);
      
      for (final f in features) {
        double minDist = double.infinity;
        Offset nearestPt = Offset.zero;
        
        if (outlineSegs.isNotEmpty) {
          for (final seg in outlineSegs) {
            double d;
            if (f.isPad) {
              d = _pointToSegmentDistance(f.start, seg.start, seg.end);
            } else {
              d = _segmentToSegmentDistance(f.start, f.end, seg.start, seg.end);
            }
            if (d < minDist) {
              minDist = d;
              nearestPt = f.isPad ? f.start : seg.start;
            }
          }
        } else {
          // Fall back to distance to bbox boundary
          final fCenter = f.isPad ? f.start : Offset((f.start.dx + f.end.dx) / 2, (f.start.dy + f.end.dy) / 2);
          final dLeft = (fCenter.dx - bbox.left).abs();
          final dRight = (bbox.right - fCenter.dx).abs();
          final dTop = (fCenter.dy - bbox.top).abs();
          final dBottom = (bbox.bottom - fCenter.dy).abs();
          minDist = math.min(math.min(dLeft, dRight), math.min(dTop, dBottom));
          nearestPt = fCenter;
        }

        final actualMargin = minDist - (f.width / 2);
        if (actualMargin >= 0 && actualMargin < rules.minCopperToEdge) {
          statusMap['Copper-to-Edge'] = 'REJECTED';
          violations.add(DfmViolation(
            ruleName: 'COPPER-TO-EDGE VIOLATION',
            description: 'Distance from copper feature to board outline is ${actualMargin.toStringAsFixed(3)} mm (requires ≥ ${rules.minCopperToEdge.toStringAsFixed(2)} mm).',
            position: nearestPt,
            actualValue: actualMargin,
            requiredValue: rules.minCopperToEdge,
            unit: 'mm',
            layerName: layerName,
          ));
        }
      }
    }
    
    final outlineSegs = result.boardOutline?.traces ?? [];
    final bbox = result.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);
    checkCopperToEdge(result.topCopper, 'Top Copper', outlineSegs, bbox);
    checkCopperToEdge(result.bottomCopper, 'Bottom Copper', outlineSegs, bbox);

    // 6. Annular Ring Check
    if (result.drills.isNotEmpty) {
      void runAnnularCheck(PCBLayerData? layer, String layerName) {
        if (layer == null) return;
        for (final drill in result.drills) {
          PCBPad? matchingPad;
          double minDist = 0.2; // maximum coordinates offset tolerance for matching drill to pad
          
          for (final pad in layer.pads) {
            final d = (pad.center - drill.center).distance;
            if (d < minDist) {
              minDist = d;
              matchingPad = pad;
            }
          }
          
          if (matchingPad != null) {
            final padSize = math.min(matchingPad.width, matchingPad.height);
            final annularRing = (padSize - drill.diameter) / 2;
            if (annularRing < rules.minAnnularRing) {
              statusMap['Annular Ring'] = 'REJECTED';
              violations.add(DfmViolation(
                ruleName: 'ANNULAR RING VIOLATION',
                description: 'Annular ring width is ${annularRing.toStringAsFixed(3)} mm (requires ≥ ${rules.minAnnularRing.toStringAsFixed(2)} mm). Pad: ${padSize.toStringAsFixed(2)}mm, Drill: ${drill.diameter.toStringAsFixed(2)}mm.',
                position: drill.center,
                actualValue: annularRing,
                requiredValue: rules.minAnnularRing,
                unit: 'mm',
                layerName: layerName,
              ));
            }
          }
        }
      }
      runAnnularCheck(result.topCopper, 'Top Copper');
      runAnnularCheck(result.bottomCopper, 'Bottom Copper');
    }

    final overallPassed = !statusMap.values.any((status) => status == 'REJECTED');

    return DfmReport(
      passed: overallPassed,
      violations: violations.take(150).toList(), // Cap violations at 150 to keep layout responsive
      statusMap: statusMap,
    );
  }

  // ─── Spatial Hash Grid Clearance Logic ─────────────────────────────────────
  
  static List<DfmViolation> _checkClearance(List<CopperFeature> features, double minClearance) {
    final violations = <DfmViolation>[];
    if (features.isEmpty) return violations;

    // We cap checked elements to prevent browser lag on massive boards
    final activeFeatures = features.length > 8000 ? features.take(8000).toList() : features;

    // cell size is larger than clearance to look in 9 boxes
    final double cellSize = math.max(minClearance * 2.5, 1.5);
    final grid = <String, List<CopperFeature>>{};

    String cellKey(int cx, int cy) => '${cx}_${cy}';

    for (final f in activeFeatures) {
      final box = f.bbox;
      final x1 = (box.left / cellSize).floor();
      final x2 = (box.right / cellSize).floor();
      final y1 = (box.top / cellSize).floor();
      final y2 = (box.bottom / cellSize).floor();

      for (int cx = x1; cx <= x2; cx++) {
        for (int cy = y1; cy <= y2; cy++) {
          grid.putIfAbsent(cellKey(cx, cy), () => []).add(f);
        }
      }
    }

    final checkedPairs = <String>{};

    for (final f1 in activeFeatures) {
      final box = f1.bbox;
      final x1 = (box.left / cellSize).floor();
      final x2 = (box.right / cellSize).floor();
      final y1 = (box.top / cellSize).floor();
      final y2 = (box.bottom / cellSize).floor();

      for (int cx = x1; cx <= x2; cx++) {
        for (int cy = y1; cy <= y2; cy++) {
          final cellFeatures = grid[cellKey(cx, cy)] ?? [];
          for (final f2 in cellFeatures) {
            if (identical(f1, f2)) continue;
            
            final id1 = identityHashCode(f1);
            final id2 = identityHashCode(f2);
            final pairKey = id1 < id2 ? '${id1}_${id2}' : '${id2}_${id1}';
            if (checkedPairs.contains(pairKey)) continue;
            checkedPairs.add(pairKey);

            double dist;
            if (f1.isPad && f2.isPad) {
              dist = (f1.start - f2.start).distance - (f1.width / 2 + f2.width / 2);
            } else if (f1.isPad && !f2.isPad) {
              dist = _pointToSegmentDistance(f1.start, f2.start, f2.end) - (f1.width / 2 + f2.width / 2);
            } else if (!f1.isPad && f2.isPad) {
              dist = _pointToSegmentDistance(f2.start, f1.start, f1.end) - (f1.width / 2 + f2.width / 2);
            } else {
              dist = _segmentToSegmentDistance(f1.start, f1.end, f2.start, f2.end) - (f1.width / 2 + f2.width / 2);
            }

            if (dist >= 0 && dist < minClearance) {
              final midpoint = f1.isPad 
                  ? f1.start 
                  : Offset((f1.start.dx + f1.end.dx)/2, (f1.start.dy + f1.end.dy)/2);
              
              violations.add(DfmViolation(
                ruleName: 'MINIMUM CLEARANCE VIOLATION',
                description: 'Clearance between features is ${dist.toStringAsFixed(4)} mm (requires ≥ ${minClearance.toStringAsFixed(4)} mm).',
                position: midpoint,
                actualValue: dist,
                requiredValue: minClearance,
                unit: 'mm',
                layerName: f1.layerName,
              ));
              
              if (violations.length >= 100) return violations; 
            }
          }
        }
      }
    }
    return violations;
  }

  // ─── Computational Geometry Helpers ────────────────────────────────────────

  static double _pointToSegmentDistance(Offset p, Offset sStart, Offset sEnd) {
    final double l2 = (sStart - sEnd).distanceSquared;
    if (l2 == 0) return (p - sStart).distance;
    final double t = ((p.dx - sStart.dx) * (sEnd.dx - sStart.dx) + (p.dy - sStart.dy) * (sEnd.dy - sStart.dy)) / l2;
    final double clampedT = t.clamp(0.0, 1.0);
    final Offset projection = Offset(
      sStart.dx + clampedT * (sEnd.dx - sStart.dx),
      sStart.dy + clampedT * (sEnd.dy - sStart.dy),
    );
    return (p - projection).distance;
  }

  static double _segmentToSegmentDistance(Offset p1, Offset q1, Offset p2, Offset q2) {
    if (_segmentsIntersect(p1, q1, p2, q2)) return 0.0;
    
    final d1 = _pointToSegmentDistance(p1, p2, q2);
    final d2 = _pointToSegmentDistance(q1, p2, q2);
    final d3 = _pointToSegmentDistance(p2, p1, q1);
    final d4 = _pointToSegmentDistance(q2, p1, q1);
    
    return math.min(math.min(d1, d2), math.min(d3, d4));
  }

  static bool _segmentsIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && _onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && _onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && _onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && _onSegment(p2, q1, q2)) return true;

    return false;
  }

  static int _orientation(Offset p, Offset q, Offset r) {
    final val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
    if (val.abs() < 1e-9) return 0;
    return val > 0 ? 1 : 2;
  }

  static bool _onSegment(Offset p, Offset q, Offset r) {
    return q.dx <= math.max(p.dx, r.dx) && q.dx >= math.min(p.dx, r.dx) &&
           q.dy <= math.max(p.dy, r.dy) && q.dy >= math.min(p.dy, r.dy);
  }

  // ─── Legacy validation (for backwards compatibility) ──────────────────────
  static DrcResult validate(GerberParseResult result) {
    final report = runDfm(result, const DfmRules());
    if (report.passed) {
      return DrcResult.success();
    }
    
    final failures = report.violations.map((v) => DrcFailure(
      featureName: v.ruleName,
      detectedValue: '${v.actualValue.toStringAsFixed(3)} mm',
      requiredValue: '≥ ${v.requiredValue.toStringAsFixed(3)} mm',
      reason: v.description,
    )).toList();
    
    return DrcResult.fail(failures);
  }
}

class DrcFailure {
  final String featureName;
  final String detectedValue;
  final String requiredValue;
  final String reason;

  const DrcFailure({
    required this.featureName,
    required this.detectedValue,
    required this.requiredValue,
    required this.reason,
  });
}

class DrcResult {
  final bool passed;
  final List<DrcFailure> failures;

  const DrcResult({required this.passed, required this.failures});

  factory DrcResult.success() => const DrcResult(passed: true, failures: []);
  factory DrcResult.fail(List<DrcFailure> failures) => DrcResult(passed: false, failures: failures);
}
