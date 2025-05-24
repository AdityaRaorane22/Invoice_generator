import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoiceData {
  final String queryId;
  final String customerName;
  final String customerAddress;
  final String companyName;
  final List<Map<String, dynamic>> products;
  final String warrantyStatus;
  final DateTime generatedDate;
  final String? invoiceNumber; // Will be set by backend

  InvoiceData({
    required this.queryId,
    required this.customerName,
    required this.customerAddress,
    required this.companyName,
    required this.products,
    required this.warrantyStatus,
    required this.generatedDate,
    this.invoiceNumber,
  });
}

class InvoiceGenerator {
  static const double taxRate = 0.10; // 10% tax rate
  static const String companyLogo = 'TechServ Solutions';
  static const String companySlogan = 'Excellence in Technology Services';

  Future<String> getNextInvoiceNumber(String companyName) async {
    const String apiUrl = 'http://localhost:3000/api/invoices/next-number'; // Replace with your backend URL
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'companyName': companyName}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['invoiceNumber'];
      } else {
        throw Exception('Failed to get invoice number');
      }
    } catch (e) {
      print('Error getting invoice number: $e');
      // Fallback to timestamp-based number if API fails
      final dateStr = DateFormat('ddMMyyyy').format(DateTime.now());
      return '$companyName/$dateStr/001';
    }
  }

  Future<void> generatePDF(InvoiceData data) async {
    // Get invoice number from backend
    final invoiceNumber = await getNextInvoiceNumber(data.companyName);
    
    final pdf = pw.Document();
    
    // Calculate totals
    final subtotal = data.products.fold(0.0, (sum, product) => 
      sum + (product['price'] * product['quantity'])
    );
    final taxAmount = subtotal * taxRate;
    final total = subtotal + taxAmount;
    
    // Format dates
    final dateFormatter = DateFormat('MMMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    // Split products into chunks that fit on pages
    const int maxProductsPerPage = 10; // Adjust based on your needs
    final List<List<Map<String, dynamic>>> productChunks = [];
    
    for (int i = 0; i < data.products.length; i += maxProductsPerPage) {
      final end = (i + maxProductsPerPage < data.products.length) 
          ? i + maxProductsPerPage 
          : data.products.length;
      productChunks.add(data.products.sublist(i, end));
    }

    // First page with header and first chunk of products
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            _buildHeader(data, invoiceNumber),
            pw.SizedBox(height: 20),
            
            // Invoice Details Section
            _buildInvoiceDetails(data, dateFormatter, timeFormatter),
            pw.SizedBox(height: 20),
            
            // Customer Information Section
            _buildCustomerInfo(data),
            pw.SizedBox(height: 20),
            
            // First chunk of products
            _buildProductTableChunk(productChunks[0], true, 
              productChunks.length == 1 ? subtotal : null,
              productChunks.length == 1 ? taxAmount : null,
              productChunks.length == 1 ? total : null,
              1, productChunks.length),
            
            // Add warranty info and footer only on last page
            if (productChunks.length == 1) ...[
              pw.SizedBox(height: 20),
              _buildWarrantyInfo(data),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          ];
        },
        footer: (pw.Context context) {
          return _buildPageFooter(context);
        },
      ),
    );

    // Additional pages for remaining product chunks
    for (int i = 1; i < productChunks.length; i++) {
      final isLastChunk = i == productChunks.length - 1;
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Continuation header
              _buildContinuationHeader(invoiceNumber),
              pw.SizedBox(height: 20),
              
              // Product chunk
              _buildProductTableChunk(productChunks[i], false,
                isLastChunk ? subtotal : null,
                isLastChunk ? taxAmount : null,
                isLastChunk ? total : null,
                i + 1, productChunks.length),
              
              // Add warranty info and footer only on last page
              if (isLastChunk) ...[
                pw.SizedBox(height: 20),
                _buildWarrantyInfo(data),
                pw.SizedBox(height: 20),
                _buildFooter(),
              ],
            ];
          },
          footer: (pw.Context context) {
            return _buildPageFooter(context);
          },
        ),
      );
    }

    // Generate PDF bytes
    final Uint8List pdfBytes = await pdf.save();
    
    // Download PDF in web browser
    await _downloadPDF(pdfBytes, 'Invoice_$invoiceNumber.pdf');
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

  pw.Widget _buildContinuationHeader(String invoiceNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Invoice Continued',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Text(
            invoiceNumber,
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.blue600,
              fontWeight: pw.FontWeight.bold,
            ),
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

  pw.Widget _buildProductTableChunk(
    List<Map<String, dynamic>> products, 
    bool isFirstChunk,
    double? subtotal,
    double? taxAmount,
    double? total,
    int chunkNumber,
    int totalChunks,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          isFirstChunk ? 'Service Details' : 'Service Details (continued)',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        if (totalChunks > 1) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            'Page $chunkNumber of $totalChunks',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
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
            // Header row (show on every chunk)
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue100),
              children: [
                _buildTableCell('Product/Service', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Unit Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Data rows for this chunk
            ...products.map((product) => pw.TableRow(
              children: [
                _buildTableCell(product['name']),
                _buildTableCell('${product['quantity']}'),
                _buildTableCell('\$${product['price'].toStringAsFixed(2)}'),
                _buildTableCell('\$${(product['price'] * product['quantity']).toStringAsFixed(2)}'),
              ],
            )).toList(),
            
            // Add totals only on the last chunk
            if (subtotal != null && taxAmount != null && total != null) ...[
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