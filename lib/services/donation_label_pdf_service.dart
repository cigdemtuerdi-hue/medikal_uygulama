import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/delivery_models.dart';
import 'delivery_service.dart';
import 'donation_service.dart';
import 'pdf_saver.dart';

/// Builds the printable MedGift donation label: brand header with the
/// heart logo, item details, and a delivery-confirmation QR code.
class DonationLabelPdfService {
  DonationLabelPdfService._();

  static final DonationLabelPdfService instance = DonationLabelPdfService._();

  static const _deepBlue = PdfColor.fromInt(0xFF0D47A1);
  static const _lightBlue = PdfColor.fromInt(0xFF64B5F6);
  static const _paleBlue = PdfColor.fromInt(0xFFF2F7FD);

  Future<String> downloadLabel(DonationLabelData label) async {
    final bytes = await buildLabelPdf(label);
    return PdfSaver.save(bytes, label.pdfFileName);
  }

  Future<Uint8List> buildLabelPdf(DonationLabelData label) async {
    final doc = pw.Document();

    // 4x6 inch shipping-label format, printable on standard label paper.
    const pageFormat = PdfPageFormat(
      4 * PdfPageFormat.inch,
      6 * PdfPageFormat.inch,
      marginAll: 18,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _deepBlue, width: 1.5),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _brandHeader(),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text(
                      label.title,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _deepBlue,
                      ),
                    ),
                    if (label.brand != null || label.model != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          [label.brand, label.model]
                              .whereType<String>()
                              .join(' - '),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 8),
                    _detailRow('Item ID', label.itemId),
                    _detailRow('Category', label.categoryLabel),
                    _detailRow('Condition', label.conditionLabel),
                    _detailRow('Quantity', '${label.quantity}'),
                    _detailRow('Donor area', label.donorAreaLabel),
                    _detailRow('Listed', formatDonationDate(DateTime.now())),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 14),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _paleBlue,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _lightBlue, width: 0.75),
                ),
                child: pw.Row(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: DeliveryService.qrPayloadFor(label.itemId),
                      width: 110,
                      height: 110,
                      color: _deepBlue,
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DELIVERY CONFIRMATION',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _deepBlue,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Recipient: scan this QR code with the MedGift '
                            'app at handoff to confirm you received the item.',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              lineSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  'MedGift US - medgift.us - Charitable equipment donation program',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _brandHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: _deepBlue,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
        ),
      ),
      child: pw.Row(
        children: [
          _heartLogo(28),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MedGift US',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'DONATION LABEL',
                style: const pw.TextStyle(
                  color: _lightBlue,
                  fontSize: 8,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// White heart drawn with bezier curves inside a light-blue rounded tile.
  pw.Widget _heartLogo(double size) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(size * 0.22),
      ),
      child: pw.Center(
        child: pw.CustomPaint(
          size: PdfPoint(size * 0.62, size * 0.58),
          painter: (canvas, pdfSize) {
            final w = pdfSize.x;
            final h = pdfSize.y;
            // Heart: bottom tip -> left lobe -> center notch -> right lobe.
            canvas
              ..setFillColor(PdfColors.white)
              ..moveTo(w / 2, 0)
              ..curveTo(-w * 0.20, h * 0.55, w * 0.15, h * 1.15, w / 2, h * 0.72)
              ..curveTo(w * 0.85, h * 1.15, w * 1.20, h * 0.55, w / 2, 0)
              ..fillPath();
          },
        ),
      ),
    );
  }

  pw.Widget _detailRow(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              key,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
          ),
        ],
      ),
    );
  }
}
