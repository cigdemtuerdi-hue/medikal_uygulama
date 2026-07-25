import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/donation_models.dart';
import '../models/exchange_models.dart';
import 'ai_vision_service.dart';
import 'donation_service.dart';
import 'pdf_saver.dart';

/// Builds official-style 501(c)(3) tax receipt PDFs and saves/downloads them.
class TaxReceiptPdfService {
  TaxReceiptPdfService._();

  static final TaxReceiptPdfService instance = TaxReceiptPdfService._();

  static const _deepBlue = PdfColor.fromInt(0xFF0D47A1);
  static const _lightBlue = PdfColor.fromInt(0xFF64B5F6);

  /// Generates the PDF for an exchange receipt and triggers download/save.
  Future<String> downloadExchangeReceipt(ExchangeTaxReceipt receipt) async {
    final bytes = await buildExchangeReceiptPdf(receipt);
    return PdfSaver.save(bytes, receipt.pdfFileName);
  }

  /// Generates the PDF for a regular donation-history receipt and
  /// triggers download/save.
  Future<String> downloadDonationReceipt(DonationRecord record) async {
    final bytes = await buildDonationReceiptPdf(record);
    return PdfSaver.save(bytes, '${record.receiptNumber}.pdf');
  }

  Future<Uint8List> buildExchangeReceiptPdf(ExchangeTaxReceipt receipt) {
    final asset = receipt.asset;
    return _buildReceiptPdf(
      receiptNumber: receipt.receiptNumber,
      issuedAt: receipt.issuedAt,
      donorLines: [
        _kv('Name', receipt.donor.name),
        _kv('Email', receipt.donor.email),
        _kv('Location', receipt.donor.location),
      ],
      receiverTitle: 'RECEIVING PARTY (VIA MEDGIFT US 501(c)(3) PROGRAM)',
      receiverLines: [
        _kv('Name', receipt.recipient.name),
        _kv('Location', receipt.recipient.location),
        _kv('Facilitator', 'MedGift US - IRC Section 501(c)(3)'),
        _kv('Exchange ID', receipt.exchangeId),
      ],
      itemRows: [
        ['Item', asset.title],
        ['Asset ID', asset.assetId],
        if (asset.brand != null) ['Brand', asset.brand!],
        if (asset.model != null) ['Model', asset.model!],
        ['Category', DonationService.categoryLabel(asset.category)],
        ['Condition', conditionLabel(asset.condition)],
        ['Quantity', '${asset.quantity}'],
        ['Fair Market Value', formatUsd(asset.fairMarketValueUsd)],
      ],
      complianceNote:
          'This receipt documents property transferred through the MedGift US '
          'equipment exchange program. No goods or services beyond the '
          'exchanged property were provided. The donor is responsible for '
          'determining fair market value per IRS Publication 561. Retain this '
          'receipt with your tax records.',
    );
  }

  Future<Uint8List> buildDonationReceiptPdf(DonationRecord record) {
    final donor = DonationService.donorProfile;
    return _buildReceiptPdf(
      receiptNumber: record.receiptNumber,
      issuedAt: record.donatedAt,
      donorLines: [
        _kv('Name', donor.name),
        _kv('Email', donor.email),
        _kv('ZIP', donor.zipCode),
      ],
      receiverTitle: 'QUALIFYING 501(c)(3) ORGANIZATION',
      receiverLines: [
        _kv('Organization', record.organizationName),
        _kv('EIN', record.organizationEin),
        _kv('IRS Status', 'Tax-exempt under IRC Section 501(c)(3)'),
      ],
      itemRows: [
        ['Item', record.title],
        if (record.brand != null) ['Brand', record.brand!],
        if (record.model != null) ['Model', record.model!],
        ['Category', DonationService.categoryLabel(record.category)],
        ['Condition', conditionLabel(record.condition)],
        ['Quantity', '${record.quantity}'],
        ['Fair Market Value (Est. Retail)', formatUsd(record.estimatedRetailValueUsd)],
        ['Tax-Deductible Amount', formatUsd(record.taxDeductionUsd)],
      ],
      complianceNote:
          'No goods or services were provided in exchange for this donation. '
          'The donor is responsible for determining the fair market value per '
          'IRS Publication 561. Retain this receipt for your tax records.',
    );
  }

  Future<Uint8List> _buildReceiptPdf({
    required String receiptNumber,
    required DateTime issuedAt,
    required List<List<String>> donorLines,
    required String receiverTitle,
    required List<List<String>> receiverLines,
    required List<List<String>> itemRows,
    required String complianceNote,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(receiptNumber, issuedAt),
            pw.SizedBox(height: 24),
            _section('DONOR INFORMATION', donorLines),
            pw.SizedBox(height: 16),
            _section(receiverTitle, receiverLines),
            pw.SizedBox(height: 16),
            _sectionTitle('DONATED PROPERTY'),
            pw.SizedBox(height: 8),
            _itemTable(itemRows),
            pw.SizedBox(height: 20),
            _sectionTitle('IRS COMPLIANCE NOTE'),
            pw.SizedBox(height: 8),
            pw.Text(
              complianceNote,
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 3),
            ),
            pw.Spacer(),
            pw.Divider(color: _lightBlue),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MedGift US - medgift.us - support@medgift.us',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Generated ${formatDonationDate(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _header(String receiptNumber, DateTime issuedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _deepBlue,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MedGift US',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'CHARITABLE DONATION TAX RECEIPT - 501(c)(3)',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                receiptNumber,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Date: ${formatDonationDate(issuedAt)} - Tax Year ${issuedAt.year}',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _deepBlue,
      ),
    );
  }

  pw.Widget _section(String title, List<List<String>> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        pw.SizedBox(height: 8),
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    line[0],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(line[1], style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _itemTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _lightBlue, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(170),
        1: pw.FlexColumnWidth(),
      },
      children: [
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? const PdfColor.fromInt(0xFFF2F7FD) : PdfColors.white,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Text(
                  rows[i][0],
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Text(rows[i][1], style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
      ],
    );
  }

  static List<String> _kv(String key, String value) => [key, value];
}
