import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/listing_photo_compressor.dart';

/// One photo the user has chosen, from pick through to upload.
///
/// [bytes] is the compressed image kept for the thumbnail; [uploadedPath] is
/// the `/api/uploads/...` path once the server has it. A photo with a null
/// [uploadedPath] and no [error] is still uploading.
class ListingPhotoDraft {
  ListingPhotoDraft({
    required this.bytes,
    required this.contentType,
    this.uploadedPath,
    this.error,
  });

  final Uint8List bytes;
  final String contentType;
  String? uploadedPath;
  String? error;

  bool get isUploaded => uploadedPath != null;
  bool get isPending => uploadedPath == null && error == null;
}

/// Picks, previews and reorders up to [maxPhotos] listing photos.
///
/// Upload is delegated to [onUpload] so this widget stays free of API details
/// and can be dropped into the sell flow later. Each photo uploads as soon as
/// it is picked rather than on submit: a donor with five photos on a slow
/// connection would otherwise stare at a frozen "Publish" button, and a failure
/// at that point would lose the whole form.
class ListingPhotoPicker extends StatefulWidget {
  const ListingPhotoPicker({
    super.key,
    required this.photos,
    required this.onChanged,
    required this.onUpload,
    this.maxPhotos = 5,
    this.enabled = true,
  });

  final List<ListingPhotoDraft> photos;
  final ValueChanged<List<ListingPhotoDraft>> onChanged;

  /// Returns the stored path, or throws with a message to show the user.
  final Future<String> Function(ListingPhotoDraft draft) onUpload;

  final int maxPhotos;
  final bool enabled;

  @override
  State<ListingPhotoPicker> createState() => _ListingPhotoPickerState();
}

class _ListingPhotoPickerState extends State<ListingPhotoPicker> {
  bool _picking = false;

  bool get _canAddMore =>
      widget.enabled &&
      !_picking &&
      widget.photos.length < widget.maxPhotos;

  Future<void> _pick() async {
    final loc = AppLocalizations.of(context);
    final remaining = widget.maxPhotos - widget.photos.length;
    if (remaining <= 0) return;

    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        // Required on web, where there is no file path to read from later.
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final selected = result.files.take(remaining).toList();
      if (result.files.length > remaining) {
        _showMessage(
          loc.t('photos.maxReached', {
            'max': widget.maxPhotos,
            'kept': remaining,
          }),
        );
      }

      for (final file in selected) {
        final raw = file.bytes;
        if (raw == null) {
          _showMessage(loc.t('photos.readFailed', {'name': file.name}));
          continue;
        }

        final CompressedPhoto compressed;
        try {
          compressed = await compressListingPhoto(raw);
        } catch (err) {
          _showMessage('${file.name}: $err');
          continue;
        }

        if (!mounted) return;
        final draft = ListingPhotoDraft(
          bytes: compressed.bytes,
          contentType: compressed.contentType,
        );
        widget.onChanged([...widget.photos, draft]);
        unawaited(_upload(draft));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _upload(ListingPhotoDraft draft) async {
    try {
      final path = await widget.onUpload(draft);
      draft
        ..uploadedPath = path
        ..error = null;
    } catch (err) {
      draft.error = '$err';
    }
    if (mounted) setState(() {});
  }

  void _remove(ListingPhotoDraft draft) {
    widget.onChanged(
      widget.photos.where((p) => !identical(p, draft)).toList(),
    );
  }

  void _retry(ListingPhotoDraft draft) {
    setState(() => draft.error = null);
    unawaited(_upload(draft));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final count = widget.photos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(loc.t('photos.title'), style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              loc.t('photos.count', {'count': count, 'max': widget.maxPhotos}),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          loc.t('photos.hint'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < widget.photos.length; i++)
              _PhotoTile(
                draft: widget.photos[i],
                isCover: i == 0,
                enabled: widget.enabled,
                onRemove: () => _remove(widget.photos[i]),
                onRetry: () => _retry(widget.photos[i]),
              ),
            if (count < widget.maxPhotos)
              _AddPhotoTile(
                busy: _picking,
                onTap: _canAddMore ? _pick : null,
              ),
          ],
        ),
      ],
    );
  }
}

const double _tileSize = 92;

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.draft,
    required this.isCover,
    required this.enabled,
    required this.onRemove,
    required this.onRetry,
  });

  final ListingPhotoDraft draft;
  final bool isCover;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final failed = draft.error != null;

    return Semantics(
      label: failed
          ? loc.t('photos.failedSemantic')
          : (isCover
              ? loc.t('photos.coverSemantic')
              : loc.t('photos.photoSemantic')),
      child: SizedBox(
        width: _tileSize,
        height: _tileSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(draft.bytes, fit: BoxFit.cover),
            ),
            if (draft.isPending)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (failed)
              _FailedOverlay(onRetry: enabled ? onRetry : null),
            if (isCover && !failed)
              Positioned(
                left: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDeepBlue.withValues(alpha: 0.82),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    loc.t('photos.cover'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            Positioned(
              top: -6,
              right: -6,
              child: IconButton(
                iconSize: 18,
                tooltip: loc.t('photos.remove'),
                onPressed: enabled ? onRemove : null,
                icon: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedOverlay extends StatelessWidget {
  const _FailedOverlay({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(
              alpha: 0.92,
            ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: IconButton(
          tooltip: loc.t('photos.retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 20),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.t('photos.add'),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
