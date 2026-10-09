import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/order.dart';

class InvoicePdfService {
  static Future<pw.Document> build(AppOrder order) async {
    final doc = pw.Document();
    final dateStr =
        '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';
    final timeStr =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BuildMart',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Construction Materials Marketplace',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'support@buildmart.example | +91-00000-00000',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.orange50,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Status: ${orderStatusLabel(order.status)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE DETAILS',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Invoice No: ${order.id.toUpperCase()}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Date: $dateStr   Time: $timeStr',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Payment: ${order.paymentMethod == PaymentMethod.cod ? "Cash on Delivery" : "Online"}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        if (order.selfArrangedTransport)
                          pw.Text(
                            'Transport: Arranged by customer',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          order.buyerName,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          order.buyerPhone,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '${order.addressLine}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '${order.city}, ${order.state} - ${order.pincode}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              pw.Container(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 6,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Unit Price',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Qty',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              ...order.items.map(
                (item) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 6,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Rs ${item.unitPrice.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity} ${item.unit}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Rs ${item.lineTotal.toStringAsFixed(0)}',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 14),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _row('Subtotal', order.subtotal),
                      _row(
                        'Transport Fee',
                        order.selfArrangedTransport ? 0 : order.transportFee,
                      ),
                      _row('Platform Fee', order.platformFee),
                      _row('Tax', order.tax),
                      pw.Divider(color: PdfColors.grey400),
                      _row('Total', order.total, bold: true),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 28),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'This bill generated is not required signature',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with BuildMart!',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _row(String label, double value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: bold ? 11 : 10,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('Rs ${value.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
