import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'process_media_screen.dart';

class CompressAudioScreen extends StatefulWidget {
  const CompressAudioScreen({super.key});

  @override
  State<CompressAudioScreen> createState() => _CompressAudioScreenState();
}

class _CompressAudioScreenState extends State<CompressAudioScreen> {
  int _q = 1; // 1 = Normal, 2 = Ekstrem
  File? _audioFile;
  String _sizeText = 'Ukuran Asli: -';

  // Batas maksimal ukuran audio (50 MB)
  static const int maxAudioSizeMB = 50;
  static const List<String> validAudioFormats = [
    'mp3',
    'm4a',
    'wav',
    'wma',
    'ogg',
    'aac',
  ];

  /// Amankan sistem izin akses storage khusus audio di Android/iOS
  Future<bool> _requestAudioPermission() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.audio.status;
        if (status.isDenied) {
          status = await Permission.audio.request();
        }

        // Fallback untuk Android 12 ke bawah yang belum mengenali Permission.audio
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
      _showErrorDialog('Error', 'Gagal meminta izin akses berkas: $e');
      return false;
    }
  }

  /// Jalur validasi kelayakan file audio
  bool _validateAudioFile(File file) {
    try {
      if (!file.existsSync()) {
        _showErrorDialog(
          'File Error',
          'Berkas audio tidak ditemukan atau sudah terhapus.',
        );
        return false;
      }

      int fileSizeBytes = file.lengthSync();
      double fileSizeMB = fileSizeBytes / (1024 * 1024);

      if (fileSizeBytes <= 0) {
        _showErrorDialog('File Error', 'Berkas audio kosong atau korup.');
        return false;
      }

      if (fileSizeMB > maxAudioSizeMB) {
        _showErrorDialog(
          'File Terlalu Besar',
          'Ukuran file audio maksimal adalah ${maxAudioSizeMB}MB. Berkas Anda ${fileSizeMB.toStringAsFixed(2)}MB.',
        );
        return false;
      }

      String extension = file.path.split('.').last.toLowerCase();
      if (!validAudioFormats.contains(extension)) {
        _showErrorDialog(
          'Format Tidak Didukung',
          'Format .$extension tidak didukung.\n Gunakan format: ${validAudioFormats.join(", ")}',
        );
        return false;
      }

      return true;
    } catch (e) {
      _showErrorDialog(
        'Validasi Error',
        'Terjadi kesalahan saat memeriksa berkas: $e',
      );
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

  /// Fungsi memilih file menggunakan FilePicker
  Future<void> _pickAudio() async {
    try {
      final hasPermission = await _requestAudioPermission();

      if (hasPermission) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          File f = File(result.files.single.path!);

          if (_validateAudioFile(f)) {
            setState(() {
              _audioFile = f;
              double sizeInMB = f.lengthSync() / (1024 * 1024);
              _sizeText = 'Ukuran Asli: ${sizeInMB.toStringAsFixed(2)} MB';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal memilih berkas musik/suara: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String fileName = _audioFile != null
        ? Uri.parse(_audioFile!.path).pathSegments.last
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PILIH AUDIO',
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
              onTap: _pickAudio,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  border: Border.all(color: Colors.purple.shade200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _audioFile != null
                    ? const Center(
                        child: Icon(
                          Icons.library_music,
                          color: Colors.purple,
                          size: 60,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'PILIH FILE AUDIO / MUSIK',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    _sizeText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_audioFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Nama: $fileName',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 16),
                  RadioListTile<int>(
                    title: const Text('Normal (Kompresi Standar)'),
                    value: 1,
                    groupValue: _q,
                    onChanged: (v) => setState(() => _q = v!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Ekstrem (Ukuran Paling Kecil)'),
                    value: 2,
                    groupValue: _q,
                    onChanged: (v) => setState(() => _q = v!),
                  ),
                ],
              ),
            ),

            // Tombol Eksekusi
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  if (_audioFile == null) {
                    _showErrorDialog(
                      'Peringatan',
                      'Silakan tentukan file audio terlebih dahulu.',
                    );
                    return;
                  }

                  if (!_validateAudioFile(_audioFile!)) {
                    return;
                  }

                  try {
                    final f = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProcessMediaScreen(
                          file: _audioFile!,
                          q: _q,
                          type: 'AUDIO',
                        ),
                      ),
                    );
                    if (f == null) return;
                    if (mounted) {
                      Navigator.pop(context, {
                        'original': _audioFile!,
                        'compressed': f,
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorDialog(
                        'Error',
                        'Gagal memulai kompresi audio: $e',
                      );
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
