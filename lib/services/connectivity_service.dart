import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// Checks if the device has an active network connection AND actual internet access
  Future<bool> hasInternet() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    
    bool hasNetwork = connectivityResult.any((r) => r != ConnectivityResult.none);

    if (!hasNetwork) return false;

    // Perform an actual internet check
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }
  
  /// Listen to network status changes (note: this only tracks connection to network, not actual internet)
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged;
  }
}
