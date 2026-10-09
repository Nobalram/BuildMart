import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/invoice_pdf_service.dart';
import '../../models/order.dart';

class InvoiceScreen extends StatelessWidget {
  final AppOrder order;

  const InvoiceScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: PdfPreview(
        build: (format) async {
          final doc = await InvoicePdfService.build(order);
          return doc.save();
        },
        allowSharing: true,
        allowPrinting: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'BuildMart_Invoice_${order.id.substring(0, 8)}.pdf',
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: AppColors.surface,
          iconColor: AppColors.primary,
        ),
      ),
    );
  }
}
