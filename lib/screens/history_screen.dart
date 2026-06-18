import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _history = prefs.getStringList('history') ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat riwayat: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    if (mounted) {
      setState(() {
        _history = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua riwayat berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'RIWAYAT KOMPRESI',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: "Hapus Semua",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Hapus Riwayat"),
                    content: const Text(
                      "Apakah Anda yakin ingin menghapus semua daftar riwayat kompresi?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAllHistory();
                        },
                        child: const Text(
                          "Hapus",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _history.isEmpty
          ? const Center(
              child: Text(
                'Belum ada riwayat kompresi.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                try {
                  final item = jsonDecode(_history[index]);

                  double before = (item['before'] ?? 0) / (1024 * 1024);
                  double after = (item['after'] ?? 0) / (1024 * 1024);
                  String type = item['type'] ?? 'Media';

                  String dateText = '';
                  if (item['date'] != null) {
                    dateText = item['date'].toString().substring(0, 10);
                  }

                  IconData typeIcon = Icons.insert_drive_file;
                  Color iconColor = Colors.blue;

                  if (type.toLowerCase().contains('foto')) {
                    typeIcon = Icons.image;
                    iconColor = Colors.green;
                  } else if (type.toLowerCase().contains('video')) {
                    typeIcon = Icons.video_collection;
                    iconColor = Colors.orange;
                  } else if (type.toLowerCase().contains('pdf')) {
                    typeIcon = Icons.picture_as_pdf;
                    iconColor = Colors.red;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(typeIcon, color: iconColor, size: 28),
                      ),
                      title: Text(
                        type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${before.toStringAsFixed(2)} MB → ${after.toStringAsFixed(2)} MB',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (dateText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  dateText,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          before > 0
                              ? '-${((before - after) / before * 100).toStringAsFixed(0)}%'
                              : '0%',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              },
            ),
    );
  }
}
