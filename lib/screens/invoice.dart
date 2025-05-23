import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:html' as html;

class InvoiceData {
  final String queryId;
  final String customerName;
  final String customerAddress;
  final String companyName;
  final String productName;
  final double productPrice;
  final String warrantyStatus;
  final DateTime generatedDate;

  InvoiceData({
    required this.queryId,
    required this.customerName,
    required this.customerAddress,
    required this.companyName,
    required this.productName,
    required this.productPrice,
    required this.warrantyStatus,
    required this.generatedDate,
  });
}

class InvoiceGenerator {
  static const double taxRate = 0.10; // 10% tax rate
  static const String companyLogo = 'TechServ Solutions';
  static const String companySlogan = 'Excellence in Technology Services';

  Future<void> generatePDF(InvoiceData data) async {
    final pdf = pw.Document();
    
    // Calculate totals
    final subtotal = data.productPrice;
    final taxAmount = subtotal * taxRate;
    final total = subtotal + taxAmount;
    
    // Format dates
    final dateFormatter = DateFormat('MMMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final invoiceNumber = 'INV-${DateFormat('yyyyMMdd').format(data.generatedDate)}-${data.queryId.substring(4, 8)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            _buildHeader(data, invoiceNumber),
            pw.SizedBox(height: 30),
            
            // Invoice Details Section
            _buildInvoiceDetails(data, dateFormatter, timeFormatter),
            pw.SizedBox(height: 30),
            
            // Customer Information Section
            _buildCustomerInfo(data),
            pw.SizedBox(height: 30),
            
            // Product Details Table
            _buildProductTable(data, subtotal, taxAmount, total),
            pw.SizedBox(height: 30),
            
            // Warranty Information
            _buildWarrantyInfo(data),
            pw.SizedBox(height: 30),
            
            // Footer with Legal Terms
            _buildFooter(),
          ];
        },
        footer: (pw.Context context) {
          return _buildPageFooter(context);
        },
      ),
    );

    // Generate PDF bytes
    final Uint8List pdfBytes = await pdf.save();
    
    // Download PDF in web browser
    await _downloadPDF(pdfBytes, 'Invoice_${invoiceNumber}.pdf');
  }

  pw.Widget _buildHeader(InvoiceData data, String invoiceNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyLogo,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                companySlogan,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blue600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                invoiceNumber,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.blue600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceDetails(InvoiceData data, DateFormat dateFormatter, DateFormat timeFormatter) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Query ID: ${data.queryId}'),
              pw.Text('Service Provider: ${data.companyName}'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated On',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${dateFormatter.format(data.generatedDate)}'),
              pw.Text('Time: ${timeFormatter.format(data.generatedDate)}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(InvoiceData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.customerName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.customerAddress,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductTable(InvoiceData data, double subtotal, double taxAmount, double total) {
    return pw.Column(
      children: [
        pw.Text(
          'Service Details',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                _buildTableCell('Product/Service', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Unit Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Data row
            pw.TableRow(
              children: [
                _buildTableCell(data.productName),
                _buildTableCell('1'),
                _buildTableCell('\$${data.productPrice.toStringAsFixed(2)}'),
                _buildTableCell('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            // Subtotal row
            pw.TableRow(
              children: [
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell('Subtotal:', isHeader: true),
                _buildTableCell('\$${subtotal.toStringAsFixed(2)}', isHeader: true),
              ],
            ),
            // Tax row
            pw.TableRow(
              children: [
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell('Tax (10%):', isHeader: true),
                _buildTableCell('\$${taxAmount.toStringAsFixed(2)}', isHeader: true),
              ],
            ),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell('TOTAL:', isHeader: true, fontSize: 14),
                _buildTableCell('\$${total.toStringAsFixed(2)}', isHeader: true, fontSize: 14),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, double fontSize = 12}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.grey700,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildWarrantyInfo(InvoiceData data) {
    final warrantyColor = data.warrantyStatus == 'Before' ? PdfColors.green : PdfColors.orange;
    final warrantyIcon = data.warrantyStatus == 'Before' ? '✓' : '⚠';
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: data.warrantyStatus == 'Before' ? PdfColors.green50 : PdfColors.orange50,
        border: pw.Border.all(color: warrantyColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            warrantyIcon,
            style: pw.TextStyle(
              fontSize: 20,
              color: warrantyColor,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Warranty Status',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: warrantyColor,
                ),
              ),
              pw.Text(
                '${data.warrantyStatus} Warranty Period',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: warrantyColor,
                ),
              ),
              if (data.warrantyStatus == 'Before')
                pw.Text(
                  'Service covered under manufacturer warranty',
                  style: const pw.TextStyle(fontSize: 10),
                )
              else
                pw.Text(
                  'Service performed after warranty expiration',
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms and Conditions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '1. Payment is due within 30 days of invoice date.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '2. Late payments may incur additional charges.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '3. All services are provided as per the agreed specifications.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '4. Warranty terms apply as per manufacturer guidelines.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            '5. This invoice is generated electronically and is valid without signature.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  Future<void> _downloadPDF(Uint8List pdfBytes, String filename) async {
    // Create blob and download in web browser
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}