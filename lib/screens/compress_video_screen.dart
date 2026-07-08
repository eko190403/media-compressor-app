import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'process_media_screen.dart';

class CompressVideoScreen extends StatefulWidget {
  // KOREKSI CONSTRUCTOR: Menambahkan parameter wajib agar sinkron dengan panggilan di HomeScreen
  final bool isPremium;
  final Future<void> Function(String type, Map<String, dynamic> result)
      onCompressionSuccess;

  const CompressVideoScreen({
    super.key,
    required this.isPremium,
    required this.onCompressionSuccess,
  });

  @override
  State<CompressVideoScreen> createState() => _CompressVideoScreenState();
}

class _CompressVideoScreenState extends State<CompressVideoScreen> {
  int _q = 1;
  File? _vid;
  String _size = 'Ukuran Asli: -';

  // Constants untuk validasi
  static const int maxVideoSizeMB = 500; // Maksimal 500MB
  static const List<String> validVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'flv',
    'wmv',
    '3gp',
  ];

  /// KOREKSI: Izin cerdas yang adaptif untuk video di semua versi Android
  Future<bool> _requestVideoPermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.videos.status;
        if (status.isDenied) {
          status = await Permission.videos.request();
        }

        // Fallback untuk Android 12 ke bawah yang belum mengenali Permission.videos
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

  /// Validasi file video
  bool _validateVideoFile(File file) {
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

      if (fileSizeMB > maxVideoSizeMB) {
        _showErrorDialog(
          'File Terlalu Besar',
          'Ukuran file maksimal adalah ${maxVideoSizeMB}MB. File Anda ${fileSizeMB.toStringAsFixed(2)}MB.',
        );
        return false;
      }

      String extension = file.path.split('.').last.toLowerCase();
      if (!validVideoFormats.contains(extension)) {
        _showErrorDialog(
          'Format Tidak Didukung',
          'Format $extension tidak didukung. Gunakan: ${validVideoFormats.join(", ")}',
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
      final hasPermission = await _requestVideoPermission();

      if (hasPermission) {
        final XFile? v = await ImagePicker().pickVideo(
          source: ImageSource.gallery,
        );
        if (v != null) {
          File f = File(v.path);

          if (_validateVideoFile(f)) {
            setState(() {
              _vid = f;
              double sizeInMB = f.lengthSync() / (1024 * 1024);
              _size = 'Ukuran Asli: ${sizeInMB.toStringAsFixed(2)} MB';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal memilih video: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String fileName =
        _vid != null ? Uri.parse(_vid!.path).pathSegments.last : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PILIH VIDEO',
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
                child: _vid != null
                    ? const Center(
                        child: Icon(
                          Icons.video_file,
                          color: Colors.blue,
                          size: 60,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'PILIH VIDEO DARI GALERI',
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
                  if (_vid != null)
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
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _q = value);
                      }
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('Ekstrem (Ukuran Super Kecil)'),
                    value: 2,
                    groupValue: _q,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _q = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  if (_vid == null) {
                    _showErrorDialog(
                      'Peringatan',
                      'Silakan pilih video terlebih dahulu.',
                    );
                    return;
                  }

                  if (!_validateVideoFile(_vid!)) {
                    return;
                  }

                  try {
                    final f = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProcessMediaScreen(
                          file: _vid!,
                          q: _q,
                          type: 'VIDEO',
                        ),
                      ),
                    );
                    if (f == null) return;
                    if (!mounted) return;
                    Navigator.pop(context, {
                      'original': _vid!,
                      'compressed': f,
                    });
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
