import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class DocumentsTab extends StatefulWidget {
  const DocumentsTab({super.key});

  @override
  DocumentsTabState createState() => DocumentsTabState();
}

class DocumentsTabState extends State<DocumentsTab> {
  final List<File> _documents = [];

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);

      // Copy the picked file to the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final newFile = await file.copy('${appDir.path}/${file.uri.pathSegments.last}');

      setState(() {
        _documents.add(newFile);
      });
    }
  }

  Future<void> _deleteDocument(int index) async {
    final file = _documents[index];
    await file.delete();
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _openDocument(File document) async {
    await OpenFile.open(document.path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload and Manage Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(  // Center the button
            child: ElevatedButton(
              onPressed: _pickDocument,
              child: const Text('Upload Document'),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _documents.isEmpty
                ? const Center(child: Text('No documents uploaded yet.'))
                : ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final document = _documents[index];
                return ListTile(
                  title: Text(document.uri.pathSegments.last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDocument(index),
                  ),
                  onTap: () {
                    _openDocument(document);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
