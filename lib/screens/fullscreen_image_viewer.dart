import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class FullscreenImageViewer extends StatelessWidget {
  final File imageFile;
  const FullscreenImageViewer({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    // Mengambil nama file saja untuk dipasang di AppBar jika diperlukan (opsional)
    String fileName = imageFile.path.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      // Menggunakan AppBar dengan kustomisasi status bar bertema gelap pekat
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Brightness.light, // Ikon status bar berwarna putih
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: Center(
        // KOREKSI: Membunderkan Image dengan InteractiveViewer agar bisa di-zoom (Pinch to Zoom)
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          minScale: 1.0, // Batas terkecil (kembali ke ukuran semula)
          maxScale: 4.0, // Batas terbesar perbesaran (4x lipat)
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
            // Memastikan gambar merender dengan kualitas terbaik saat di-zoom
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
