import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/gerber_parser.dart';
import '../utils/gerber_renderer.dart';
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
  int _pcbTabIndex = 0;
  final Set<String> _hiddenViewerLayers = {};

  double _rotY = 28 * math.pi / 180;
  double _tiltX = 32 * math.pi / 180;

  late int _qty;
  late String _layers;
  late String _boardType;
  late String _discreteDesign;
  late String _pcbThickness;
  late String _copperThickness;
  late String _pcbFinish;
  late String _maskColor;

  String? _lineWidthError;
  late TextEditingController _lineWidthController;

  late int _randomSeed;

  final List<int> _qtyOptions = [5, 10, 25, 50, 100, 200, 500, 1000];
  final List<String> _layerOptions = ['1', '2', '4', '6', '8', '10', '12'];
  final List<String> _boardTypeOptions = ['Single Piece', 'Panel by Manufacturer', 'Panel by Customer'];
  final List<String> _discreteOptions = ['1 Design', '2 Designs', '3 Designs', '4 Designs'];
  final List<String> _thicknessOptions = ['0.4 mm', '0.6 mm', '0.8 mm', '1.0 mm', '1.2 mm', '1.6 mm', '2.0 mm', '2.4 mm'];
  final List<String> _copperOptions = ['1 oz / 35 µm', '2 oz / 70 µm', '3 oz / 105 µm'];
  final List<String> _finishOptions = ['HASL (with lead)', 'HASL (lead free)', 'ENIG', 'OSP', 'Hard Gold', 'Immersion Silver', 'Immersion Tin'];
  final List<String> _maskOptions = ['Green', 'Red', 'Blue', 'Black', 'White', 'Yellow', 'Purple', 'Matte Black', 'Matte Green'];

  @override
  void initState() {
    super.initState();
    _randomSeed = math.Random().nextInt(9999999);
    _qty             = 10;
    _layers          = widget.parseResult.layerCount.toString();
    _boardType       = widget.parseResult.boardType;
    _discreteDesign  = widget.parseResult.discreteDesign;
    _pcbThickness    = widget.parseResult.pcbThickness;
    _copperThickness = widget.parseResult.copperThickness;
    _pcbFinish       = widget.parseResult.pcbFinish;
    _maskColor       = widget.parseResult.solderMask;
    if (!_layerOptions.contains(_layers)) _layers = '2';
    if (!_copperOptions.contains(_copperThickness)) _copperThickness = _copperOptions.first;
    if (!_maskOptions.contains(_maskColor)) _maskColor = 'Green';
    final initialWidth = widget.parseResult.minLineWidth.replaceAll(' mm', '');
    _lineWidthController = TextEditingController(text: initialWidth);
  }

  @override
  void didUpdateWidget(QuoteResultSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName || oldWidget.parseResult != widget.parseResult) {
      _randomSeed = math.Random().nextInt(9999999);
      _qty             = 10;
      _layers          = widget.parseResult.layerCount.toString();
      _boardType       = widget.parseResult.boardType;
      _discreteDesign  = widget.parseResult.discreteDesign;
      _pcbThickness    = widget.parseResult.pcbThickness;
      _copperThickness = widget.parseResult.copperThickness;
      _pcbFinish       = widget.parseResult.pcbFinish;
      _maskColor       = widget.parseResult.solderMask;
      _lineWidthController.text = widget.parseResult.minLineWidth.replaceAll(' mm', '');
      _rotY = 28 * math.pi / 180;
      _tiltX = 32 * math.pi / 180;
    }
  }

  @override
  void dispose() {
    _lineWidthController.dispose();
    super.dispose();
  }

  Color? get _maskTintColor {
    switch (_maskColor.toLowerCase()) {
      case 'green':        return const Color(0xFF1B4D3E);
      case 'matte green':  return const Color(0xFF0F2A22);
      case 'red':          return const Color(0xFF7A1C1C);
      case 'blue':         return const Color(0xFF1C3D7A);
      case 'black':        return const Color(0xFF111111);
      case 'matte black':  return const Color(0xFF222222);
      case 'white':        return const Color(0xFFEEEEEE);
      case 'yellow':       return const Color(0xFF8A731C);
      case 'purple':       return const Color(0xFF5A1C7A);
      default:             return null;
    }
  }

  BlendMode? get _maskBlendMode => _maskTintColor != null ? BlendMode.color : null;

  int get _currentUnitPrice {
    final layers = int.tryParse(_layers) ?? widget.parseResult.layerCount;
    final base = widget.parseResult.unitPrice;
    final multiplier = layers / math.max(widget.parseResult.layerCount, 1);
    return math.max((base * multiplier).round(), 80);
  }

  int get _currentTotalPrice => _currentUnitPrice * _qty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildTopRow(context),
        const SizedBox(height: 24),
        _buildPCBSection(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
          ),
          child: const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gerber Analysis Complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(widget.fileName, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13)),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: widget.onUploadNewFile,
          icon: const Icon(Icons.upload_file, size: 16),
          label: const Text('Upload Another', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusBadge('READY TO ORDER', const Color(0xFF69FF47)),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildPCBSpecsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF00E5FF).withOpacity(0.12), const Color(0xFF0072FF).withOpacity(0.06)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.developer_board, color: Color(0xFF00E5FF), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('PCB SPECIFICATIONS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF69FF47).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF69FF47).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFF69FF47), size: 13),
                      SizedBox(width: 5),
                      Text('Auto-detected from Gerber', style: TextStyle(color: Color(0xFF69FF47), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final specs = _buildSpecFields();
                final isWide = constraints.maxWidth > 700;
                final cols = isWide ? 3 : 2;
                final gap = isWide ? 16.0 : 12.0;
                final rows = <Widget>[];
                for (int i = 0; i < specs.length; i += cols) {
                  final rowChildren = <Widget>[];
                  for (int c = 0; c < cols; c++) {
                    if (c > 0) rowChildren.add(SizedBox(width: gap));
                    rowChildren.add(Expanded(child: i + c < specs.length ? specs[i + c] : const SizedBox()));
                  }
                  rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));
                  if (i + cols < specs.length) rows.add(SizedBox(height: gap));
                }
                return Column(children: rows);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpecFields() {
    return [
      _specDropdown<int>(label: 'PCB Qty', icon: Icons.inventory_2_outlined, iconColor: const Color(0xFF00E5FF),
        value: _qty, items: _qtyOptions, displayFn: (v) => '$v pcs', onChanged: (v) => setState(() => _qty = v!), isDetected: false),
      _specDropdown<String>(label: 'Layers', icon: Icons.layers_outlined, iconColor: const Color(0xFFBB86FC),
        value: _layers, items: _layerOptions, displayFn: (v) => '$v Layer${int.parse(v) > 1 ? 's' : ''}',
        onChanged: (v) => setState(() => _layers = v!), isDetected: true),
      _specInfoField(label: 'Board Dimensions', icon: Icons.straighten_outlined, iconColor: const Color(0xFFFFD54F),
        value: widget.parseResult.dimensions, isDetected: true),
      _specDropdown<String>(label: 'Discrete Design', icon: Icons.grid_view_outlined, iconColor: const Color(0xFF69FF47),
        value: _discreteDesign, items: _discreteOptions, displayFn: (v) => v,
        onChanged: (v) => setState(() => _discreteDesign = v!), isDetected: false),
      _specDropdown<String>(label: 'Board Type', icon: Icons.developer_board_outlined, iconColor: const Color(0xFFFF7043),
        value: _boardType, items: _boardTypeOptions, displayFn: (v) => v,
        onChanged: (v) => setState(() => _boardType = v!), isDetected: false),
      _specDropdown<String>(label: 'PCB Thickness', icon: Icons.height_outlined, iconColor: const Color(0xFF26C6DA),
        value: _pcbThickness, items: _thicknessOptions, displayFn: (v) => v,
        onChanged: (v) => setState(() => _pcbThickness = v!), isDetected: false),
      _specDropdown<String>(label: 'Copper Thickness', icon: Icons.electrical_services_outlined, iconColor: const Color(0xFFFFD54F),
        value: _copperThickness, items: _copperOptions, displayFn: (v) => v,
        onChanged: (v) => setState(() => _copperThickness = v!), isDetected: true),
      _specDropdown<String>(label: 'PCB Finish', icon: Icons.auto_fix_high_outlined, iconColor: const Color(0xFFBB86FC),
        value: _pcbFinish, items: _finishOptions, displayFn: (v) => v,
        onChanged: (v) => setState(() => _pcbFinish = v!), isDetected: false),
      _specDropdown<String>(label: 'Mask Color', icon: Icons.color_lens_outlined, iconColor: _maskColorValue(_maskColor),
        value: _maskColor, items: _maskOptions, displayFn: (v) => v,
        onChanged: (v) => setState(() => _maskColor = v!), isDetected: false, showColorDot: true),
      _specLineWidthField(),
    ];
  }

  Color _maskColorValue(String color) {
    switch (color.toLowerCase()) {
      case 'green': case 'matte green': return Colors.green;
      case 'red':   return Colors.red;
      case 'blue':  return Colors.blue;
      case 'black': case 'matte black': return Colors.grey.shade700;
      case 'white': return Colors.white;
      case 'yellow': return Colors.amber;
      case 'purple': return Colors.purple;
      default:      return const Color(0xFF00E5FF);
    }
  }

  Widget _specDropdown<T>({
    required String label, required IconData icon, required Color iconColor,
    required T value, required List<T> items, required String Function(T) displayFn,
    required ValueChanged<T?> onChanged, required bool isDetected, bool showColorDot = false,
  }) {
    return _specFieldContainer(
      label: label, icon: icon, iconColor: iconColor, isDetected: isDetected,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, isExpanded: true,
          dropdownColor: const Color(0xFF1E1E2A),
          icon: const Icon(Icons.expand_more, color: Color(0xFF8B8B9E), size: 18),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  if (showColorDot) ...[
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _maskColorValue(item.toString()), shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(displayFn(item), style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _specInfoField({required String label, required IconData icon, required Color iconColor, required String value, required bool isDetected}) {
    return _specFieldContainer(
      label: label, icon: icon, iconColor: iconColor, isDetected: isDetected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _specLineWidthField() {
    return _specFieldContainer(
      label: 'Min Line Width', icon: Icons.linear_scale_outlined, iconColor: const Color(0xFFFF7043), isDetected: true,
      child: TextField(
        controller: _lineWidthController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          suffixText: 'mm',
          suffixStyle: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          errorText: _lineWidthError, errorMaxLines: 2,
          errorStyle: const TextStyle(fontSize: 10, color: Colors.redAccent, height: 1.2),
          filled: true, fillColor: Colors.white12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v);
          setState(() { _lineWidthError = (parsed == null || parsed < 0.10) ? 'Min allowed is 0.10 mm' : null; });
        },
      ),
    );
  }

  Widget _specFieldContainer({required String label, required IconData icon, required Color iconColor, required bool isDetected, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDetected ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
              if (isDetected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('AUTO', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildQuotationCard(context)),
                const SizedBox(width: 24),
                Expanded(child: _buildProjectDetailsCard(context)),
              ])
            : Column(children: [
                _buildQuotationCard(context),
                const SizedBox(height: 24),
                _buildProjectDetailsCard(context),
              ]);
      },
    );
  }

  Widget _buildQuotationCard(BuildContext context) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.receipt_long, 'QUOTATION', const Color(0xFF00E5FF)),
          const SizedBox(height: 20),
          _quoteRow('Unit Price', '₹ $_currentUnitPrice', highlight: false),
          _divider(),
          _quoteRow('Quantity', '$_qty pcs', highlight: false),
          _divider(),
          _quoteRow('PCB Thickness', _pcbThickness, highlight: false),
          _divider(),
          _quoteRow('Surface Finish', _pcbFinish, highlight: false),
          _divider(),
          _quoteRow('Delivery', '3-5 Days', highlight: false),
          _divider(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0072FF)]), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                Text('₹ $_currentTotalPrice', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
              label: const Text('Place Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteRow(String label, String value, {required bool highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 14)),
          Text(value, style: TextStyle(color: highlight ? const Color(0xFF00E5FF) : Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProjectDetailsCard(BuildContext context) {
    final layersText = '$_layers Layer${(int.tryParse(_layers) ?? 2) > 1 ? 's' : ''}';
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.info_outline, 'PROJECT DETAILS', const Color(0xFFFFD54F)),
          const SizedBox(height: 20),
          _detailItem('File Name', widget.fileName, Icons.folder_zip_outlined),
          _detailItem('Board Dimensions', widget.parseResult.dimensions, Icons.straighten),
          _detailItem('Layers', layersText, Icons.layers),
          _detailItem('Copper Thickness', _copperThickness, Icons.electrical_services),
          _detailItem('Line Width', widget.parseResult.minLineWidth, Icons.linear_scale),
          _detailItem('Line to Line Gap', widget.parseResult.minTraceSpace, Icons.space_bar_outlined),
          _detailItem('Drill Size', widget.parseResult.minHoleSize, Icons.circle_outlined),
          _detailItem('Board Material', widget.parseResult.material, Icons.inventory_2_outlined),
          _detailItem('Solder Mask', _maskColor, Icons.color_lens_outlined),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF69FF47).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF69FF47).withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_outlined, color: Color(0xFF69FF47), size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('DRC Passed — No design rule violations detected.', style: TextStyle(color: Color(0xFF69FF47), fontSize: 13, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD54F), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPCBSection(BuildContext context) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.developer_board, 'PCB PREVIEW', const Color(0xFFBB86FC)),
          const SizedBox(height: 16),
          _buildDetectedLayersRow(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.layers, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              const Text('LAYER VISIBILITY', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              _buildLayerToggles(),
            ],
          ),
          const SizedBox(height: 24),
          const Text('3D INTERACTIVE VIEWER', style: TextStyle(color: Color(0xFFBB86FC), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildViewerTab(),
          const SizedBox(height: 32),
          const Text('2D LAYER PREVIEWS', style: TextStyle(color: Color(0xFFBB86FC), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildImagesTab(),
        ],
      ),
    );
  }
Widget _buildDetectedLayersRow() {
    final top = widget.parseResult.topLayer;
    final bot = widget.parseResult.bottomLayer;
    final hasTopCopper   = top != null && (top.traces.isNotEmpty  || top.pads.isNotEmpty);
    final hasBotCopper   = bot != null && (bot.traces.isNotEmpty  || bot.pads.isNotEmpty);
    final hasOutline     = (top?.outline.isNotEmpty ?? false) || (bot?.outline.isNotEmpty ?? false);
    final hasDrills      = (top?.drills.isNotEmpty  ?? false);
    final hasTopSilk     = top != null && top.silkscreen.isNotEmpty;
    final hasBotSilk     = bot != null && bot.silkscreen.isNotEmpty;
    final hasTopMask     = top != null && (top.soldermaskPads.isNotEmpty || top.soldermaskTraces.isNotEmpty);
    final hasBotMask     = bot != null && (bot.soldermaskPads.isNotEmpty || bot.soldermaskTraces.isNotEmpty);

    Widget chip(String label, bool detected) {
      return Container(
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: detected ? const Color(0xFF00E5FF).withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: detected ? const Color(0xFF00E5FF).withOpacity(0.4) : Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(detected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 10, color: detected ? const Color(0xFF00E5FF) : Colors.white24),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: detected ? Colors.white70 : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Wrap(
      children: [
        chip('Top Copper',    hasTopCopper),
        chip('Bottom Copper', hasBotCopper),
        chip('Top Mask',      hasTopMask),
        chip('Bottom Mask',   hasBotMask),
        chip('Top Silk',      hasTopSilk),
        chip('Bottom Silk',   hasBotSilk),
        chip('Outline',       hasOutline),
        chip('Drills',        hasDrills),
      ],
    );
  }
  Widget _buildLayerToggles() {
    final layers = [
      {'label': 'copper',   'key': 'Top.copper'},
      {'label': 'mask',     'key': 'Top.soldermask'},
      {'label': 'silk',     'key': 'Top.silkscreen'},
      {'label': 'drill',    'key': 'All.drill'},
      {'label': 'outline',  'key': 'All.outline'},
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: layers.map((l) {
        final layerKey = l['key']!;
        final label    = l['label']!;
        final hidden = _hiddenViewerLayers.contains(layerKey);
        return GestureDetector(
          onTap: () => setState(() {
            if (hidden) _hiddenViewerLayers.remove(layerKey);
            else _hiddenViewerLayers.add(layerKey);
          }),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hidden ? Colors.transparent : const Color(0xFFBB86FC).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: hidden ? Colors.white12 : const Color(0xFFBB86FC).withOpacity(0.5)),
            ),
            child: Text(label,
                style: TextStyle(
                    color: hidden ? Colors.white24 : const Color(0xFFBB86FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        );
      }).toList(),
    );
  }

  Widget _pcbTab(String label, IconData icon, int index) {
    final active = _pcbTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _pcbTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFBB86FC).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFFBB86FC) : Colors.white.withOpacity(0.08), width: active ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFFBB86FC) : Colors.white54),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: active ? const Color(0xFFBB86FC) : Colors.white54, fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCompositeView('Top',    widget.parseResult.topImageUrl,    widget.parseResult.topLayer),
        const SizedBox(height: 32),
        _buildCompositeView('Bottom', widget.parseResult.bottomImageUrl, widget.parseResult.bottomLayer),
      ],
    );
  }

  Widget _buildCompositeView(String title, String? imageUrl, PCBLayerData? layerData) {
    return Column(
      children: [
        Container(
          width: double.infinity, height: 380,
          decoration: BoxDecoration(color: const Color(0xFF0F1218), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (imageUrl != null)
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 0.5, maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        key: ValueKey(imageUrl),
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                        },
                      ),
                    ),
                  ),
                if (imageUrl == null && layerData != null && layerData.bbox.width > 0)
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 10.0,
                      child: CustomPaint(
                        painter: GerberPCBPainter(
                          layerData: layerData,
                          maskColor: _maskTintColor ?? const Color(0xFF1B4D3E),
                          isTop: title == 'Top',
                          hiddenLayers: _hiddenViewerLayers,
                        ),
                      ),
                    ),
                  ),
                if (imageUrl == null && (layerData == null || layerData.bbox.width <= 0))
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CompositePCBPainter(
                        isTop: title == 'Top',
                        seed: _randomSeed,
                        maskColor: _maskTintColor ?? const Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07070A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'FILE: ${widget.fileName.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LAYER: ${title.toUpperCase()} | COLOR: ${_maskColor.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildViewerTab() {
    final topLayer = widget.parseResult.topLayer;
    final hasRealData = topLayer != null && topLayer.bbox.width > 0;

    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
           
            if (hasRealData)
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _rotY  += d.delta.dx * 0.008;
                      _tiltX  = (_tiltX - d.delta.dy * 0.008)
                          .clamp(5 * math.pi / 180, 75 * math.pi / 180);
                    });
                  },
                  child: CustomPaint(
                    key: ValueKey('3d_${widget.parseResult.uploadId}'),
                    painter: GerberPCB3DPainter(
                      topLayer: topLayer!,
                      maskColor: _maskTintColor ?? const Color(0xFF1B4D3E),
                      hiddenLayers: _hiddenViewerLayers,
                      rotY:  _rotY,
                      tiltX: _tiltX,
                    ),
                  ),
                ),
              ),
            if (!hasRealData)
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _rotY  += d.delta.dx * 0.008;
                      _tiltX  = (_tiltX - d.delta.dy * 0.008)
                          .clamp(5 * math.pi / 180, 75 * math.pi / 180);
                    });
                  },
                  child: CustomPaint(
                    painter: _Fake3DPainter(
                      maskColor: _maskTintColor ?? const Color(0xFF1B4D3E),
                      seed: _randomSeed,
                      rotY: _rotY,
                      tiltX: _tiltX,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12, top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF07070A).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('FILE: ${widget.fileName.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const SizedBox(height: 3),
                    Text('3D VIEW | ${_maskColor.toUpperCase()} MASK',
                        style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ), 
            Positioned(
              right: 12, bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_with, color: Colors.white38, size: 13),
                    SizedBox(width: 5),
                    Text('Drag to rotate', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12, top: 12,
              child: GestureDetector(
                onTap: () => setState(() {
                  _rotY  = 28 * math.pi / 180;
                  _tiltX = 32 * math.pi / 180;
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: const Color(0xFF16161D), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: child,
    );
  }

  Widget _cardTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2)),
      ],
    );
  }

  Widget _divider() => Divider(color: Colors.white.withOpacity(0.06), height: 1);
}
class _FlatPCBViewerPainter extends CustomPainter {
  final Set<String> hiddenLayers;
  final int seed;
  _FlatPCBViewerPainter({required this.hiddenLayers, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final math.Random rand = math.Random(seed);

    if (!hiddenLayers.contains('All.outline')) {
      final boardRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(2));
      bool topMask = !hiddenLayers.contains('Top.soldermask');
      canvas.drawRRect(boardRect, Paint()..color = topMask ? const Color(0xFF4C984C) : const Color(0xFFD6943C));
    }

    if (!hiddenLayers.contains('Top.copper')) {
      final tracePaint = Paint()
        ..color = hiddenLayers.contains('Top.soldermask') ? const Color(0xFFDE9F4D) : const Color(0xFF5CB85C)
        ..strokeWidth = 2.5 ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
      final Path routing = Path();
      for (int i = 0; i < 20; i++) {
        double currentX = 20 + rand.nextDouble() * (size.width - 40);
        double currentY = 20 + rand.nextDouble() * (size.height - 40);
        routing.moveTo(currentX, currentY);
        int segments = 1 + rand.nextInt(3);
        for (int j = 0; j < segments; j++) {
          if (rand.nextBool()) { currentX += (rand.nextBool() ? 15 : -15); } else { currentY += (rand.nextBool() ? 15 : -15); }
          routing.lineTo(currentX, currentY);
        }
        canvas.drawCircle(Offset(currentX, currentY), 2.5, tracePaint..style = PaintingStyle.fill);
        tracePaint.style = PaintingStyle.stroke;
      }
      canvas.drawPath(routing, tracePaint);
    }

    if (!hiddenLayers.contains('Top.solderpaste') || !hiddenLayers.contains('Top.copper')) {
      final padPaint = Paint()..color = const Color(0xFFD4D4D4);
      for (int i = 0; i < 8; i++) {
        canvas.drawRect(Rect.fromLTWH(cx - 40, cy - 30 + i * 8, 10, 4), padPaint);
        canvas.drawRect(Rect.fromLTWH(cx - 15, cy - 30 + i * 8, 10, 4), padPaint);
      }
      for (int i = 0; i < 5; i++) { canvas.drawCircle(Offset(cx + 90, cy - 20 + i * 14), 5, padPaint); }
    }

    if (!hiddenLayers.contains('All.drill')) {
      final holePaint = Paint()..color = const Color(0xFFEAEAEA);
      for (int i = 0; i < 5; i++) { canvas.drawCircle(Offset(cx + 90, cy - 20 + i * 14), 2.5, holePaint); }
    }

    if (!hiddenLayers.contains('Top.silkscreen')) {
      final silkPaint = Paint()..color = Colors.white ..strokeWidth = 1.2 ..style = PaintingStyle.stroke;
      canvas.drawRect(Rect.fromLTWH(cx - 42, cy - 32, 39, 66), silkPaint);
      canvas.drawCircle(Offset(cx - 35, cy - 25), 1.5, Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(30, 90, 20, 40), silkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlatPCBViewerPainter oldDelegate) => oldDelegate.hiddenLayers != hiddenLayers || oldDelegate.seed != seed;
}

class _CompositePCBPainter extends CustomPainter {
  final bool isTop;
  final int seed;
  final Color maskColor;
  _CompositePCBPainter({required this.isTop, required this.seed, this.maskColor = const Color(0xFF1B4D3E)});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0A0A12));
    final cx = size.width / 2;
    final cy = size.height / 2;
    final boardW = size.width * 0.9;
    final boardH = size.height * 0.85;
    final boardRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: boardW, height: boardH), const Radius.circular(6));

    canvas.drawRRect(boardRect, Paint()..color = const Color(0xFFD6943C));
    
    canvas.drawRRect(boardRect, Paint()..color = maskColor.withOpacity(0.85));

    final math.Random rand = math.Random(seed + (isTop ? 42 : 1337));
    final tracePaint = Paint()..color = const Color(0xFFDE9F4D) ..strokeWidth = 2.0 ..strokeCap = StrokeCap.round ..strokeJoin = StrokeJoin.miter ..style = PaintingStyle.stroke;
    final Path routing = Path();
    for (int i = 0; i < (isTop ? 60 : 40); i++) {
      double startX = cx - boardW/2 + 20 + rand.nextDouble() * (boardW - 40);
      double startY = cy - boardH/2 + 20 + rand.nextDouble() * (boardH - 40);
      routing.moveTo(startX, startY);
      double currentX = startX;
      double currentY = startY;
      int segments = 2 + rand.nextInt(4);
      for (int j = 0; j < segments; j++) {
        if (rand.nextBool()) { currentX += (rand.nextBool() ? 20 : -20); } else { currentY += (rand.nextBool() ? 20 : -20); }
        routing.lineTo(currentX, currentY);
      }
      canvas.drawCircle(Offset(currentX, currentY), 2.5, Paint()..color = const Color(0xFFDE9F4D)..style = PaintingStyle.fill);
    }

    final polyPaint = Paint()..color = const Color(0xFFDCA152).withOpacity(0.8) ..style = PaintingStyle.fill;
    if (isTop) {
      final Path poly1 = Path();
      poly1.moveTo(cx - 150, cy + 60); poly1.lineTo(cx - 20, cy + 60); poly1.lineTo(cx - 20, cy + 100); poly1.lineTo(cx - 150, cy + 100); poly1.close();
      canvas.drawPath(poly1, polyPaint);
    } else {
      final Path poly2 = Path();
      poly2.moveTo(cx + 40, cy - 100); poly2.lineTo(cx + 150, cy - 100); poly2.lineTo(cx + 150, cy - 30); poly2.lineTo(cx + 80, cy - 30); poly2.close();
      canvas.drawPath(poly2, polyPaint);
    }
    canvas.drawPath(routing, tracePaint);

    final padPaint = Paint()..color = const Color(0xFFB5B5BE) ..style = PaintingStyle.fill;
    final holePaint = Paint()..color = const Color(0xFF1B1B1B) ..style = PaintingStyle.fill;

    if (isTop) {
      for (int i = -6; i <= 6; i++) {
        if (i == 0) continue;
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + i * 4.5, cy - 25), width: 2.5, height: 8), padPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + i * 4.5, cy + 25), width: 2.5, height: 8), padPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx - 25, cy + i * 4.5), width: 8, height: 2.5), padPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + 25, cy + i * 4.5), width: 8, height: 2.5), padPaint);
      }
    }
    for (int i = 0; i < 8; i++) {
      canvas.drawRect(Rect.fromCenter(center: Offset(cx - 100, cy - 60 + i * 6), width: 7, height: 3), padPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(cx - 75, cy - 60 + i * 6), width: 7, height: 3), padPaint);
    }
    for (int i = 0; i < (isTop ? 40 : 25); i++) {
      double px = cx - boardW/2 + 30 + rand.nextDouble() * (boardW - 60);
      double py = cy - boardH/2 + 30 + rand.nextDouble() * (boardH - 60);
      if (px > cx - 40 && px < cx + 40 && py > cy - 40 && py < cy + 40) continue;
      if (rand.nextBool()) {
        canvas.drawRect(Rect.fromCenter(center: Offset(px - 3, py), width: 3, height: 4.5), padPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(px + 3, py), width: 3, height: 4.5), padPaint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset(px, py - 3), width: 4.5, height: 3), padPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(px, py + 3), width: 4.5, height: 3), padPaint);
      }
    }
    for (int i = 0; i < 20; i++) {
      double px = cx - boardW/2 + 20 + rand.nextDouble() * (boardW - 40);
      double py = cy - boardH/2 + 20 + rand.nextDouble() * (boardH - 40);
      canvas.drawCircle(Offset(px, py), 2.5, padPaint);
      canvas.drawCircle(Offset(px, py), 1.2, holePaint);
    }
    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(Offset(cx + boardW/2 - 30, cy - 80 + i * 15), 4.5, padPaint);
      canvas.drawCircle(Offset(cx + boardW/2 - 30, cy - 80 + i * 15), 2.5, holePaint);
    }
    final mountingHoles = [
      Offset(cx - boardW/2 + 25, cy - boardH/2 + 25), Offset(cx + boardW/2 - 25, cy - boardH/2 + 25),
      Offset(cx - boardW/2 + 25, cy + boardH/2 - 25), Offset(cx + boardW/2 - 25, cy + boardH/2 - 25),
    ];
    for (var pos in mountingHoles) { canvas.drawCircle(pos, 10, padPaint); canvas.drawCircle(pos, 6, holePaint); }

    if (isTop) {
      final silkPaint = Paint()..color = Colors.white.withOpacity(0.85) ..strokeWidth = 1.2 ..style = PaintingStyle.stroke;
      final textStyle = const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600, fontFamily: 'monospace');
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 44, height: 44), silkPaint);
      canvas.drawCircle(Offset(cx - 16, cy - 16), 2, Paint()..color = Colors.white..style = PaintingStyle.fill);
      _drawText(canvas, 'U1', Offset(cx, cy - 5), textStyle);
      _drawText(canvas, 'STM32', Offset(cx, cy + 5), textStyle.copyWith(fontSize: 6));
      canvas.drawRect(Rect.fromCenter(center: Offset(cx - 87.5, cy - 39), width: 14, height: 50), silkPaint);
      _drawText(canvas, 'U2', Offset(cx - 87.5, cy - 8), textStyle);
      _drawText(canvas, 'AL_DEVELOPMENT_BRD', Offset(cx, cy + boardH/2 - 30), textStyle.copyWith(fontSize: 10));
      _drawText(canvas, 'ARONLABZ TECH PVT LTD', Offset(cx, cy + boardH/2 - 18), textStyle.copyWith(fontSize: 10));
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CompositePCBPainter old) => old.isTop != isTop || old.seed != seed || old.maskColor != maskColor;
}

class _Fake3DPainter extends CustomPainter {
  final Color maskColor;
  final int seed;
  final double rotY;
  final double tiltX;

  const _Fake3DPainter({
    required this.maskColor,
    required this.seed,
    this.rotY = 0.49,
    this.tiltX = 0.56,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final boardW = size.width * 0.52;
    final boardH = boardW * 0.65;
    const thick = 10.0;

    Offset proj(double lx, double ly, double lz) {
      final rx = lx * math.cos(rotY) + lz * math.sin(rotY);
      final rz = -lx * math.sin(rotY) + lz * math.cos(rotY);
      final ry = ly * math.cos(tiltX) - rz * math.sin(tiltX);
      return Offset(cx + rx, cy + ry * 0.82);
    }

    final tl  = proj(-boardW/2, -boardH/2,  thick/2);
    final tr  = proj( boardW/2, -boardH/2,  thick/2);
    final br  = proj( boardW/2,  boardH/2,  thick/2);
    final bl  = proj(-boardW/2,  boardH/2,  thick/2);
    final tlb = proj(-boardW/2, -boardH/2, -thick/2);
    final trb = proj( boardW/2, -boardH/2, -thick/2);
    final brb = proj( boardW/2,  boardH/2, -thick/2);
    final blb = proj(-boardW/2,  boardH/2, -thick/2);

    void quad(List<Offset> pts, Color color) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy)
        ..lineTo(pts[3].dx, pts[3].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0A0A12));
    quad([tlb, trb, brb, blb], const Color(0xFF9A6218));
    quad([tl, tlb, blb, bl],   const Color(0xFF7A4E10));
    quad([tr, trb, brb, br],   const Color(0xFFBB7A1C));
    quad([tl, tr, trb, tlb],   const Color(0xFF8A5A12));
    quad([bl, br, brb, blb],   const Color(0xFF6A4510));

    final topPath = Path()
      ..moveTo(tl.dx, tl.dy)..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)..lineTo(bl.dx, bl.dy)..close();
    canvas.drawPath(topPath, Paint()..color = maskColor.withOpacity(0.90));

 
    final rand = math.Random(seed);
    final tp = Paint()
      ..color = const Color(0xFFDE9F4D).withOpacity(0.65)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 25; i++) {
      final nx = (rand.nextDouble() - 0.5) * boardW;
      final ny = (rand.nextDouble() - 0.5) * boardH;
      final nx2 = nx + (rand.nextBool() ? 20 : 0) * (rand.nextBool() ? 1 : -1);
      final ny2 = ny + (rand.nextBool() ? 0 : 20) * (rand.nextBool() ? 1 : -1);
      canvas.drawLine(proj(nx, ny, thick/2 + 0.8), proj(nx2, ny2, thick/2 + 0.8), tp);
    }

    canvas.drawPath(topPath, Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_Fake3DPainter old) =>
      old.maskColor != maskColor || old.seed != seed ||
      old.rotY != rotY || old.tiltX != tiltX;
}
