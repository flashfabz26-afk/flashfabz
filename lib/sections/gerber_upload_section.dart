import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'section_wrapper.dart';
import 'quote_result_section.dart';
import '../utils/gerber_parser.dart';
import '../services/gerber_api_service.dart';

class GerberUploadSection extends StatefulWidget {
  const GerberUploadSection({super.key});

  @override
  State<GerberUploadSection> createState() => _GerberUploadSectionState();
}

class _GerberUploadSectionState extends State<GerberUploadSection> {
  bool isHovered = false;
  String? selectedFileName;
  GerberParseResult? _parseResult;
  bool _analyzing = false;
  double _analyzeProgress = 0.0;
  String? _errorMessage;
  Key? _quoteKey;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _analyzeFile(String fileName, List<int> bytes) async {
    setState(() {
      _analyzing = true;
      _analyzeProgress = 0.0;
      _errorMessage = null;
    });
    Future<GerberParseResult?> parseTask = GerberApiService.uploadGerber(fileName, bytes);

    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _analyzeProgress = i / 100.0;
      });
    }

    GerberParseResult? result;
    String? error;
    try {
      result = await parseTask;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() {
      _analyzing = false;
      if (error != null) {
        _errorMessage = error;
      } else {
        selectedFileName = fileName;
        _parseResult = result;
        _quoteKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      title: 'INSTANT QUOTE',
      backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.5),
      child: selectedFileName != null && _parseResult != null
          ? QuoteResultSection(
              key: _quoteKey,
              fileName: selectedFileName!,
              parseResult: _parseResult!,
              onUploadNewFile: () {
                setState(() {
                  selectedFileName = null;
                  _parseResult = null;
                  _errorMessage = null;
                  _analyzeProgress = 0.0;
                });
              },
            )
          : _buildUploadCard(context),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return _analyzing ? _buildAnalyzingCard(context) : _buildDropZone(context);
  }

  Widget _buildAnalyzingCard(BuildContext context) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(Icons.analytics_outlined, size: 56, color: Color(0xFF00E5FF)),
          ),
          const SizedBox(height: 28),
          const Text(
            'Analyzing Gerber Files…',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _analyzeLabel(_analyzeProgress),
            style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 14),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _analyzeProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_analyzeProgress * 100).toInt()}%',
            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _analyzeLabel(double progress) {
    if (progress < 0.2)  return 'Parsing Gerber layers…';
    if (progress < 0.45) return 'Running DRC checks…';
    if (progress < 0.65) return 'Calculating board dimensions…';
    if (progress < 0.80) return 'Generating 3D preview…';
    if (progress < 0.95) return 'Pricing your order…';
    return 'Almost done!';
  }

  Widget _buildDropZone(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit:  (_) => setState(() => isHovered = false),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHovered
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(0.05),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: isHovered ? 86 : 80,
              color: isHovered
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white54,
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload your Gerber files',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload your design in .zip or .rar format for an instant\nmanufacturing quote and automated design review.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['ZIP', 'RAR', 'GBR', 'GTL', 'GBL'].map((fmt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(fmt,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8)),
                );
              }).toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['zip', 'rar'],
                  withData: true,
                );
                if (!context.mounted) return;
                if (result != null && result.files.single.bytes != null) {
                  await _analyzeFile(
                    result.files.single.name,
                    result.files.single.bytes!.toList(),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File selection canceled.'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.folder_zip, color: Colors.black),
              label: const Text(
                'Browse Files',
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _featureChip(Icons.security, 'Secure Upload'),
                const SizedBox(width: 16),
                _featureChip(Icons.flash_on, 'Instant Quote'),
                const SizedBox(width: 16),
                _featureChip(Icons.verified, 'DRC Check'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00E5FF)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
