import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String _currentDeviceId = "Memuat ID...";
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _loadRealDeviceId();
  }

  // Mengambil ID Perangkat asli HP user (Bukan statis "device_test_001")
  Future<void> _loadRealDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String idResult = "unknown_device";

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        idResult = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        idResult = iosInfo.identifierForVendor ?? "unknown_ios";
      }

      if (mounted) {
        setState(() {
          _currentDeviceId = idResult;
          _isLoadingId = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentDeviceId = "Gagal memuat ID";
          _isLoadingId = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
        title: const Text(
          "UPGRADE PREMIUM",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Pindai QRIS DANA di bawah ini untuk melakukan pembayaran sebesar Rp15.000",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // AREA TAMPILAN QRIS
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShape.circle == false
                          ? BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          : const BoxShadow(),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/qris.jpeg',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 240,
                          height: 240,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Text("Gambar QRIS Belum Terpasang"),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // KOREKSI DI SINI: Parameter border dibungkus dengan benar di dalam BoxDecoration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ), // <-- Peletakan parameter border yang valid
                ),
                child: Column(
                  children: [
                    const Text(
                      "DEVICE ID ANDA (WAJIB COCOK)",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _currentDeviceId,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            size: 18,
                            color: Colors.grey,
                          ),
                          tooltip: "Salin ID",
                          onPressed: _isLoadingId
                              ? null
                              : () {
                                  Clipboard.setData(
                                    ClipboardData(text: _currentDeviceId),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Device ID berhasil disalin!",
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Langkah setelah transfer:\n1. Salin Device ID di atas atau biarkan tombol WhatsApp mengisinya otomatis.\n2. Kirim bukti transfer dan sebutkan Device ID Anda ke Admin.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // TOMBOL KIRIM DATA WHATSAPP
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    "Konfirmasi via WhatsApp",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isLoadingId
                      ? null
                      : () async {
                          String phoneNumber = "6285769363379";
                          String message =
                              "Halo Admin, saya ingin konfirmasi aktivasi Premium Media Compress.\n\nBerikut Device ID saya:\n$_currentDeviceId\n\nSaya akan mengirimkan foto bukti transfer setelah ini.";

                          final Uri url = Uri.parse(
                            "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
                          );

                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Gagal membuka WhatsApp. Pastikan aplikasi WA terinstal.",
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint("Error WhatsApp: $e");
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
