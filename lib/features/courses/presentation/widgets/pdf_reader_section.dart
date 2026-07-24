import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Streams a lesson's PDF resource. `SfPdfViewer.network` handles
/// progressive loading itself; if `localFilePath` is provided, we load the
/// cached PDF from local storage using `SfPdfViewer.file` for offline support.
class PdfReaderSection extends StatefulWidget {
  const PdfReaderSection({
    super.key,
    required this.pdfUrl,
    this.localFilePath,
  });

  final String pdfUrl;
  final String? localFilePath;

  @override
  State<PdfReaderSection> createState() => _PdfReaderSectionState();
}

class _PdfReaderSectionState extends State<PdfReaderSection> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 420,
        decoration: BoxDecoration(
          color: AppColors.glassFillLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: const Text(
          'PDF unavailable offline',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final localPath = widget.localFilePath;
    final useLocal = localPath != null && localPath.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 420,
        child: useLocal
            ? SfPdfViewer.file(
                File(localPath),
                canShowScrollHead: true,
                canShowScrollStatus: true,
                onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                  setState(() {
                    _hasError = true;
                  });
                },
              )
            : SfPdfViewer.network(
                widget.pdfUrl,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                  setState(() {
                    _hasError = true;
                  });
                },
              ),
      ),
    );
  }
}
