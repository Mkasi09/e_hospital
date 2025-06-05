import 'package:flutter/material.dart';

class FilesAndPrescriptionsScreen extends StatefulWidget {
  const FilesAndPrescriptionsScreen({super.key});

  @override
  State<FilesAndPrescriptionsScreen> createState() => _FilesAndPrescriptionsScreenState();
}

class _FilesAndPrescriptionsScreenState extends State<FilesAndPrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _files = [
    {'title': 'Blood Test Report', 'date': '2025-03-10'},
    {'title': 'X-Ray Results', 'date': '2025-04-01'},
    {'title': 'Prescription - Dr. Smith', 'date': '2025-05-15'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addFile() {
    setState(() {
      _files.add({
        'title': 'New File ${_files.length + 1}',
        'date': DateTime.now().toIso8601String().split('T').first,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File added successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files & Prescriptions'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            return _buildCard(
              title: file['title']!,
              date: file['date']!,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String date}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Date: $date'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle file opening or download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening "$title"...')),
          );
        },
      ),
    );
  }
}
