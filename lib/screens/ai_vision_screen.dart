import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/donation_models.dart';
import '../services/ai_vision_service.dart';
import '../widgets/ai_scan_result_card.dart';
import '../widgets/common_widgets.dart';

class AiVisionScreen extends StatefulWidget {
  const AiVisionScreen({super.key});

  @override
  State<AiVisionScreen> createState() => _AiVisionScreenState();
}

class _AiVisionScreenState extends State<AiVisionScreen> {
  final _aiService = AiVisionService();
  Uint8List? _imageBytes;
  String? _fileName;
  AiVisionResult? _result;
  bool _isAnalyzing = false;
  String _analysisStep = '';
  AiScanPreset? _activePreset;

  static const _demoPresets = [
    (
      preset: AiScanPreset.invacareWheelchair,
      icon: Icons.accessible,
      color: AppTheme.primaryBlue,
    ),
    (
      preset: AiScanPreset.driveRollator,
      icon: Icons.directions_walk,
      color: AppTheme.accentTeal,
    ),
    (
      preset: AiScanPreset.woundDressingKit,
      icon: Icons.healing,
      color: Color(0xFF6A1B9A),
    ),
    (
      preset: AiScanPreset.oxygenConcentrator,
      icon: Icons.air,
      color: Color(0xFFEF6C00),
    ),
  ];

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read image data. Try another file.')),
      );
      return;
    }

    setState(() {
      _imageBytes = file.bytes;
      _fileName = file.name;
      _result = null;
      _activePreset = null;
    });
  }

  Future<void> _runAnalysis({AiScanPreset? preset}) async {
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _analysisStep = 'Connecting to GPT-4o Vision...';
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _analysisStep = 'Identifying brand, model & category...');

      final AiVisionResult analysis;
      if (preset != null) {
        analysis = await _aiService.analyzePreset(preset);
      } else {
        analysis = await _aiService.analyzeImage(_imageBytes!, _fileName!);
      }

      if (!mounted) return;
      setState(() => _analysisStep = 'Calculating estimated retail value...');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      setState(() {
        _result = analysis;
        if (preset != null) {
          _activePreset = preset;
          _fileName = '${_aiService.presetLabel(preset)}.jpg';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisStep = '';
        });
      }
    }
  }

  Future<void> _simulatePreset(AiScanPreset preset) async {
    setState(() {
      _imageBytes = _placeholderBytesFor(preset);
      _fileName = '${_aiService.presetLabel(preset)}.jpg';
      _activePreset = preset;
      _result = null;
    });
    await _runAnalysis(preset: preset);
  }

  Uint8List _placeholderBytesFor(AiScanPreset preset) {
    // Minimal valid 1x1 PNG used only as a visual placeholder for demo scans.
    return Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ])..add(preset.index);
  }

  void _clearScan() {
    setState(() {
      _imageBytes = null;
      _fileName = null;
      _result = null;
      _activePreset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Scan'),
        actions: [
          if (_imageBytes != null || _result != null)
            TextButton.icon(
              onPressed: _isAnalyzing ? null : _clearScan,
              icon: const Icon(Icons.refresh),
              label: const Text('New Scan'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'GPT-4o Vision Equipment Scanner',
              subtitle:
                  'Upload a DME or wound care photo to auto-detect brand, model, category, and estimated tax-deductible value.',
            ),
            const SizedBox(height: 16),
            const ComplianceBanner(),
            const SizedBox(height: 24),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildUploadPanel()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildResultsPanel()),
                ],
              )
            else ...[
              _buildUploadPanel(),
              const SizedBox(height: 24),
              _buildResultsPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload Photo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'JPEG or PNG of the item label, packaging, or full product view.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isAnalyzing ? null : _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imageBytes == null
                            ? AppTheme.primaryBlue.withValues(alpha: 0.35)
                            : Colors.grey.shade300,
                        width: _imageBytes == null ? 2 : 1,
                      ),
                    ),
                    child: _isAnalyzing
                        ? _AnalysisOverlay(step: _analysisStep)
                        : _imageBytes == null
                            ? const _UploadPlaceholder()
                            : _ImagePreview(
                                imageBytes: _imageBytes!,
                                fileName: _fileName,
                                preset: _activePreset,
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzing ? null : _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose Photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _imageBytes == null || _isAnalyzing
                            ? null
                            : () => _runAnalysis(),
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Run AI Scan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Quick Simulate', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'No photo handy? Run a demo scan with pre-loaded GPT-4o Vision responses.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _demoPresets.map((demo) {
            final label = _aiService.presetLabel(demo.preset);
            return ActionChip(
              avatar: Icon(demo.icon, size: 18, color: demo.color),
              label: Text(label),
              onPressed: _isAnalyzing ? null : () => _simulatePreset(demo.preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsPanel() {
    if (_result == null && !_isAnalyzing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Scan results will appear here',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a photo or use Quick Simulate to extract brand, model, category, and estimated retail value for your IRS donation record.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_isAnalyzing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _AnalysisOverlay(step: _analysisStep, expanded: true),
        ),
      );
    }

    return AiScanResultCard(
      result: _result!,
      onContinue: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _result!.isDme
                  ? 'Opening DME form with ${_result!.brand} ${_result!.model}...'
                  : 'Opening Wound Care form with ${_result!.brand} ${_result!.model}...',
            ),
          ),
        );
      },
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text('Drop or click to upload', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('DME equipment or wound care supplies', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imageBytes,
    required this.fileName,
    required this.preset,
  });

  final Uint8List imageBytes;
  final String? fileName;
  final AiScanPreset? preset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (preset != null)
          Container(
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  switch (preset!) {
                    AiScanPreset.invacareWheelchair => Icons.accessible,
                    AiScanPreset.driveRollator => Icons.directions_walk,
                    AiScanPreset.woundDressingKit => Icons.healing,
                    AiScanPreset.oxygenConcentrator => Icons.air,
                  },
                  size: 72,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text('Simulated scan', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(imageBytes, fit: BoxFit.cover),
          ),
        Positioned(
          left: 12,
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fileName ?? 'uploaded_image.jpg',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisOverlay extends StatelessWidget {
  const _AnalysisOverlay({
    required this.step,
    this.expanded = false,
  });

  final String step;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(expanded ? 24 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text('GPT-4o Vision analyzing...', style: Theme.of(context).textTheme.titleSmall),
            if (step.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(step, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
