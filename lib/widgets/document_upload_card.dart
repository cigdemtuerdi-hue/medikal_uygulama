import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isUploaded,
    this.fileName,
    this.isRequired = true,
    this.onPickFromGallery,
    this.onPickFromCamera,
    this.onPickFile,
    this.onPickVideo,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isUploaded;
  final String? fileName;
  final bool isRequired;
  final VoidCallback? onPickFromGallery;
  final VoidCallback? onPickFromCamera;
  final VoidCallback? onPickFile;
  final VoidCallback? onPickVideo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warningAmber
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                loc.t('common.required'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.warningAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppTheme.accentTeal.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploaded
                      ? AppTheme.accentTeal.withValues(alpha: 0.35)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isUploaded
                        ? Icons.check_circle_outline
                        : Icons.upload_file_outlined,
                    color: isUploaded
                        ? AppTheme.accentTeal
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isUploaded
                          ? (fileName ?? loc.t('common.fileUploaded'))
                          : loc.t('common.noFileSelected'),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onPickFromGallery != null)
                  OutlinedButton.icon(
                    onPressed: onPickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(loc.t('common.gallery')),
                  ),
                if (onPickFromCamera != null)
                  OutlinedButton.icon(
                    onPressed: onPickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(loc.t('common.camera')),
                  ),
                if (onPickFile != null)
                  OutlinedButton.icon(
                    onPressed: onPickFile,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(loc.t('common.pdfImage')),
                  ),
                if (onPickVideo != null)
                  OutlinedButton.icon(
                    onPressed: onPickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(loc.t('common.selectVideo')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
