import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'section_wrapper.dart';
import 'quote_result_section.dart';
import '../utils/gerber_parser.dart';
import '../services/gerber_api_service.dart';
import '../utils/gerber_drc_validator.dart';

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
      await Future.delayed(const Duration(milliseconds: 30));
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

  // ── DRC Rejection Dialog ─────────────────────────────────────────────────

  void _showDrcRejectionDialog(List<DrcFailure> failures) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF4D4D).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D4D).withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4D).withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Color(0xFFFF4D4D),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerber File Rejected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Design Rule Check failed',
                            style: TextStyle(
                              color: Color(0xFFFF4D4D),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Message ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.07)),
                  ),
                  child: const Text(
                    'The uploaded PCB design does not meet the supported '
                    'manufacturing specifications. Please correct the following '
                    'issues before uploading again.',
                    style: TextStyle(
                        color: Color(0xFFB0B0C0),
                        fontSize: 13,
                        height: 1.55),
                  ),
                ),
              ),

              // ── Failed validation report ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                child: Row(
                  children: [
                    const Icon(Icons.rule_folder_outlined,
                        size: 15, color: Color(0xFF8B8B9E)),
                    const SizedBox(width: 6),
                    Text(
                      'FAILED VALIDATION REPORT  (${failures.length} issue${failures.length == 1 ? '' : 's'})',
                      style: const TextStyle(
                        color: Color(0xFF8B8B9E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable failure list ────────────────────────────────
              Flexible(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                    shrinkWrap: true,
                    itemCount: failures.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _buildDrcFailureTile(failures[i]),
                  ),
                ),
              ),

              // ── Footer button ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it — Upload a corrected file',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrcFailureTile(DrcFailure failure) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4D).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF4D4D).withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature name
          Row(
            children: [
              const Text('❌', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                failure.featureName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Detected / Required / Reason rows
          _drcRow('Detected', failure.detectedValue,
              const Color(0xFFFF8080)),
          const SizedBox(height: 4),
          _drcRow('Required', failure.requiredValue,
              const Color(0xFF00E5FF)),
          const SizedBox(height: 4),
          _drcRow('Reason', failure.reason, const Color(0xFFB0B0C0)),
        ],
      ),
    );
  }

  Widget _drcRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            '$label:',
            style: const TextStyle(
                color: Color(0xFF6B6B80),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
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
                  allowMultiple: true,
                  withData: true,
                );
                if (!context.mounted) return;
                if (result != null && result.files.isNotEmpty) {
                  final firstFile = result.files.first;
                  if (result.files.length == 1 && firstFile.bytes != null && (firstFile.name.toLowerCase().endsWith('.zip') || firstFile.name.toLowerCase().endsWith('.rar'))) {
                    await _analyzeFile(
                      firstFile.name,
                      firstFile.bytes!.toList(),
                    );
                  } else {
                    // Combine individual files into virtual Gerber collection
                    final archive = Archive();
                    for (final f in result.files) {
                      if (f.bytes != null) {
                        archive.addFile(ArchiveFile(f.name, f.bytes!.length, f.bytes!.toList()));
                      }
                    }
                    final zipBytes = ZipEncoder().encode(archive);
                    if (zipBytes != null) {
                      await _analyzeFile(
                        'Uploaded_Gerber_Set.zip',
                        zipBytes,
                      );
                    }
                  }
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
