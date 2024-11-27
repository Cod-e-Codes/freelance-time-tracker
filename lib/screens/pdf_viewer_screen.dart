import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerScreen extends StatelessWidget {
  final String filePath;

  const PDFViewerScreen({required this.filePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Viewer"),
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
