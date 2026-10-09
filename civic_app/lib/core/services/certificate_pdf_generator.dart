import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../constants/app_constants.dart';
import '../models/certificate_model.dart';

/// Service for generating professional, Civic Precision PDF certificates with embedded QR codes.
class CertificatePdfGenerator {
  static const String defaultBaseUrl = AppConstants.publicBaseUrl;

  /// Generates the complete binary PDF bytes for a CivicCertificate.
  static Future<Uint8List> generateCertificatePdf({
    required CivicCertificate certificate,
    String baseUrl = defaultBaseUrl,
  }) async {
    final pdf = pw.Document();

    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final qrVerificationUrl = '$cleanBaseUrl/verify/${certificate.verificationSlug}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#1E3A8A'), // Civic Navy / Primary
                width: 3.5,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#D97706'), // Gold / Accent
                  width: 1.2,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Header & Organization Crest
                  pw.Column(
                    children: [
                      pw.Text(
                        'MUNICIPAL CIVIC GOVERNANCE  |  CIVICFIX RECOGNITION',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#4B5563'),
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'CERTIFICATE OF CIVIC RECOGNITION',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#1E3A8A'),
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      pw.Container(
                        height: 2,
                        width: 140,
                        margin: const pw.EdgeInsets.only(top: 4, bottom: 8),
                        color: PdfColor.fromHex('#D97706'),
                      ),
                    ],
                  ),

                  // 2. Recipient Information
                  pw.Column(
                    children: [
                      pw.Text(
                        'THIS IS PROUDLY PRESENTED TO',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#6B7280'),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        certificate.recipientDisplayName,
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#111827'),
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.ConstrainedBox(
                        constraints: const pw.BoxConstraints(maxWidth: 550),
                        child: pw.Text(
                          'In recognition of exemplary civic commitment, active community problem resolution, and earning the distinction of ${certificate.civicLevel} in the City of Mumbai.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#374151'),
                            fontSize: 10,
                            lineSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. Snapshot Metrics & Details
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricBox(
                        title: 'Civic Points',
                        value: '+${certificate.pointsAtIssue}',
                        colorHex: '#0D9488', // Teal
                      ),
                      _buildMetricBox(
                        title: 'Verified Reports',
                        value: '${certificate.verifiedComplaintsAtIssue}',
                        colorHex: '#2563EB', // Blue
                      ),
                      _buildMetricBox(
                        title: 'Resolved Grievances',
                        value: '${certificate.resolvedComplaintsAtIssue}',
                        colorHex: '#16A34A', // Green
                      ),
                    ],
                  ),

                  // 4. Footer with QR Code, Certificate ID, Date, and Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Left: QR Code & Verification
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 60,
                            height: 60,
                            padding: const pw.EdgeInsets.all(3),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: qrVerificationUrl,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Scan to Verify',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#111827'),
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'ID: ${certificate.certificateId}',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#6B7280'),
                                  fontSize: 7,
                                ),
                              ),
                              pw.Text(
                                'Issued: ${_formatDate(certificate.issuedAt)}',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#6B7280'),
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Right: Signatory & Seal
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 140,
                            height: 1,
                            color: PdfColor.fromHex('#9CA3AF'),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'CivicFix Municipal Board',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#111827'),
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Digital Verification Authority',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#6B7280'),
                              fontSize: 7,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricBox({
    required String title,
    required String value,
    required String colorHex,
  }) {
    return pw.Container(
      width: 130,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9FAFB'),
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColor.fromHex(colorHex),
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#6B7280'),
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
