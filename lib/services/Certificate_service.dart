import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../screens/event_model.dart';
import '../screens/data_service.dart';

class CertificateService {
  // ── Page dimensions match the template image exactly (1280 × 902 px → pt) ──
  static const double _pageWidth = 1280;
  static const double _pageHeight = 902;

  // ── Font sizes ──
  static const double _nameFontSize = 30;
  static const double _detailFontSize = 22;

  // ── Name: center coordinate on the image ──
  static const double _nameCenterY = 424;

  // ── Class, Event, Date: top-left starting coordinates ──
  static const double _classLeft = 676;
  static const double _classTop = 464.45;
  static const double _eventLeft = 567;
  static const double _eventTop = 504.15;
  static const double _dateLeft = 539;
  static const double _dateTop = 624;

  // ── Colors ──
  // Dark maroon/red for the student name (matches certificate design)
  static const PdfColor _nameColor = PdfColor(0.545, 0.102, 0.102);
  static const PdfColor _textColor = PdfColor(0.2, 0.184, 0.161);

  // ── Date formatter: "6th September 2024" ──
  static String _formatDate(DateTime date) {
    final day = date.day;
    final String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '$day$suffix ${months[date.month - 1]} ${date.year}';
  }

  /// Generates the certificate PDF and opens the system share/save sheet.
  static Future<void> generateAndDownload(EventItem event) async {
    final pdf = pw.Document();

    // 1. Load the template image from assets
    final imageBytes =
        await rootBundle.load('assets/certificate_template.jpeg');
    final templateImage =
        pw.MemoryImage(imageBytes.buffer.asUint8List());

    // 2. Gather student data
    final studentName = DataService.instance.studentName;
    final studentClass = DataService.instance.studentCourse;
    final eventName = event.title;
    final completionDate = event.completedAt ?? DateTime.now();
    final dateStr = _formatDate(completionDate);

    // 3. Build the PDF page
    pdf.addPage(
      pw.Page(
        // Custom page size matching the template image (1280 × 902 pt)
        pageFormat: PdfPageFormat(_pageWidth, _pageHeight),
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // ── Layer 1: Full-bleed template background ──
              pw.Positioned.fill(
                child: pw.Image(templateImage, fit: pw.BoxFit.fill),
              ),

              // ── Layer 2: Student Name — centered at (640, 424) ──
              // top = centerY - fontSize/2  →  424 - 15 = 409
              pw.Positioned(
                top: _nameCenterY - (_nameFontSize / 2),
                left: 0,
                right: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      studentName.toUpperCase(),
                      style: pw.TextStyle(
                        font: pw.Font.timesBold(),
                        fontSize: _nameFontSize,
                        color: _nameColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Layer 3: Class — left-aligned at (676, 475) ──
              pw.Positioned(
                top: _classTop,
                left: _classLeft,
                child: pw.Text(
                  studentClass.toUpperCase(),
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: _detailFontSize,
                    color: _textColor,
                  ),
                ),
              ),

              // ── Layer 4: Event Name — left-aligned at (567, 515) ──
              pw.Positioned(
                top: _eventTop,
                left: _eventLeft,
                child: pw.Text(
                  eventName.toUpperCase(),
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: _detailFontSize,
                    color: _textColor,
                  ),
                ),
              ),

              // ── Layer 5: Date — left-aligned at (539, 637) ──
              pw.Positioned(
                top: _dateTop,
                left: _dateLeft,
                child: pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: _detailFontSize,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 4. Save PDF bytes and open system share / save sheet
    final bytes = await pdf.save();
    final safeTitle = eventName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'DLLE_Certificate_$safeTitle.pdf',
    );
  }
}
