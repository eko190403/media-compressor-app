import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'device_service.dart';

class UserData {
  final int quota;
  final bool isPremium;

  UserData({required this.quota, required this.isPremium});
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserData?> syncUserStatusAndQuota() async {
    try {
      String deviceId = await DeviceService().getDeviceId();
      var docRef = _firestore.collection('users').doc(deviceId);
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

      return UserData(quota: targetQuota, isPremium: targetPremium);
    } catch (e) {
      debugPrint('FirebaseService Error sync: $e');
      throw Exception('Gagal menyinkronkan data pengguna dengan server.');
    }
  }

  Future<int> addQuotaFromAd() async {
    try {
      String deviceId = await DeviceService().getDeviceId();
      
      return await _firestore.runTransaction((transaction) async {
        DocumentReference docRef = _firestore.collection('users').doc(deviceId);
        DocumentSnapshot snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }
        
        int currentQuota = snapshot.get('quota') ?? 0;
        int newQuota = currentQuota + 1;
        transaction.update(docRef, {'quota': newQuota});
        return newQuota;
      });
    } catch (e) {
      debugPrint('FirebaseService Error add quota: $e');
      throw Exception('Gagal menambahkan kuota.');
    }
  }

  Future<int> consumeQuota(int currentQuotaLocally, bool isOnline) async {
    if (!isOnline) {
      return currentQuotaLocally > 0 ? currentQuotaLocally - 1 : 0;
    }

    try {
      String deviceId = await DeviceService().getDeviceId();
      
      return await _firestore.runTransaction((transaction) async {
        DocumentReference docRef = _firestore.collection('users').doc(deviceId);
        DocumentSnapshot snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }
        
        int currentQuota = snapshot.get('quota') ?? 0;
        if (currentQuota <= 0) {
          return 0; // Out of quota
        }
        
        int newQuota = currentQuota - 1;
        transaction.update(docRef, {'quota': newQuota});
        return newQuota;
      });
    } catch (e) {
      debugPrint("FirebaseService Quota consume error: $e");
      throw Exception('Gagal memotong kuota di server.');
    }
  }
}
