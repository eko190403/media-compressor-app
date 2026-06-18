import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'process_media_screen.dart';

class CompressPhotoScreen extends StatefulWidget {
  // KOREKSI CONSTRUCTOR: Menampung kiriman parameter data dari Beranda utama
  final bool isPremium;
  final Future<void> Function(String type, Map<String, dynamic> result)
      onCompressionSuccess;

  const CompressPhotoScreen({
    super.key,
    required this.isPremium,
    required this.onCompressionSuccess,
  });

  @override
  State<CompressPhotoScreen> createState() => _CompressPhotoScreenState();
}

class _CompressPhotoScreenState extends State<CompressPhotoScreen> {
  int _q = 1;
  File? _img;
  String _size = 'Ukuran Asli: -';

  static const int maxPhotoSizeMB = 50;
  static const List<String> validPhotoFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
  ];

  Future<bool> _requestPhotoPermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
        }

        if (status.isDenied) {
          var storageStatus = await Permission.storage.request();
          if (storageStatus.isPermanentlyDenied) {
            openAppSettings();
            return false;
          }
          return storageStatus.isGranted;
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

  bool _validatePhotoFile(File file) {
    try {
      if (!file.existsSync()) {
        _showErrorDialog(
          'File Error',
          'File tidak ditemukan atau sudah dihapus.',
        );
        return false;
      }

      int fileSizeBytes = file.lengthSync();
      double fileSizeMB = fileSizeBytes / (1024 * 1024);

      if (fileSizeBytes <= 0) {
        _showErrorDialog('File Error', 'File kosong atau tidak valid.');
        return false;
      }

      if (fileSizeMB > maxPhotoSizeMB) {
        _showErrorDialog(
          'File Terlalu Besar',
          'Ukuran file maksimal adalah ${maxPhotoSizeMB}MB. File Anda ${fileSizeMB.toStringAsFixed(2)}MB.',
        );
        return false;
      }

      String extension = file.path.split('.').last.toLowerCase();
      if (!validPhotoFormats.contains(extension)) {
        _showErrorDialog(
          'Format Tidak Didukung',
          'Format $extension tidak didukung. Gunakan: ${validPhotoFormats.join(", ")}',
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

  Future<void> _pick() async {
    try {
      final hasPermission = await _requestPhotoPermission();

      if (hasPermission) {
        final XFile? i = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (i != null) {
          File f = File(i.path);

          if (_validatePhotoFile(f)) {
            setState(() {
              _img = f;
              double sizeInMB = f.lengthSync() / (1024 * 1024);
              _size = 'Ukuran Asli: ${sizeInMB.toStringAsFixed(2)} MB';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal memilih foto: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String fileName =
        _img != null ? Uri.parse(_img!.path).pathSegments.last : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PILIH FOTO',
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
              onTap: _pick,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _img != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_img!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Text(
                          'PILIH FOTO DARI GALERI',
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
                    _size,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_img != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Nama: $fileName',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 10),
                  RadioListTile<int>(
                    title: const Text('Normal (Kualitas Terjaga)'),
                    value: 1,
                    groupValue: _q,
                    onChanged: (v) => setState(() => _q = v!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Ekstrem (Ukuran Super Kecil)'),
                    value: 2,
                    groupValue: _q,
                    onChanged: (v) => setState(() => _q = v!),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  if (_img == null) {
                    _showErrorDialog(
                      'Peringatan',
                      'Silakan pilih foto terlebih dahulu.',
                    );
                    return;
                  }

                  if (!_validatePhotoFile(_img!)) {
                    return;
                  }

                  try {
                    final f = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProcessMediaScreen(
                          file: _img!,
                          q: _q,
                          type: 'FOTO',
                        ),
                      ),
                    );
                    if (f == null) return;
                    if (mounted) {
                      Navigator.pop(context, {
                        'original': _img!,
                        'compressed': f,
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
