import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FileViewerScreen extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final String fileExtension;

  const FileViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileExtension,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: fileExtension == 'pdf'
          ? SfPdfViewer.network(fileUrl)
          : InteractiveViewer(
        child: Center(
          child: Image.network(fileUrl),
        ),
      ),
    );
  }
}
