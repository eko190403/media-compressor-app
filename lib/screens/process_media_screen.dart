import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ProcessMediaScreen extends StatefulWidget {
  final File file;
  final int q;
  final String type;
  const ProcessMediaScreen({
    super.key,
    required this.file,
    required this.q,
    required this.type,
  });
  @override
  State<ProcessMediaScreen> createState() => _ProcessMediaScreenState();
}

class _ProcessMediaScreenState extends State<ProcessMediaScreen>
    with TickerProviderStateMixin {
  double _progress = 0;
  String _status = 'Menyiapkan kompres...';
  String? _errorDetail;
  bool _hasError = false;
  dynamic _progressSubscription;
  late AnimationController _animationController;

  late Stopwatch _stopwatch;
  String _elapsedTime = '0:00';
  late Timer _timerDisplay;

  @override
  void initState() {
    super.initState();

    _stopwatch = Stopwatch()..start();
    _timerDisplay = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_hasError) {
        setState(() {
          int seconds = _stopwatch.elapsed.inSeconds;
          int minutes = seconds ~/ 60;
          int secs = seconds % 60;
          _elapsedTime = '$minutes:${secs.toString().padLeft(2, '0')}';

          if (widget.type != 'VIDEO') {
            if (seconds == 4) {
              _status = 'Membaca struktur data ${widget.type.toLowerCase()}...';
            } else if (seconds == 8) {
              _status = 'Merestrukturisasi ukuran biner file...';
            } else if (seconds == 15) {
              _status = 'Menuliskannya ke folder temporary...';
            }
          }
        });
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _progressSubscription = VideoCompress.compressProgress$.subscribe((
      progress,
    ) {
      if (mounted) {
        setState(() {
          _progress = progress.toDouble();
        });
      }
    });

    _start();
  }

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _hasError = false;
      _errorDetail = null;
    });
  }

  void _showError(String message, [String? detail]) {
    if (!mounted) return;
    _timerDisplay.cancel();
    _stopwatch.stop();
    setState(() {
      _status = message;
      _errorDetail = detail;
      _hasError = true;
    });
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _setStatus('Menyiapkan kompres...');

    try {
      final originalSize = widget.file.lengthSync();

      // 1. JALUR KOMPRES FOTO
      if (widget.type == 'FOTO') {
        if (originalSize <= 0) {
          _showError('File foto tidak valid.');
          return;
        }

        _setStatus('Mengompres foto...');
        try {
          int quality = widget.q == 1 ? 60 : 30;
          final dir = await getTemporaryDirectory();
          final targetPath =
              '${dir.path}/c_${DateTime.now().millisecondsSinceEpoch}.jpg';

          XFile? res = await FlutterImageCompress.compressAndGetFile(
            widget.file.path,
            targetPath,
            quality: quality,
          );

          if (res == null) {
            _showError('Kompresi foto gagal. Hasil null.',
                'FlutterImageCompress mengembalikan null');
            return;
          }

          File compressedFile = File(res.path);
          if (!compressedFile.existsSync()) {
            _showError('Kompresi foto gagal. File tidak ditemukan.',
                'Path: ${res.path}');
            return;
          }

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context, compressedFile);
            });
          }
          return;
        } catch (e) {
          _showError('Kompresi foto gagal.', 'Error: $e');
          return;
        }
      }

      // 2. JALUR KOMPRES VIDEO
      if (widget.type == 'VIDEO') {
        if (originalSize <= 0) {
          _showError('File video tidak valid.');
          return;
        }

        _setStatus('Mengompres video...');
        try {
          VideoQuality vq = widget.q == 1
              ? VideoQuality.DefaultQuality
              : VideoQuality.LowQuality;
          MediaInfo? info = await VideoCompress.compressVideo(
            widget.file.path,
            quality: vq,
            deleteOrigin: false,
          );

          if (info == null || info.file == null) {
            _showError('Kompresi video gagal.', 'MediaInfo returned null');
            return;
          }

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context, info.file);
            });
          }
          return;
        } catch (e) {
          _showError('Kompresi video gagal.', 'Error: $e');
          return;
        }
      }

      // 3. JALUR KOMPRES PDF
      if (widget.type == 'PDF') {
        if (originalSize <= 0) {
          _showError('File PDF tidak valid.');
          return;
        }

        _setStatus('Mengompres PDF...');
        try {
          final PdfDocument doc = PdfDocument(
            inputBytes: widget.file.readAsBytesSync(),
          );
          doc.compressionLevel = PdfCompressionLevel.best;
          final dir = await getTemporaryDirectory();
          File res = File(
            '${dir.path}/c_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );

          List<int> pdfBytes = await doc.save();
          if (pdfBytes.isEmpty) {
            _showError(
                'Kompresi PDF gagal. File hasil kosong.', 'PDF bytes kosong');
            doc.dispose();
            return;
          }

          await res.writeAsBytes(pdfBytes);
          doc.dispose();

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context, res);
            });
          }
          return;
        } catch (e) {
          _showError('Kompresi PDF gagal.', 'Error: $e');
          return;
        }
      }

      _showError('Tipe file tidak dikenali.');
    } catch (e) {
      _showError('Terjadi kesalahan saat kompres. Coba lagi.', e.toString());
    }
  }

  @override
  void dispose() {
    _progressSubscription?.unsubscribe();
    _timerDisplay.cancel();
    _stopwatch.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData fileIcon;
    Color iconColor;

    switch (widget.type) {
      case 'FOTO':
        fileIcon = Icons.image;
        iconColor = Colors.purple;
        break;
      case 'VIDEO':
        fileIcon = Icons.videocam;
        iconColor = Colors.red;
        break;
      case 'PDF':
        fileIcon = Icons.picture_as_pdf;
        iconColor = Colors.orange;
        break;
      default:
        fileIcon = Icons.file_present;
        iconColor = Colors.blue;
    }

    return PopScope(
      canPop: _hasError,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jangan tutup layar saat proses berlangsung!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_hasError)
                    ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.1)
                          .animate(_animationController),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(fileIcon, size: 80, color: iconColor),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline,
                          size: 80, color: Colors.red),
                    ),
                  const SizedBox(height: 30),
                  Text(
                    _hasError ? 'Kompresi Gagal' : 'Mengompres ${widget.type}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _hasError ? Colors.red : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  if (!_hasError) ...[
                    if (widget.type == 'VIDEO')
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_progress / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade400),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_progress.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                              Text('Waktu: $_elapsedTime',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: null,
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      iconColor.withOpacity(0.3)),
                                ),
                                Positioned(
                                  child: RotationTransition(
                                    turns: _animationController,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: iconColor, width: 4),
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hourglass_bottom,
                                        color: iconColor, size: 32),
                                    const SizedBox(height: 4),
                                    Text(
                                      _elapsedTime,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: iconColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ],
                  if (_hasError && _errorDetail != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detail Error:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          const SizedBox(height: 4),
                          Text(_errorDetail!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_hasError)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('KEMBALI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Jangan tutup aplikasi selama proses berlangsung',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.blue, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
