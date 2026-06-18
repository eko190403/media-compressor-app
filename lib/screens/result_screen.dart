import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'fullscreen_image_viewer.dart';
import 'fullscreen_video_viewer.dart';
import 'package:gal/gal.dart';

class ResultScreen extends StatefulWidget {
  final File originalFile;
  final File compressedFile;
  final String mediaType;
  const ResultScreen({
    super.key,
    required this.originalFile,
    required this.compressedFile,
    required this.mediaType,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaved = false; // Tracking status apakah file sudah disimpan ke galeri

  Future<void> _deleteCompressedFile() async {
    try {
      if (await widget.compressedFile.exists()) {
        await widget.compressedFile.delete();
        debugPrint(
          "File sementara berhasil dihapus: ${widget.compressedFile.path}",
        );
      }
    } catch (e) {
      debugPrint("Error menghapus file sementara: $e");
    }
  }

  // Fungsi pengaman untuk mengecek status simpan sebelum keluar
  Future<bool> _confirmExit() async {
    // Jika file berupa PDF (yang tidak punya tombol simpan galeri murni) atau sudah disimpan, izinkan keluar langsung
    if (_isSaved || widget.mediaType == 'PDF') {
      await _deleteCompressedFile();
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Belum Disimpan"),
        content: const Text(
          "File hasil kompresi belum disimpan ke galeri. Apakah Anda yakin ingin keluar dan menghapusnya?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteCompressedFile();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double oMb = widget.originalFile.lengthSync() / (1024 * 1024);
    final double cMb = widget.compressedFile.lengthSync() / (1024 * 1024);
    final int saved =
        (((widget.originalFile.lengthSync() -
                        widget.compressedFile.lengthSync()) /
                    widget.originalFile.lengthSync()) *
                100)
            .round();
    final bool success =
        widget.compressedFile.lengthSync() < widget.originalFile.lengthSync();

    return PopScope(
      canPop:
          false, // Kunci tombol back bawaan HP agar melewati konfirmasi dialog
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.blue.shade100,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'HASIL KOMPRESI',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                if (widget.mediaType == 'FOTO')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Preview Foto (Ketuk untuk memperbesar)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(
                                imageFile: widget.compressedFile,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            widget.compressedFile,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                else if (widget.mediaType == 'VIDEO')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Preview Video (Ketuk untuk memutar)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenVideoViewer(
                                videoFile: widget.compressedFile,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 60,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Perbandingan Ukuran',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Asli',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${oMb.toStringAsFixed(2)} MB',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.grey),
                            Column(
                              children: [
                                const Text(
                                  'Hasil',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${cMb.toStringAsFixed(2)} MB',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: success
                                        ? Colors.green
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!success)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'File terlalu kecil untuk dikompres lebih jauh',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Ukuran berhasil dipotong sehemat $saved%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. TOMBOL SIMPAN KE GALERI (Hanya untuk Foto & Video)
                if (widget.mediaType != 'PDF') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Platform.isAndroid ? Icons.download : Icons.save_alt,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isSaved ? 'Tersimpan di Galeri' : 'Simpan ke Galeri',
                      ),
                      onPressed: _isSaved
                          ? null // Matikan tombol jika sudah berhasil disimpan agar tidak diduplikasi
                          : () async {
                              try {
                                final hasAccess = await Gal.requestAccess();
                                if (hasAccess) {
                                  if (widget.mediaType == 'VIDEO') {
                                    await Gal.putVideo(
                                      widget.compressedFile.path,
                                    );
                                  } else {
                                    await Gal.putImage(
                                      widget.compressedFile.path,
                                    );
                                  }

                                  setState(() => _isSaved = true);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Berhasil disimpan ke galeri!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Izin akses galeri ditolak.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal menyimpan: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaved
                            ? Colors.grey
                            : Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. TOMBOL BAGIKAN FILE (Universal untuk Foto, Video, & PDF)
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Bagikan File'),
                    onPressed: () async {
                      try {
                        await Share.shareXFiles([
                          XFile(widget.compressedFile.path),
                        ]);
                      } catch (e) {
                        debugPrint('Error sharing: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. TOMBOL KOMPRES LAGI (Diperbaiki: Sekarang terbuka untuk PDF agar bisa kembali)
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Kompres Lagi'),
                    onPressed: () async {
                      if (await _confirmExit() && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. TOMBOL SELESAI
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (await _confirmExit() && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
