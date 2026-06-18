import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'premium_page.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

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
  bool _isBannerAdReady = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  StreamSubscription<dynamic>? _connectivitySubscription;

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    return "unknown_device";
  }

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    if (result is List) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  @override
  void initState() {
    super.initState();
    _initializeAppData();

    Connectivity().checkConnectivity().then((result) {
      _setConnectivityFrom(result);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      _setConnectivityFrom(result);
    });
  }

  Future<void> _initializeAppData() async {
    try {
      await _syncUserStatusAndQuota();
      if (!_isPremium) {
        _loadBannerAd();
        _loadInterstitialAd();
        _loadRewardedAd();
      }
    } catch (e) {
      debugPrint("Error inisialisasi: $e");
    }
  }

  Future<void> _syncUserStatusAndQuota() async {
    try {
      String deviceId = await _getDeviceId();
      var docRef = FirebaseFirestore.instance.collection('users').doc(deviceId);
      String today = DateTime.now().toString().substring(0, 10);
      var doc = await docRef.get();

      int targetQuota = 3;
      bool targetPremium = false;

      if (doc.exists) {
        targetPremium = doc.data()?['isPremium'] ?? false;
        String lastDate = doc.data()?['lastDate'] ?? '';
        int currentQuota = doc.data()?['quota'] ?? 3;

        if (lastDate != today) {
          targetQuota = 3;
          await docRef.update({'quota': 3, 'lastDate': today});
        } else {
          targetQuota = currentQuota;
        }
      } else {
        await docRef.set({'quota': 3, 'lastDate': today, 'isPremium': false});
      }

      if (mounted) {
        setState(() {
          _quota = targetQuota;
          _isPremium = targetPremium;
        });
      }
    } catch (e) {
      debugPrint('Error sync: $e');
    }
  }

  void _loadBannerAd() {
    if (_isPremium) return;
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted && !_isPremium) {
            setState(() => _isBannerAdReady = true);
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
        },
        onAdClosed: (ad) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    if (_isPremium) return;
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) =>
            debugPrint('Interstitial failed: ${err.message}'),
      ),
    );
  }

  void _loadRewardedAd() {
    if (_isPremium) return;
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) =>
            debugPrint('Rewarded failed: ${err.message}'),
      ),
    );
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
              if (_rewardedAd != null) {
                _rewardedAd!.show(
                  onUserEarnedReward: (ad, reward) async {
                    await _addQuotaFromAd();
                    _loadRewardedAd();
                  },
                );
              } else {
                _loadRewardedAd();
              }
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

  Future<void> _addQuotaFromAd() async {
    String deviceId = await _getDeviceId();
    setState(() => _quota += 1);
    await FirebaseFirestore.instance.collection('users').doc(deviceId).update({
      'quota': _quota,
    });
  }

  Future<void> _updateQuota() async {
    if (_isPremium) return;
    String deviceId = await _getDeviceId();
    if (await _hasInternet()) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(deviceId)
            .update({'quota': FieldValue.increment(-1)});
        await _syncUserStatusAndQuota();
      } catch (e) {
        debugPrint("Quota update error: $e");
      }
    } else {
      setState(() => _quota--);
    }
  }

  void _setConnectivityFrom(dynamic result) {
    bool online = false;
    if (result is ConnectivityResult) {
      online = result != ConnectivityResult.none;
    } else if (result is List) {
      try {
        online = result.any((r) => r != ConnectivityResult.none);
      } catch (e) {
        online = result.isNotEmpty;
      }
    }
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _handleCompressionSuccess(
    String title,
    Map<String, dynamic> result,
  ) async {
    String deviceId = await _getDeviceId();
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(deviceId)
        .get();
    bool isPremiumUser = doc.data()?['isPremium'] ?? false;
    int currentQuotaUser = doc.data()?['quota'] ?? 0;

    setState(() {
      _isPremium = isPremiumUser;
      _quota = currentQuotaUser;
    });

    if (!isPremiumUser) {
      bool online = await _hasInternet();
      if (!online) {
        _showNoInternetDialog();
        return;
      }
      if (currentQuotaUser <= 0) {
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

    if (!isPremiumUser) {
      await _updateQuota();
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _loadInterstitialAd();
      }
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Butuh Internet"),
        content: const Text("Fitur ini memerlukan koneksi internet."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MENYAMBUNGKAN STATE UTAMA KE FILE HOME_SCREEN.DART YANG BARU
    return HomeScreen(
      quota: _quota,
      isPremium: _isPremium,
      isOnline: _isOnline,
      bannerAd: _bannerAd,
      isBannerAdReady: _isBannerAdReady,
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
                  if (await canLaunchUrl(uri))
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

      // KOREKSI DI SINI: Menggunakan fungsi async-await murni untuk mendeteksi halaman ditutup
      onTriggerPremiumPage: () async {
        // 1. Aplikasi akan menunggu (pause) di baris ini sampai PremiumPage ditutup oleh user
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumPage()),
        );

        // 2. Begitu user kembali ke HomeScreen, baris di bawah ini langsung dieksekusi secara paksa
        await _syncUserStatusAndQuota();
      },

      onCompressionSuccess: (type, res) => _handleCompressionSuccess(type, res),
    );
  }
}
