import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'compress_photo_screen.dart';
import 'compress_video_screen.dart';
import 'compress_pdf_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  final int quota;
  final bool isPremium;
  final bool isOnline;
  final BannerAd? bannerAd;
  final bool isBannerAdReady;
  final VoidCallback onTriggerPrivacyPolicy;
  final VoidCallback onTriggerHistory;
  final VoidCallback onTriggerPremiumPage;
  final Future<void> Function(String type, Map<String, dynamic> result)
      onCompressionSuccess;

  const HomeScreen({
    super.key,
    required this.quota,
    required this.isPremium,
    required this.isOnline,
    required this.bannerAd,
    required this.isBannerAdReady,
    required this.onTriggerPrivacyPolicy,
    required this.onTriggerHistory,
    required this.onTriggerPremiumPage,
    required this.onCompressionSuccess,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _clearTempFiles();
  }

  Future<void> _clearTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      int deletedCount = 0;
      for (var file in files) {
        if (file.path.contains('c_')) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            debugPrint("Error menghapus file: ${file.path}, Error: $e");
          }
        }
      }
      if (deletedCount > 0) {
        debugPrint("Total file sementara yang dihapus: $deletedCount");
      }
    } catch (e) {
      debugPrint("Error saat membersihkan temp files: $e");
    }
  }

  void _navigateToCompress(String type) async {
    Map<String, dynamic>? result;

    if (type == 'FOTO') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompressPhotoScreen(
            isPremium: widget.isPremium,
            onCompressionSuccess: widget.onCompressionSuccess,
          ),
        ),
      );
    } else if (type == 'VIDEO') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompressVideoScreen(
            isPremium: widget.isPremium,
            onCompressionSuccess: widget.onCompressionSuccess,
          ),
        ),
      );
    } else if (type == 'PDF') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompressPdfScreen(
            isPremium: widget.isPremium,
            onCompressionSuccess: widget.onCompressionSuccess,
          ),
        ),
      );
    }

    if (result != null && result['compressed'] != null) {
      await widget.onCompressionSuccess(type, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Media Compress',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kompres Foto, Video & PDF',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: widget.onTriggerPrivacyPolicy,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: widget.onTriggerHistory,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Icon(
                  widget.isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 14,
                  color: widget.isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 2),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 9, color: Colors.black),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(
              right: 12,
              left: 4,
              top: 8,
              bottom: 8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: Colors.orange),
                const SizedBox(width: 2),
                Text(
                  widget.isPremium ? '∞' : '${widget.quota}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // KOREKSI CLEAN: Kembali ke 3 menu vertikal utama (Foto, Video, PDF)
            Column(
              children: [
                _buildMenuCard(
                  'KOMPRES FOTO',
                  Icons.camera_alt,
                  'FOTO',
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  'KOMPRES VIDEO',
                  Icons.videocam,
                  'VIDEO',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  'KOMPRES PDF',
                  Icons.picture_as_pdf,
                  'PDF',
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!widget.isPremium)
              GestureDetector(
                onTap: widget.onTriggerPremiumPage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Upgrade Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '✓ Unlimited Kompres  ✓ Tanpa Iklan  ✓ Akses Offline',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),

            if (!widget.isPremium)
              (widget.isBannerAdReady && widget.bannerAd != null
                  ? Container(
                      alignment: Alignment.center,
                      width: widget.bannerAd!.size.width.toDouble(),
                      height: widget.bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: widget.bannerAd!),
                    )
                  : Container(
                      height: 50,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Center(child: Text('Memuat Iklan...')),
                    ))
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    String type,
    Color themeColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: themeColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isPremium ? 'Bebas Kuota' : '-1 Kuota harian',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isPremium
                        ? Colors.green.shade700
                        : Colors.pink.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 75,
            height: 34,
            child: ElevatedButton(
              onPressed: () => _navigateToCompress(type),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Buka',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
