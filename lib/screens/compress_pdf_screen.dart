import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'process_media_screen.dart';
import 'package:path/path.dart' as p;

class CompressPdfScreen extends StatefulWidget {
  // KOREKSI CONSTRUCTOR: Menampung kiriman parameter data dari HomeScreen
  final bool isPremium;
  final Future<void> Function(String type, Map<String, dynamic> result)
      onCompressionSuccess;

  const CompressPdfScreen({
    super.key,
    required this.isPremium,
    required this.onCompressionSuccess,
  });

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  int _selectedQuality = 1;
  File? _selectedPdf;
  String _fileSizeText = 'Ukuran Asli: -';

  static const int maxPdfSizeMB = 100;

  /// KOREKSI: Menggunakan izin penyimpanan dokumen yang benar
  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return true;
      }
      return true;
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal meminta izin: $e');
      }
      return false;
    }
  }

  bool _validatePdfFile(File file) {
    try {
      if (!file.existsSync()) {
        _showErrorDialog(
          'File Error',
          'File tidak ditemukan atau sudah dihapus.',
        );
        return false;
      }

      String extension =
          p.extension(file.path).toLowerCase().replaceAll('.', '');
      if (extension.isEmpty) {
        extension = file.path.split('.').last.toLowerCase();
      }

      if (extension != 'pdf') {
        _showErrorDialog(
          'Format Tidak Didukung',
          'File harus berformat PDF. File Anda: $extension',
        );
        return false;
      }

      int fileSizeBytes = file.lengthSync();
      double fileSizeMB = fileSizeBytes / (1024 * 1024);

      if (fileSizeBytes <= 0) {
        _showErrorDialog('File Error', 'File kosong atau tidak valid.');
        return false;
      }

      if (fileSizeMB > maxPdfSizeMB) {
        _showErrorDialog(
          'File Terlalu Besar',
          'Ukuran file maksimal adalah ${maxPdfSizeMB}MB. File Anda ${fileSizeMB.toStringAsFixed(2)}MB.',
        );
        return false;
      }

      return true;
    } catch (e) {
      _showErrorDialog('Validasi Error', 'Terjadi error saat validasi: $e');
      return false;
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      final hasPermission = await _requestStoragePermission();

      if (hasPermission) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          File file = File(result.files.single.path!);

          if (_validatePdfFile(file)) {
            setState(() {
              _selectedPdf = file;
              double sizeInMB = file.lengthSync() / (1024 * 1024);
              _fileSizeText = 'Ukuran Asli: ${sizeInMB.toStringAsFixed(2)} MB';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal memilih PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String fileName =
        _selectedPdf != null ? p.basename(_selectedPdf!.path) : '';
    if (fileName.isEmpty && _selectedPdf != null) {
      fileName = _selectedPdf!.path.split(Platform.isWindows ? '\\' : '/').last;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PILIH DOKUMEN PDF',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickPdf,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedPdf != null
                    ? const Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 60,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'PILIH PDF\nDARI FILE MANAGER',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    _fileSizeText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedPdf != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Nama: $fileName',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 10),
                  RadioListTile<int>(
                    title: const Text('Kompresi Standar'),
                    value: 1,
                    groupValue: _selectedQuality,
                    onChanged: (v) => setState(() => _selectedQuality = v!),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedPdf == null) {
                    _showErrorDialog(
                      'Peringatan',
                      'Silakan pilih file PDF terlebih dahulu.',
                    );
                    return;
                  }

                  if (!_validatePdfFile(_selectedPdf!)) {
                    return;
                  }

                  try {
                    final File? compressedFile = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProcessMediaScreen(
                          file: _selectedPdf!,
                          q: _selectedQuality,
                          type: 'PDF',
                        ),
                      ),
                    );
                    if (compressedFile == null) return;
                    if (mounted) {
                      Navigator.pop(context, {
                        'original': _selectedPdf!,
                        'compressed': compressedFile,
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorDialog('Error', 'Gagal memulai kompresi: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: const Text(
                  '[ MULAI KOMPRES ]',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
