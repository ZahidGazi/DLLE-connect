import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../screens/event_model.dart';
import '../screens/data_service.dart';

class CertificateService {

  static Future<void> generateCertificate(EventItem event) async {
    final pdf = pw.Document();

    // 1. Load the Template Image
    final image = await imageFromAssetBundle('assets/certificate_template.jpeg');

    // 2. Get Student Data
    final studentName = DataService.instance.studentName;
    final date = DateTime.now().toString().split(' ')[0]; // Simple YYYY-MM-DD

    pdf.addPage(
      pw.Page(
        // Set page size to match your image aspect ratio (A4 Landscape usually)
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Layer 1: The Template Image (Full Screen)
              pw.Positioned.fill(
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),

              // Layer 2: Student Name (Adjust top/left to fit your design)
              pw.Positioned(
                top: 220, // ⬇ Move Down
                left: 0,
                right: 0, // Centering trick
                child: pw.Center(
                  child: pw.Text(
                    studentName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black, // Or your theme color
                    ),
                  ),
                ),
              ),

              // Layer 3: Event Name
              pw.Positioned(
                top: 290, // ⬇ Move lower than Name
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    "For completing: ${event.title}",
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
              ),

              // Layer 4: Date (Bottom Left usually)
              pw.Positioned(
                bottom: 60,
                left: 100,
                child: pw.Text(
                  "Date: $date",
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),

              // Layer 5: Hours (Bottom Right usually)
              pw.Positioned(
                bottom: 60,
                right: 100,
                child: pw.Text(
                  "Credits: ${event.hours} Hrs",
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 3. Open PDF Viewer
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}