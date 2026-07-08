import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'premium_page.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';

import 'services/admob_service.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();
  runApp(const MediaCompressApp());
}

class MediaCompressApp extends StatelessWidget {
  const MediaCompressApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppStateContainer(),
    );
  }
}

class AppStateContainer extends StatefulWidget {
  const AppStateContainer({super.key});
  @override
  State<AppStateContainer> createState() => _AppStateContainerState();
}

class _AppStateContainerState extends State<AppStateContainer> {
  int _quota = 3;
  bool _isOnline = true;
  bool _isPremium = false;
  StreamSubscription<dynamic>? _connectivitySubscription;

  final AdmobService _admobService = AdmobService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initializeAppData();

    _checkInternet();
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((_) {
      _checkInternet();
    });
  }

  Future<void> _checkInternet() async {
    bool isOnline = await _connectivityService.hasInternet();
    if (mounted && _isOnline != isOnline) {
      setState(() => _isOnline = isOnline);
    }
  }

  Future<void> _initializeAppData() async {
    try {
      await _syncUserStatusAndQuota();
      if (!_isPremium) {
        _admobService.loadBannerAd(() {
          if (mounted) setState(() {});
        });
        _admobService.loadInterstitialAd();
        _admobService.loadRewardedAd();
      }
    } catch (e) {
      debugPrint("Error inisialisasi: $e");
    }
  }

  Future<void> _syncUserStatusAndQuota() async {
    try {
      final userData = await _firebaseService.syncUserStatusAndQuota();
      if (userData != null && mounted) {
        setState(() {
          _quota = userData.quota;
          _isPremium = userData.isPremium;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyinkronkan data pengguna dengan server.')),
        );
      }
    }
  }

  void _showPaywallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'KUOTA HABIS!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Tonton iklan video pendek untuk mendapatkan +1 Kuota, atau Upgrade Premium.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _admobService.showRewardedAd(() async {
                try {
                  int newQuota = await _firebaseService.addQuotaFromAd();
                  if (mounted) {
                    setState(() => _quota = newQuota);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal menambahkan kuota. Cek koneksi Anda.')),
                    );
                  }
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Tonton Iklan (+1)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Butuh Internet"),
        content: const Text("Fitur ini memerlukan koneksi internet untuk mengelola kuota."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompressionSuccess(
    String title,
    Map<String, dynamic> result,
  ) async {
    // Check latest status first before proceeding
    try {
      await _syncUserStatusAndQuota();
    } catch (e) {
      // Ignore if offline, fallback to local state
    }

    if (!_isPremium) {
      bool online = await _connectivityService.hasInternet();
      if (!online) {
        _showNoInternetDialog();
        return;
      }
      if (_quota <= 0) {
        _showPaywallDialog();
        return;
      }
    }

    if (!mounted) return;

    // Alur penanganan halaman hasil
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          originalFile: result['original']!,
          compressedFile: result['compressed']!,
          mediaType: title,
        ),
      ),
    ).then((_) => _syncUserStatusAndQuota());

    if (!_isPremium) {
      try {
        int newQuota = await _firebaseService.consumeQuota(_quota, _isOnline);
        if (mounted) {
          setState(() => _quota = newQuota);
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Terjadi kesalahan saat memotong kuota.'))
           );
        }
      }
      _admobService.showInterstitialAd();
    }
  }

  @override
  void dispose() {
    _admobService.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      quota: _quota,
      isPremium: _isPremium,
      isOnline: _isOnline,
      bannerAd: _admobService.bannerAd,
      isBannerAdReady: _admobService.isBannerAdReady,
      onTriggerPrivacyPolicy: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Kebijakan Privasi"),
            content: const Text(
              "Aplikasi ini tidak menyimpan data Anda. Semua proses dilakukan lokal.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final Uri uri = Uri.parse(
                    'https://docs.google.com/document/d/1example/edit?usp=sharing',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text("Baca Lengkap"),
              ),
            ],
          ),
        );
      },
      onTriggerHistory: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
      },
      onTriggerPremiumPage: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumPage()),
        );
        await _syncUserStatusAndQuota();
      },
      onCompressionSuccess: (type, res) => _handleCompressionSuccess(type, res),
    );
  }
}
