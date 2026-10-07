import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../utils/gerber_parser.dart';
import '../utils/gerber_renderer.dart';
import '../utils/gerber_drc_validator.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';

class QuoteResultSection extends StatefulWidget {
  final String fileName;
  final GerberParseResult parseResult;
  final VoidCallback onUploadNewFile;

  const QuoteResultSection({
    super.key,
    required this.fileName,
    required this.parseResult,
    required this.onUploadNewFile,
  });

  @override
  State<QuoteResultSection> createState() => _QuoteResultSectionState();
}

class _QuoteResultSectionState extends State<QuoteResultSection> {
  // Navigation & Viewport State
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  double _rotationAngle = 0.0; // In radians (0, pi/2, pi, 3pi/2)
  bool _is3DMode = false;
  bool _isFullscreen = false;

  // Sidebar scroll controller
  final ScrollController _sidebarScrollController = ScrollController();

  // Sliding Right Panel State (3 Sections)
  int _activeSectionIndex = 0; // 0: Specs & Metrics, 1: Instant Quote, 2: DFM & Layers
  bool _isPanelExpanded = true;

  // Render & Visibility State
  final Set<String> _visibleLayers = {
    'top_copper',
    'bottom_copper',
    'inner_copper',
    'top_soldermask',
    'bottom_soldermask',
    'top_silkscreen',
    'bottom_silkscreen',
    'top_paste',
    'bottom_paste',
    'outline',
    'drill'
  };
  String _selectedLayer = 'top_copper';
  Color _maskColorVal = const Color(0xFF1B4D3E); // Substrate Green
  String _maskColorName = 'Green';

  // 3D rotation state
  double _rotY = 28 * math.pi / 180;
  double _tiltX = 32 * math.pi / 180;

  // Grid & Snap State
  String _units = 'mm'; // 'mm', 'mil', 'inch'
  double _gridSpacing = 1.0; // in mm
  bool _showGrid = true;
  bool _snapToPad = true;
  bool _snapToTrack = true;
  bool _snapToDrill = true;
  bool _snapToOutline = true;

  // Measurement State
  bool _measurementMode = false;
  Offset? _measurementStart; // Gerber space
  Offset? _measurementEnd;   // Gerber space
  Offset _mouseHoverGerber = Offset.zero;

  // DFM Configurable Rules & Report State
  double _ruleBoardThickness = 1.6;
  double _ruleCopperThicknessOz = 1.0;
  double _ruleMinDrill = 0.50;
  double _ruleMinTrackWidth = 0.2; // 0.2 mm
  double _ruleMinClearance = 0.2;  // 0.2 mm
  double _ruleMinAnnularRing = 0.15;
  double _ruleMinCopperToEdge = 0.30;
  
  late DfmReport _dfmReport;
  DfmViolation? _selectedViolation;

  // Quotation Inputs
  late int _qty;
  late String _layers;
  late String _pcbThickness;
  late String _copperThickness;
  late String _pcbFinish;
  bool _isPlacingOrder = false;

  final List<int> _qtyOptions = [5, 10, 25, 50, 100, 200, 500, 1000];
  final List<String> _layerOptions = ['1', '2', '4', '6', '8'];
  final List<String> _thicknessOptions = ['0.6 mm', '0.8 mm', '1.0 mm', '1.2 mm', '1.6 mm', '2.0 mm'];
  final List<String> _copperOptions = ['1 oz / 35 µm', '2 oz / 70 µm', '3 oz / 105 µm'];
  final List<String> _finishOptions = ['HASL (with lead)', 'HASL (lead free)', 'ENIG', 'OSP'];
  final List<String> _maskOptions = ['Green', 'Red', 'Blue', 'Black', 'White', 'Yellow', 'Purple'];

  @override
  void initState() {
    super.initState();
    _qty = 10;
    _layers = widget.parseResult.layerCount.toString();
    _pcbThickness = widget.parseResult.pcbThickness;
    _copperThickness = widget.parseResult.copperThickness;
    _pcbFinish = widget.parseResult.pcbFinish;
    _maskColorName = widget.parseResult.solderMask;

    if (!_layerOptions.contains(_layers)) _layers = '2';
    if (!_copperOptions.contains(_copperThickness)) _copperThickness = _copperOptions.first;
    _updateMaskColor(_maskColorName);

    _runDfm();
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    super.dispose();
  }

  void _updateMaskColor(String colorName) {
    _maskColorName = colorName;
    switch (colorName.toLowerCase()) {
      case 'green':
        _maskColorVal = const Color(0xFF0F2F1D);
        break;
      case 'red':
        _maskColorVal = const Color(0xFF4A0A0A);
        break;
      case 'blue':
        _maskColorVal = const Color(0xFF0A2240);
        break;
      case 'black':
        _maskColorVal = const Color(0xFF111113);
        break;
      case 'white':
        _maskColorVal = const Color(0xFFE2E2E6);
        break;
      case 'yellow':
        _maskColorVal = const Color(0xFF4A3F0A);
        break;
      case 'purple':
        _maskColorVal = const Color(0xFF2F0A3F);
        break;
    }
  }

  void _runDfm() {
    final rules = DfmRules(
      boardThickness: _ruleBoardThickness,
      copperThicknessOz: _ruleCopperThicknessOz,
      minDrillSize: _ruleMinDrill,
      minTrackWidth: _ruleMinTrackWidth,
      minClearance: _ruleMinClearance,
      minAnnularRing: _ruleMinAnnularRing,
      minCopperToEdge: _ruleMinCopperToEdge,
    );
    setState(() {
      _dfmReport = GerberDrcValidator.runDfm(widget.parseResult, rules);
    });
  }

  // Centering & Zoom to Coordinates
  void _centerOnGerberCoordinate(Offset target, Size viewPortSize) {
    final bbox = widget.parseResult.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);
    if (bbox.width <= 0 || bbox.height <= 0) return;

    const margin = 24.0;
    final double baseScale = math.min(
      (viewPortSize.width - margin * 2) / bbox.width,
      (viewPortSize.height - margin * 2) / bbox.height,
    );

    final gerberCenter = bbox.center;

    final double dx = target.dx - gerberCenter.dx;
    final double dy = -(target.dy - gerberCenter.dy); // inverted Y axis

    setState(() {
      _pan = Offset(-dx * baseScale * _zoom, -dy * baseScale * _zoom);
    });
  }

  int get _currentUnitPrice {
    final layersInt = int.tryParse(_layers) ?? widget.parseResult.layerCount;
    final base = widget.parseResult.unitPrice;
    final multiplier = layersInt / math.max(widget.parseResult.layerCount, 1);
    return math.max((base * multiplier).round(), 80);
  }

  int get _currentTotalPrice => _currentUnitPrice * _qty;

  // Snapping logic
  Offset _findSnapPoint(Offset rawPt) {
    if (!_snapToPad && !_snapToTrack && !_snapToDrill && !_snapToOutline) {
      return rawPt;
    }
    
    double bestDist = 1.0; // snap distance threshold in mm
    Offset snapPt = rawPt;

    if (_snapToDrill) {
      for (final drill in widget.parseResult.drills) {
        final d = (rawPt - drill.center).distance;
        if (d < bestDist) {
          bestDist = d;
          snapPt = drill.center;
        }
      }
    }

    if (_snapToPad) {
      final copperLayers = [widget.parseResult.topCopper, widget.parseResult.bottomCopper];
      for (final cl in copperLayers) {
        if (cl == null) continue;
        for (final pad in cl.pads) {
          final d = (rawPt - pad.center).distance;
          if (d < bestDist) {
            bestDist = d;
            snapPt = pad.center;
          }
        }
      }
    }

    if (_snapToTrack) {
      final copperLayers = [widget.parseResult.topCopper, widget.parseResult.bottomCopper];
      for (final cl in copperLayers) {
        if (cl == null) continue;
        for (final t in cl.traces) {
          final dStart = (rawPt - t.start).distance;
          if (dStart < bestDist) {
            bestDist = dStart;
            snapPt = t.start;
          }
          final dEnd = (rawPt - t.end).distance;
          if (dEnd < bestDist) {
            bestDist = dEnd;
            snapPt = t.end;
          }
        }
      }
    }

    if (_snapToOutline && widget.parseResult.boardOutline != null) {
      for (final t in widget.parseResult.boardOutline!.traces) {
        final dStart = (rawPt - t.start).distance;
        if (dStart < bestDist) {
          bestDist = dStart;
          snapPt = t.start;
        }
        final dEnd = (rawPt - t.end).distance;
        if (dEnd < bestDist) {
          bestDist = dEnd;
          snapPt = t.end;
        }
      }
    }

    return snapPt;
  }

  // Units Display helper
  String _formatValue(double valueMm) {
    if (_units == 'mil') {
      return '${(valueMm * 39.3701).toStringAsFixed(1)} mil';
    } else if (_units == 'inch') {
      return '${(valueMm * 0.0393701).toStringAsFixed(4)} in';
    }
    return '${valueMm.toStringAsFixed(3)} mm';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1150;
            // Equalized square height for PCB Board Viewer & Features Sliding Box
            final double equalBoxHeight = isWide 
                ? (constraints.maxWidth - 436).clamp(580.0, 720.0) 
                : 500.0;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PCB Gerber Canvas Viewer (Square aspect matching height)
                  Expanded(
                    child: _buildViewerContainer(context, Size(equalBoxHeight, equalBoxHeight)),
                  ),
                  const SizedBox(width: 16),
                  // 2. 3 Sliding Sections Panel on RIGHT side (Exact SAME height)
                  _buildSlidingRightPanel(context, equalBoxHeight),
                ],
              );
            } else {
              return Column(
                children: [
                  // 1. PCB Board Canvas Viewer
                  _buildViewerContainer(context, Size(constraints.maxWidth, equalBoxHeight)),
                  const SizedBox(height: 18),
                  // 2. Mobile 3-Section Sliding Tab Bar
                  _buildMobileSectionTabs(),
                  const SizedBox(height: 14),
                  // 3. Active Section Content Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10121C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: _buildActiveSectionContent(context),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // Header Component
  Widget _buildHeader() {
    final overallPassed = _dfmReport.passed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: overallPassed 
                  ? const Color(0xFF00E676).withOpacity(0.1) 
                  : const Color(0xFFFF3D00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              overallPassed ? Icons.check_circle_outline : Icons.report_problem_outlined,
              color: overallPassed ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'PCB Inspection & Quotation Dashboard',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    _buildPill(
                      overallPassed ? 'PASS' : 'REJECTED',
                      overallPassed ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.fileName,
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onUploadNewFile,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Upload New', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.06),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // Right Side Sliding Panel Container (Holds the 3 Sections)
  Widget _buildSlidingRightPanel(BuildContext context, double viewerHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      width: _isPanelExpanded ? 420 : 68,
      height: viewerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF10121C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(-4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical Sliding Control Strip (68px)
            _buildSlidingNavStrip(),

            // Active Section Content Body (Visible when expanded)
            if (_isPanelExpanded) ...[
              Container(width: 1, color: Colors.white.withOpacity(0.06)),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_activeSectionIndex),
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildActiveSectionContent(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Sliding Control Strip with 3 Section Buttons + Slide Toggle
  Widget _buildSlidingNavStrip() {
    return Container(
      width: 67,
      color: const Color(0xFF0C0E17),
      child: Column(
        children: [
          const SizedBox(height: 14),
          // Slide Collapse / Expand Toggle Button
          Tooltip(
            message: _isPanelExpanded ? 'Slide Panel Closed' : 'Slide Open 3 Sections',
            child: InkWell(
              onTap: () {
                setState(() {
                  _isPanelExpanded = !_isPanelExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                ),
                child: Icon(
                  _isPanelExpanded ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  color: const Color(0xFF00E5FF),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, indent: 12, endIndent: 12),
          const SizedBox(height: 10),

          // Section 0: Specs
          _buildNavTabButton(
            index: 0,
            title: 'Specs',
            icon: Icons.developer_board_rounded,
            accentColor: const Color(0xFFFFD54F),
          ),
          const SizedBox(height: 12),

          // Section 1: Quote
          _buildNavTabButton(
            index: 1,
            title: 'Quote',
            icon: Icons.shopping_bag_outlined,
            accentColor: const Color(0xFF00E5FF),
            badgeText: '₹',
          ),
          const SizedBox(height: 12),

          // Section 2: DFM Analysis
          _buildNavTabButton(
            index: 2,
            title: 'DFM',
            icon: Icons.bug_report_outlined,
            accentColor: const Color(0xFFBB86FC),
            badgeColor: _dfmReport.passed ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
          ),
          const SizedBox(height: 12),

          // Section 3: Layer Manager
          _buildNavTabButton(
            index: 3,
            title: 'Layers',
            icon: Icons.layers_rounded,
            accentColor: const Color(0xFF00BCD4),
          ),
          const SizedBox(height: 12),

          // Section 4: Inspect & Measure
          _buildNavTabButton(
            index: 4,
            title: 'Inspect',
            icon: Icons.straighten_rounded,
            accentColor: const Color(0xFF00E676),
          ),

          const Spacer(),

          if (!_isPanelExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Tooltip(
                message: '3D Board View',
                child: IconButton(
                  icon: Icon(_is3DMode ? Icons.view_in_ar : Icons.grid_on_outlined, size: 18),
                  color: Colors.white54,
                  onPressed: () => setState(() => _is3DMode = !_is3DMode),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavTabButton({
    required int index,
    required String title,
    required IconData icon,
    required Color accentColor,
    String? badgeText,
    Color? badgeColor,
  }) {
    final bool isActive = _activeSectionIndex == index;
    return Tooltip(
      message: 'Section ${index + 1}: $title',
      child: InkWell(
        onTap: () {
          setState(() {
            if (_activeSectionIndex == index && _isPanelExpanded) {
              _isPanelExpanded = false;
            } else {
              _activeSectionIndex = index;
              _isPanelExpanded = true;
            }
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? accentColor.withOpacity(0.7) : Colors.white.withOpacity(0.05),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isActive ? accentColor : Colors.white54,
                    size: 20,
                  ),
                  if (badgeColor != null)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: badgeColor.withOpacity(0.6), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? accentColor : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Horizontal Tab Bar for Mobile/Narrow Views
  Widget _buildMobileSectionTabs() {
    final sections = [
      {'title': '1. Specs', 'icon': Icons.developer_board_rounded, 'color': const Color(0xFFFFD54F)},
      {'title': '2. Quote', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFF00E5FF)},
      {'title': '3. DFM', 'icon': Icons.bug_report_outlined, 'color': const Color(0xFFBB86FC)},
      {'title': '4. Layers', 'icon': Icons.layers_rounded, 'color': const Color(0xFF00BCD4)},
      {'title': '5. Inspect', 'icon': Icons.straighten_rounded, 'color': const Color(0xFF00E676)},
    ];

    return Row(
      children: List.generate(sections.length, (index) {
        final item = sections[index];
        final isActive = _activeSectionIndex == index;
        final color = item['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeSectionIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: index < sections.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.12) : const Color(0xFF10121C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? color : Colors.white.withOpacity(0.06),
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, size: 14, color: isActive ? color : Colors.white54),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? color : Colors.white54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Active Section Switcher Renderer
  Widget _buildActiveSectionContent(BuildContext context) {
    switch (_activeSectionIndex) {
      case 0:
        return _buildPcbSpecsSection();
      case 1:
        return _buildInstantQuoteSection(context);
      case 2:
        return _buildDfmSection();
      case 3:
        return _buildLayerManagerSection();
      case 4:
      default:
        return _buildInspectAndMeasureSection();
    }
  }

  // Section Title Header Helper
  Widget _buildSectionTitleHeader(String badge, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge,
              style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _specBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // SECTION 1: PCB SPECS & METRICS
  Widget _buildPcbSpecsSection() {
    final bbox = widget.parseResult.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);
    final boardW = bbox.width;
    final boardH = bbox.height;
    final boardArea = boardW * boardH;

    double calcPerimeter() {
      if (widget.parseResult.boardOutline != null && widget.parseResult.boardOutline!.traces.isNotEmpty) {
        double p = 0.0;
        for (final t in widget.parseResult.boardOutline!.traces) {
          p += (t.start - t.end).distance;
        }
        return p;
      }
      return 2 * (boardW + boardH);
    }

    double calcMinTrack() {
      double m = double.infinity;
      final layers = [widget.parseResult.topCopper, widget.parseResult.bottomCopper];
      for (final l in layers) {
        if (l == null) continue;
        for (final t in l.traces) {
          if (!t.isArc && t.width < m) m = t.width;
        }
      }
      return m.isInfinite ? 0.2 : m;
    }

    double calcMaxTrack() {
      double m = 0.0;
      final layers = [widget.parseResult.topCopper, widget.parseResult.bottomCopper];
      for (final l in layers) {
        if (l == null) continue;
        for (final t in l.traces) {
          if (!t.isArc && t.width > m) m = t.width;
        }
      }
      return m;
    }

    final double minDrill = widget.parseResult.drills.isNotEmpty
        ? widget.parseResult.drills.map((d) => d.diameter).reduce(math.min)
        : 0.50;
    final double maxDrill = widget.parseResult.drills.isNotEmpty
        ? widget.parseResult.drills.map((d) => d.diameter).reduce(math.max)
        : 1.00;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleHeader('SECTION 1 OF 5', 'PCB FEATURES & SPECS', Icons.developer_board_rounded, const Color(0xFFFFD54F)),
        const SizedBox(height: 16),

        // Primary Geometry Highlight Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD54F).withOpacity(0.08),
                const Color(0xFF00E5FF).withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BOARD DIMENSIONS',
                style: TextStyle(color: Color(0xFFFFD54F), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${boardW.toStringAsFixed(2)} × ${boardH.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 6),
                  const Text('mm', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _specBadge('Area: ${boardArea.toStringAsFixed(1)} mm²', const Color(0xFF00E5FF)),
                  _specBadge('Perimeter: ${calcPerimeter().toStringAsFixed(1)} mm', const Color(0xFFBB86FC)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stackup & Material Card
        _sidebarCard(
          title: 'STACKUP & MATERIAL',
          icon: Icons.layers,
          iconColor: const Color(0xFFBB86FC),
          child: Column(
            children: [
              _infoRow('Copper Layers', '$_layers Layers', valueColor: const Color(0xFFBB86FC)),
              _infoRow('Board Type', widget.parseResult.boardType),
              _infoRow('Substrate Material', widget.parseResult.material),
              _infoRow('Default Finish', widget.parseResult.pcbFinish),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Drill & Trace Metrics Card
        _sidebarCard(
          title: 'DRILL & TRACE PRECISION',
          icon: Icons.adjust_rounded,
          iconColor: const Color(0xFF00E676),
          child: Column(
            children: [
              _infoRow('Drill Hole Count', '${widget.parseResult.drills.length} holes', valueColor: const Color(0xFF00E676)),
              _infoRow('Hole Size Range', '${minDrill.toStringAsFixed(2)} – ${maxDrill.toStringAsFixed(2)} mm'),
              _infoRow('Min Trace Width', _formatValue(calcMinTrack())),
              _infoRow('Max Trace Width', _formatValue(calcMaxTrack())),
            ],
          ),
        ),
      ],
    );
  }

  // SECTION 2: INSTANT QUOTE & ORDER
  Widget _buildInstantQuoteSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleHeader('SECTION 2 OF 5', 'INSTANT QUOTE & ORDER', Icons.shopping_bag_outlined, const Color(0xFF00E5FF)),
        const SizedBox(height: 16),

        // Solder Mask Interactive Color Picker
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131522),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SOLDER MASK COLOR', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _maskColorVal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _maskColorVal),
                    ),
                    child: Text(
                      _maskColorName,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _maskOptions.map((cName) {
                  final isSel = _maskColorName.toLowerCase() == cName.toLowerCase();
                  Color colorVal = Colors.green;
                  switch (cName.toLowerCase()) {
                    case 'green': colorVal = const Color(0xFF0F2F1D); break;
                    case 'red': colorVal = const Color(0xFF8B0000); break;
                    case 'blue': colorVal = const Color(0xFF0A2240); break;
                    case 'black': colorVal = const Color(0xFF1B1B1E); break;
                    case 'white': colorVal = const Color(0xFFE2E2E6); break;
                    case 'yellow': colorVal = const Color(0xFFD4AC0D); break;
                    case 'purple': colorVal = const Color(0xFF5B2C6F); break;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _updateMaskColor(cName)),
                    child: Tooltip(
                      message: cName,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSel ? 32 : 26,
                        height: isSel ? 32 : 26,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                            width: isSel ? 2.5 : 1.0,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.6), blurRadius: 8)]
                              : [],
                        ),
                        child: isSel
                            ? Icon(Icons.check, size: 14, color: cName.toLowerCase() == 'white' ? Colors.black : Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Manufacturing Specs Dropdowns
        _sidebarCard(
          title: 'SPECIFICATIONS',
          icon: Icons.tune,
          iconColor: const Color(0xFF00E5FF),
          child: Column(
            children: [
              _quoteRow('Layers', _layers, items: _layerOptions, onChanged: (v) {
                setState(() => _layers = v!);
              }),
              _quoteRow('Thickness', _pcbThickness, items: _thicknessOptions, onChanged: (v) {
                setState(() => _pcbThickness = v!);
                final thkVal = double.tryParse(v!.replaceAll(' mm', ''));
                if (thkVal != null) {
                  setState(() {
                    _ruleBoardThickness = thkVal;
                    _runDfm();
                  });
                }
              }),
              _quoteRow('Copper Weight', _copperThickness, items: _copperOptions, onChanged: (v) {
                setState(() => _copperThickness = v!);
                final ozVal = double.tryParse(v!.split(' ').first);
                if (ozVal != null) {
                  setState(() {
                    _ruleCopperThicknessOz = ozVal;
                    _runDfm();
                  });
                }
              }),
              _quoteRow('Surface Finish', _pcbFinish, items: _finishOptions, onChanged: (v) {
                setState(() => _pcbFinish = v!);
              }),
              _quoteRow('Quantity', '$_qty pcs', items: _qtyOptions.map((e) => '$e pcs').toList(), onChanged: (v) {
                setState(() {
                  _qty = int.parse(v!.replaceAll(' pcs', ''));
                });
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Price Summary & Order Action Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF13192B), Color(0xFF1A122B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ESTIMATED PRICE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text('₹ $_currentUnitPrice / pc', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Text(
                    '₹ $_currentTotalPrice',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w900, fontSize: 26),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: const Color(0xFF00E5FF).withOpacity(0.5),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('PLACE ORDER NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SECTION 3: DFM ANALYSIS
  Widget _buildDfmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleHeader('SECTION 3 OF 5', 'DFM ANALYSIS', Icons.bug_report_outlined, const Color(0xFFBB86FC)),
        const SizedBox(height: 16),
        _buildDfmSummaryCard(),
      ],
    );
  }

  // SECTION 4: LAYER MANAGER
  Widget _buildLayerManagerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleHeader('SECTION 4 OF 5', 'LAYER MANAGER', Icons.layers_rounded, const Color(0xFF00BCD4)),
        const SizedBox(height: 16),
        _buildLayerCard(),
      ],
    );
  }

  // SECTION 5: INSPECT & MEASURE
  Widget _buildInspectAndMeasureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleHeader('SECTION 5 OF 5', 'INSPECT & MEASURE TOOLS', Icons.straighten_rounded, const Color(0xFF00E676)),
        const SizedBox(height: 16),
        _buildInspectionSettingsCard(),
      ],
    );
  }


  // 2. DFM Summary Card
  Widget _buildDfmSummaryCard() {
    return _sidebarCard(
      title: 'DFM ANALYSIS SUMMARY',
      icon: Icons.bug_report_outlined,
      iconColor: const Color(0xFFFFD54F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _dfmReport.statusMap.entries.map((e) {
              final status = e.value;
              Color color = const Color(0xFF00E676);
              if (status == 'WARNING') color = const Color(0xFFFFD54F);
              if (status == 'REJECTED') color = const Color(0xFFFF3D00);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'VIOLATIONS LOG',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          if (_dfmReport.violations.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, size: 14, color: Color(0xFF00E676)),
                  SizedBox(width: 8),
                  Text('All DFM rules passed.', style: TextStyle(color: Color(0xFF00E676), fontSize: 12)),
                ],
              ),
            )
          else
            Column(
              children: List.generate(_dfmReport.violations.length, (index) {
                final v = _dfmReport.violations[index];
                final isSelected = _selectedViolation == v;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _dfmReport.violations.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedViolation = v;
                        _zoom = 6.0;
                        _is3DMode = false;
                      });
                      _centerOnGerberCoordinate(v.position, const Size(700, 680));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF3D00).withOpacity(0.12) : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF3D00).withOpacity(0.4) : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('⚠️ ', style: TextStyle(fontSize: 11)),
                              Expanded(
                                child: Text(
                                  v.ruleName,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFFF8A80) : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                v.layerName,
                                style: const TextStyle(color: Colors.white30, fontSize: 9, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            v.description,
                            style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 10),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // 3. Layer visibility card
  Widget _buildLayerCard() {
    final layers = [
      {'label': 'Board Outline', 'key': 'outline'},
      {'label': 'Drills & Holes', 'key': 'drill'},
      {'label': 'Top Copper', 'key': 'top_copper'},
      {'label': 'Inner Copper', 'key': 'inner_copper'},
      {'label': 'Bottom Copper', 'key': 'bottom_copper'},
      {'label': 'Top Solder Mask', 'key': 'top_soldermask'},
      {'label': 'Bottom Solder Mask', 'key': 'bottom_soldermask'},
      {'label': 'Top Silkscreen', 'key': 'top_silkscreen'},
      {'label': 'Bottom Silkscreen', 'key': 'bottom_silkscreen'},
      {'label': 'Top Solder Paste', 'key': 'top_paste'},
      {'label': 'Bottom Solder Paste', 'key': 'bottom_paste'},
    ];

    return _sidebarCard(
      title: 'LAYERS MANAGER',
      icon: Icons.layers_outlined,
      iconColor: const Color(0xFFBB86FC),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _textButton('Show All', () {
                setState(() {
                  _visibleLayers.addAll(layers.map((l) => l['key']!));
                });
              }),
              _textButton('Hide All', () {
                setState(() {
                  _visibleLayers.clear();
                  _visibleLayers.add('outline'); // Keep outline always visible
                });
              }),
              _textButton('Solo Active', () {
                setState(() {
                  _visibleLayers.clear();
                  _visibleLayers.add('outline');
                  _visibleLayers.add(_selectedLayer);
                  if (_selectedLayer.contains('top')) {
                    _visibleLayers.add('top_soldermask');
                    _visibleLayers.add('top_silkscreen');
                  } else {
                    _visibleLayers.add('bottom_soldermask');
                    _visibleLayers.add('bottom_silkscreen');
                  }
                });
              }),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            children: List.generate(layers.length, (index) {
              final l = layers[index];
              final key = l['key']!;
              final label = l['label']!;
              final isVisible = _visibleLayers.contains(key);
              final isActive = _selectedLayer == key;

              return Container(
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withOpacity(0.04) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: isVisible ? const Color(0xFFBB86FC) : Colors.white24,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isVisible) {
                            _visibleLayers.remove(key);
                          } else {
                            _visibleLayers.add(key);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isVisible ? Colors.white : Colors.white30,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (key.contains('copper') || key.contains('silk') || key.contains('mask') || key.contains('paste'))
                      Radio<String>(
                        value: key,
                        groupValue: _selectedLayer,
                        activeColor: const Color(0xFFBB86FC),
                        onChanged: (v) {
                          setState(() {
                            _selectedLayer = v!;
                            _visibleLayers.add(v);
                          });
                        },
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 4. Inspection & Grid Settings Card
  Widget _buildInspectionSettingsCard() {
    return _sidebarCard(
      title: 'INSPECT & MEASURE',
      icon: Icons.straighten_outlined,
      iconColor: const Color(0xFF00E5FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Unit System', style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 12)),
              Row(
                children: ['mm', 'mil', 'inch'].map((u) {
                  final active = _units == u;
                  return GestureDetector(
                    onTap: () => setState(() => _units = u),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF00E5FF).withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: active ? const Color(0xFF00E5FF) : Colors.white10,
                        ),
                      ),
                      child: Text(
                        u.toUpperCase(),
                        style: TextStyle(
                          color: active ? const Color(0xFF00E5FF) : Colors.white30,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Cursor Pos', 'X: ${_formatValue(_mouseHoverGerber.dx)}\nY: ${_formatValue(_mouseHoverGerber.dy)}'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ruler Tool', style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 12)),
              Row(
                children: [
                  if (_measurementStart != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                      onPressed: () => setState(() {
                        _measurementStart = null;
                        _measurementEnd = null;
                      }),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _measurementMode = !_measurementMode;
                        if (!_measurementMode) {
                          _measurementStart = null;
                          _measurementEnd = null;
                        }
                      });
                    },
                    icon: Icon(_measurementMode ? Icons.edit_off : Icons.edit, size: 13),
                    label: Text(_measurementMode ? 'Active' : 'Measure'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _measurementMode ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white12,
                      foregroundColor: _measurementMode ? const Color(0xFF00E5FF) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_measurementStart != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _measureValRow('X1', _measurementStart!.dx),
                  _measureValRow('Y1', _measurementStart!.dy),
                  _measureValRow('X2', (_measurementEnd ?? _mouseHoverGerber).dx),
                  _measureValRow('Y2', (_measurementEnd ?? _mouseHoverGerber).dy),
                  const Divider(color: Colors.white10, height: 12),
                  _measureValRow('ΔX', ((_measurementEnd ?? _mouseHoverGerber).dx - _measurementStart!.dx).abs()),
                  _measureValRow('ΔY', ((_measurementEnd ?? _mouseHoverGerber).dy - _measurementStart!.dy).abs()),
                  _measureValRow('Total Distance', (_measurementStart! - (_measurementEnd ?? _mouseHoverGerber)).distance, isTotal: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('RULER & SNAP HINTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _snapToggle('Snap to Pads', _snapToPad, (v) => setState(() => _snapToPad = v!)),
          _snapToggle('Snap to Tracks', _snapToTrack, (v) => setState(() => _snapToTrack = v!)),
          _snapToggle('Snap to Drills', _snapToDrill, (v) => setState(() => _snapToDrill = v!)),
          _snapToggle('Snap to Outline', _snapToOutline, (v) => setState(() => _snapToOutline = v!)),
        ],
      ),
    );
  }

  // 5. PCB stats info card
  Widget _buildPcbInfoCard() {
    final bbox = widget.parseResult.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);
    final boardW = bbox.width;
    final boardH = bbox.height;
    final boardArea = boardW * boardH;

    double calcPerimeter() {
      if (widget.parseResult.boardOutline != null && widget.parseResult.boardOutline!.traces.isNotEmpty) {
        double p = 0.0;
        for (final t in widget.parseResult.boardOutline!.traces) {
          p += (t.start - t.end).distance;
        }
        return p;
      }
      return 2 * (boardW + boardH);
    }

    double calcMinTrack() {
      double m = double.infinity;
      final layers = [widget.parseResult.topCopper, widget.parseResult.bottomCopper];
      for (final l in layers) {
        if (l == null) continue;
        for (final t in l.traces) {
          if (!t.isArc && t.width < m) m = t.width;
        }
      }
      return m.isInfinite ? 0.2 : m;
    }

    double calcMaxTrack() {
      double m = 0.0;
      final layers = [widget.parseResult.topCopper, widget.parseResult.bottomCopper];
      for (final l in layers) {
        if (l == null) continue;
        for (final t in l.traces) {
          if (!t.isArc && t.width > m) m = t.width;
        }
      }
      return m;
    }

    final double minDrill = widget.parseResult.drills.isNotEmpty
        ? widget.parseResult.drills.map((d) => d.diameter).reduce(math.min)
        : 0.50;
    final double maxDrill = widget.parseResult.drills.isNotEmpty
        ? widget.parseResult.drills.map((d) => d.diameter).reduce(math.max)
        : 1.00;

    Widget metricGroup(String heading, IconData headIcon, Color headColor, List<Widget> rows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headIcon, size: 11, color: headColor),
              const SizedBox(width: 5),
              Text(
                heading,
                style: TextStyle(
                  color: headColor.withOpacity(0.8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.025),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              children: rows,
            ),
          ),
        ],
      );
    }

    return _sidebarCard(
      title: 'PCB METRICS',
      icon: Icons.developer_board_outlined,
      iconColor: const Color(0xFFFFD54F),
      accentColor: const Color(0xFFFFD54F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          metricGroup('BOARD GEOMETRY', Icons.crop_free, const Color(0xFF00E5FF), [
            _infoRow('Dimensions', '${boardW.toStringAsFixed(2)} × ${boardH.toStringAsFixed(2)} mm', valueColor: Colors.white),
            _infoRow('Area', '${boardArea.toStringAsFixed(1)} mm²'),
            _infoRow('Perimeter', '${calcPerimeter().toStringAsFixed(1)} mm'),
          ]),
          const SizedBox(height: 12),
          metricGroup('STACKUP', Icons.layers, const Color(0xFFBB86FC), [
            _infoRow('Copper Layers', '$_layers Layers', valueColor: const Color(0xFFBB86FC)),
            _infoRow('Board Type', widget.parseResult.boardType),
            _infoRow('Material', widget.parseResult.material),
          ]),
          const SizedBox(height: 12),
          metricGroup('DRILL & TRACE', Icons.adjust, const Color(0xFF00E676), [
            _infoRow('Drill Holes', '${widget.parseResult.drills.length} holes', valueColor: const Color(0xFF00E676)),
            _infoRow('Hole Ø Range', '${minDrill.toStringAsFixed(2)} – ${maxDrill.toStringAsFixed(2)} mm'),
            _infoRow('Min Trace', _formatValue(calcMinTrack())),
            _infoRow('Max Trace', _formatValue(calcMaxTrack())),
          ]),
        ],
      ),
    );
  }

  // 2D & 3D Interactive Viewer Component
  Widget _buildViewerContainer(BuildContext context, Size containerSize) {
    final bbox = widget.parseResult.topLayer?.bbox ?? const Rect.fromLTWH(0, 0, 100, 80);
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentWidth = constraints.maxWidth;
        final currentHeight = _isFullscreen ? MediaQuery.of(context).size.height - 180 : containerSize.height;

        return Container(
          width: currentWidth,
          height: currentHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1218),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 1. Rendering Viewport
                if (!_is3DMode)
                  Positioned.fill(
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final double delta = pointerSignal.scrollDelta.dy;
                          final double scaleFactor = delta > 0 ? 0.90 : 1.10;
                          
                          final double oldZoom = _zoom;
                          final double newZoom = (_zoom * scaleFactor).clamp(0.2, 300.0);
                          final localPos = pointerSignal.localPosition;

                          // Zoom relative to cursor point
                          setState(() {
                            const margin = 24.0;
                            final double baseScale = math.min(
                              (currentWidth - margin * 2) / bbox.width,
                              (currentHeight - margin * 2) / bbox.height,
                            );
                            
                            final screenCenter = Offset(currentWidth / 2, currentHeight / 2);
                            final gerberCenter = bbox.center;

                            final Offset cursorInGerber = Offset(
                              (localPos.dx - screenCenter.dx - _pan.dx) / (baseScale * oldZoom) + gerberCenter.dx,
                              -(localPos.dy - screenCenter.dy - _pan.dy) / (baseScale * oldZoom) + gerberCenter.dy,
                            );

                            _zoom = newZoom;

                            final double rotatedDx = cursorInGerber.dx - gerberCenter.dx;
                            final double rotatedDy = -(cursorInGerber.dy - gerberCenter.dy);

                            _pan = Offset(
                              localPos.dx - screenCenter.dx - rotatedDx * baseScale * newZoom,
                              localPos.dy - screenCenter.dy - rotatedDy * baseScale * newZoom,
                            );
                          });
                        }
                      },
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _pan += details.delta;
                          });
                        },
                        onTapDown: (details) {
                          // Snapping math
                          const margin = 24.0;
                          final double baseScale = math.min(
                            (currentWidth - margin * 2) / bbox.width,
                            (currentHeight - margin * 2) / bbox.height,
                          );

                          final screenCenter = Offset(currentWidth / 2, currentHeight / 2);
                          final gerberCenter = bbox.center;

                          double dx = (details.localPosition.dx - screenCenter.dx - _pan.dx) / (baseScale * _zoom);
                          double dy = (details.localPosition.dy - screenCenter.dy - _pan.dy) / (baseScale * _zoom);

                          // Rotate back coordinates for geometry checks
                          if (_rotationAngle != 0.0) {
                            final double angle = -_rotationAngle;
                            final double rx = dx * math.cos(angle) - dy * math.sin(angle);
                            final double ry = dx * math.sin(angle) + dy * math.cos(angle);
                            dx = rx;
                            dy = ry;
                          }
                          dy = -dy; // Invert Y back to Gerber

                          final clickedGerber = _findSnapPoint(Offset(dx + gerberCenter.dx, dy + gerberCenter.dy));

                          if (_measurementMode) {
                            setState(() {
                              if (_measurementStart == null) {
                                _measurementStart = clickedGerber;
                              } else if (_measurementEnd == null) {
                                _measurementEnd = clickedGerber;
                              } else {
                                _measurementStart = clickedGerber;
                                _measurementEnd = null;
                              }
                            });
                          } else {
                            // Check if they clicked a DFM violation marker to zoom into it
                            DfmViolation? clickedV;
                            double bestV = 3.0; // max click radius in mm
                            for (final v in _dfmReport.violations) {
                              final d = (clickedGerber - v.position).distance;
                              if (d < bestV) {
                                bestV = d;
                                clickedV = v;
                              }
                            }
                            if (clickedV != null) {
                              setState(() {
                                _selectedViolation = clickedV;
                                _zoom = 8.0;
                              });
                              _centerOnGerberCoordinate(clickedV.position, Size(currentWidth, currentHeight));
                            }
                          }
                        },
                        child: MouseRegion(
                          cursor: _measurementMode ? SystemMouseCursors.precise : SystemMouseCursors.move,
                          onHover: (details) {
                            const margin = 24.0;
                            final double baseScale = math.min(
                              (currentWidth - margin * 2) / bbox.width,
                              (currentHeight - margin * 2) / bbox.height,
                            );

                            final screenCenter = Offset(currentWidth / 2, currentHeight / 2);
                            final gerberCenter = bbox.center;

                            double dx = (details.localPosition.dx - screenCenter.dx - _pan.dx) / (baseScale * _zoom);
                            double dy = (details.localPosition.dy - screenCenter.dy - _pan.dy) / (baseScale * _zoom);

                            if (_rotationAngle != 0.0) {
                              final double angle = -_rotationAngle;
                              final double rx = dx * math.cos(angle) - dy * math.sin(angle);
                              final double ry = dx * math.sin(angle) + dy * math.cos(angle);
                              dx = rx;
                              dy = ry;
                            }
                            dy = -dy;

                            final gerberPt = Offset(dx + gerberCenter.dx, dy + gerberCenter.dy);
                            setState(() {
                              _mouseHoverGerber = _findSnapPoint(gerberPt);
                            });
                          },
                          child: CustomPaint(
                            size: Size(currentWidth, currentHeight),
                            painter: GerberPCBPainter(
                              parseResult: widget.parseResult,
                              visibleLayers: _visibleLayers,
                              maskColor: _maskColorVal,
                              isTop: _selectedLayer.contains('top'),
                              zoom: _zoom,
                              pan: _pan,
                              rotationAngle: _rotationAngle,
                              viewSize: Size(currentWidth, currentHeight),
                              gridSpacingMm: _gridSpacing,
                              showGrid: _showGrid,
                              violations: _dfmReport.violations,
                              selectedViolation: _selectedViolation,
                              measurementStart: _measurementStart,
                              measurementEnd: _measurementEnd,
                              mouseHoverGerber: _mouseHoverGerber,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final double delta = pointerSignal.scrollDelta.dy;
                          final double scaleFactor = delta > 0 ? 0.90 : 1.10;
                          setState(() {
                            _zoom = (_zoom * scaleFactor).clamp(0.1, 10.0);
                          });
                        }
                      },
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            _rotY += d.delta.dx * 0.008;
                            _tiltX = (_tiltX - d.delta.dy * 0.008)
                                .clamp(5 * math.pi / 180, 75 * math.pi / 180);
                          });
                        },
                        child: CustomPaint(
                          key: ValueKey('3d_${widget.parseResult.uploadId}_$_rotY'),
                          painter: GerberPCB3DPainter(
                            parseResult: widget.parseResult,
                            maskColor: _maskColorVal,
                            hiddenLayers: _visibleLayers.contains('drill') ? {} : {'All.drill'},
                            rotY: _rotY,
                            tiltX: _tiltX,
                            zoom: _zoom,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Crosshairs are drawn directly on the canvas in GerberPCBPainter for performance and style

                // 3. Top-Right Toolbar Action Overlay
                Positioned(
                  right: 12,
                  top: 12,
                  child: Row(
                    children: [
                      _toolbarButton(_is3DMode ? Icons.view_in_ar : Icons.grid_on_outlined, () {
                        setState(() {
                          _is3DMode = !_is3DMode;
                          _zoom = 1.0; // Reset zoom when switching modes
                          _pan = Offset.zero;
                        });
                      }, tooltip: 'Toggle 2D/3D Mode', active: _is3DMode),
                      const SizedBox(width: 6),
                      _toolbarButton(Icons.zoom_in, () {
                        setState(() => _zoom = (_zoom * 1.3).clamp(0.2, 300.0));
                      }, tooltip: 'Zoom In'),
                      const SizedBox(width: 6),
                      _toolbarButton(Icons.zoom_out, () {
                        setState(() => _zoom = (_zoom / 1.3).clamp(0.2, 300.0));
                      }, tooltip: 'Zoom Out'),
                      const SizedBox(width: 6),
                      _toolbarButton(Icons.zoom_out_map, () {
                        setState(() {
                          _zoom = 1.0;
                          _pan = Offset.zero;
                          _rotationAngle = 0;
                        });
                      }, tooltip: 'Fit Board to View'),
                      const SizedBox(width: 6),
                      _toolbarButton(Icons.rotate_right_rounded, () {
                        setState(() {
                          _rotationAngle = (_rotationAngle + math.pi / 2) % (2 * math.pi);
                        });
                      }, tooltip: 'Rotate Board 90°'),
                      const SizedBox(width: 6),
                      _toolbarButton(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, () {
                        setState(() => _isFullscreen = !_isFullscreen);
                      }, tooltip: 'Toggle Fullscreen', active: _isFullscreen),
                    ],
                  ),
                ),

                // 4. Bottom Grid Config overlay in 2D
                if (!_is3DMode)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grid_3x3, size: 14, color: Colors.white60),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _gridSpacing,
                              dropdownColor: const Color(0xFF13131A),
                              icon: const Icon(Icons.arrow_drop_up, color: Colors.white70),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                              items: [
                                {'label': '0.1 mm', 'val': 0.1},
                                {'label': '0.25 mm', 'val': 0.25},
                                {'label': '0.5 mm', 'val': 0.5},
                                {'label': '1.0 mm', 'val': 1.0},
                                {'label': '2.5 mm', 'val': 2.5},
                                {'label': '10 mil', 'val': 0.254},
                                {'label': '50 mil', 'val': 1.27},
                                {'label': '100 mil', 'val': 2.54},
                              ].map((item) {
                                return DropdownMenuItem<double>(
                                  value: item['val'] as double,
                                  child: Text(item['label'] as String),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _gridSpacing = v!),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Checkbox(
                            value: _showGrid,
                            activeColor: const Color(0xFF00E5FF),
                            checkColor: Colors.black,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setState(() => _showGrid = v!),
                          ),
                          const Text('Grid On', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                // 5. Active snapping coordinates indicator overlay
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _is3DMode ? '3D VIEW' : 'INSPECT MODE',
                          style: TextStyle(
                            color: _is3DMode ? const Color(0xFFBB86FC) : const Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        if (!_is3DMode) ...[
                          const SizedBox(height: 4),
                          Text(
                            'X: ${_formatValue(_mouseHoverGerber.dx)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                          ),
                          Text(
                            'Y: ${_formatValue(_mouseHoverGerber.dy)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // Sidebar widget helpers
  Widget _sidebarCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Color? accentColor,
  }) {
    final accent = accentColor ?? iconColor;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Accent top border
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.7), accent.withOpacity(0.0)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(icon, color: accent, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quoteRow(String label, String value, {required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF13131A),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 18),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              items: items.map((e) {
                return DropdownMenuItem<String>(value: e, child: Text(e));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6E6E85), fontSize: 11.5),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              style: TextStyle(
                color: valueColor ?? Colors.white.withOpacity(0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _measureValRow(String label, double val, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? const Color(0xFF00E5FF) : Colors.white38, fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            _formatValue(val),
            style: TextStyle(
              color: isTotal ? const Color(0xFF00E5FF) : Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapToggle(String label, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF00E5FF),
            checkColor: Colors.black,
            visualDensity: VisualDensity.compact,
            onChanged: onChanged,
          ),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _textButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, VoidCallback onTap, {String? tooltip, bool active = false}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? const Color(0xFF00E5FF) : Colors.white10),
          ),
          child: Icon(
            icon,
            color: active ? const Color(0xFF00E5FF) : Colors.white70,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  // Preserved Place Order Firestore logic
  Future<void> _handlePlaceOrder() async {
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to place your order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    double boardW = 100;
    double boardH = 100;
    final dimParts = widget.parseResult.dimensions.toLowerCase().replaceAll('mm', '').split('x');
    if (dimParts.length >= 2) {
      boardW = double.tryParse(dimParts[0].trim()) ?? 100;
      boardH = double.tryParse(dimParts[1].trim()) ?? 100;
    }

    final res = await FirebaseService.saveOrder(
      userEmail: AuthService.userEmail ?? '',
      fileName: widget.fileName,
      layerCount: int.tryParse(_layers) ?? 2,
      boardWidth: boardW,
      boardHeight: boardH,
      quantity: _qty,
      totalPrice: _currentTotalPrice.toDouble(),
      pcbMaterial: widget.parseResult.material,
      pcbThickness: _pcbThickness,
      pcbFinish: _finishOptions.first,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order Placed Successfully! Order ID: ${res['orderId']}'),
          backgroundColor: const Color(0xFF00E5FF),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Failed to place order.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
