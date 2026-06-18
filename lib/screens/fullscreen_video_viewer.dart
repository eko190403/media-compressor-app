import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:async';

class FullscreenVideoViewer extends StatefulWidget {
  final File videoFile;
  const FullscreenVideoViewer({super.key, required this.videoFile});

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls =
      true; // State untuk menyembunyikan/menampilkan tombol kontrol
  Timer? _controlsTimer; // Pengatur waktu otomatis hilangnya tombol kontrol

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true); // Otomatis mengulang video jika habis
          _startControlsTimer(); // Mulai hitung mundur sembunyikan tombol
        }
      });
  }

  // KOREKSI AMAN: Amankan siklus penghancuran memori tanpa panggil pause()
  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startControlsTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    String fileName = widget.videoFile.path.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
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
        child: _initialized
            ? GestureDetector(
                onTap:
                    _toggleControls, // Mengetuk layar hanya untuk memunculkan/menyembunyikan bar kontrol
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),

                      // KOREKSI UI: Lapisan Kontrol Transparan yang Bisa Menghilang Otomatis
                      AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: !_showControls,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                color: Colors.black38,
                              ), // Efek redup latar belakang saat kontrol aktif
                              // Tombol Play/Pause Tengah Layar
                              IconButton(
                                iconSize: 75.0,
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_controller.value.isPlaying) {
                                      _controller.pause();
                                    } else {
                                      _controller.play();
                                    }
                                  });
                                  _startControlsTimer(); // Reset ulang waktu hilangnya tombol
                                },
                              ),

                              // KOREKSI FITUR: Menambahkan Progress Bar Pemutar di Bagian Bawah Video
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing:
                                      true, // Membuat durasi video bisa digeser maju/mundur
                                  colors: VideoProgressColors(
                                    playedColor: Colors.blue.shade700,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(color: Colors.blue),
      ),
    );
  }
}
