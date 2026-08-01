import 'dart:async';
import 'dart:convert'; // Wajib untuk base64
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import Wajib untuk kIsWeb / Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Stock {
  final String id;
  final String name;
  final String unit;
  final int quantity;

  Stock({required this.id, required this.name, required this.quantity, required this.unit});

  factory Stock.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final namaBarang = data['name']?.toString() ?? '';
    
    return Stock(
      id: doc.id,
      name: namaBarang,
      quantity: (data['quantity'] is int) ? data['quantity'] as int : int.tryParse('${data['quantity'] ?? 0}') ?? 0,
      unit: namaBarang.contains('220ml') ? 'Karton' : (data['unit']?.toString() ?? 'Karton'),
    );
  }
}

class Store {
  final String id;
  final String name;
  final String address;
  final String sales;
  final String status;
  final List<dynamic> muatan;
  final DateTime? createdAt;

  Store({
    required this.id, 
    required this.name, 
    required this.address, 
    required this.sales,
    required this.status,
    required this.muatan,
    this.createdAt,
  });

  factory Store.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    String salesValue = data['sales']?.toString() ?? data['salesName']?.toString() ?? 'SYAKUR';
    String statusValue = data['status']?.toString() ?? 'PENDING';
    List<dynamic> muatanList = data['muatan'] is List ? data['muatan'] as List : [];
    
    DateTime? createdTime;
    if (data['createdAt'] is Timestamp) {
      createdTime = (data['createdAt'] as Timestamp).toDate();
    }

    return Store(
      id: doc.id, 
      name: data['name']?.toString() ?? '',
      address: data['address']?.toString() ?? '', 
      sales: salesValue,
      status: statusValue,
      muatan: muatanList,
      createdAt: createdTime,
    );
  }
}

class SalesHistory {
  final String id; // <-- TAMBAHKAN ID DOKUMEN FIRESTORE
  final String sales;
  final List<dynamic> muatan;
  final DateTime timestamp;
  final String storeName;

  SalesHistory({
    required this.id, 
    required this.sales, 
    required this.muatan, 
    required this.timestamp, 
    required this.storeName
  });

  factory SalesHistory.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SalesHistory(
      id: doc.id, // <-- SIMPAN ID DOKUMEN FIRESTORE
      sales: data['sales']?.toString() ?? '',
      muatan: data['muatan'] is List ? data['muatan'] as List : [],
      timestamp: (data['timestamp'] is Timestamp) ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      storeName: data['storeName']?.toString() ?? 'Toko Terhapus (Reset Harian)',
    );
  }
}

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<Stock> _stocks = [];
  final List<Store> _stores = [];
  final List<SalesHistory> _history = [];

  DateTime? _waktuResetHarianTerakhir;
  DateTime? _waktuResetBulananTerakhir;

  final Map<String, int> salesTargets = {
    'SYAKUR': 20000,
    'FAISOL': 5000,
    'MULYADI': 5000,
    'LUAY': 5000,
    'INSTANSI': 10000,
    'SHOPEE': 10000,
  };

  StreamSubscription<QuerySnapshot>? _stocksSub;
  StreamSubscription<QuerySnapshot>? _storesSub;
  StreamSubscription<QuerySnapshot>? _historySub;

  AdminProvider();

  List<Stock> get stocks => List.unmodifiable(_stocks);
  List<Store> get stores => List.unmodifiable(_stores);
  List<SalesHistory> get history => List.unmodifiable(_history);

  Stream<DocumentSnapshot> streamSalesProfile(String salesName) {
    return _db.collection('sales_profiles').doc(salesName.trim().toUpperCase()).snapshots();
  }

  // JALUR TOTAL GRATIS: Mengubah gambar menjadi teks murni agar tersimpan aman di Firestore tanpa CORS error
  Future<void> uploadAndUpdateSalesAvatarCrossPlatform(String salesName, dynamic xFile, Uint8List imageBytes) async {
    final String cleanName = salesName.trim().toUpperCase();
    
    try {
      // Mengubah gambar menjadi string teks Base64
      final String base64String = base64Encode(imageBytes);

      // Simpan langsung teks gambar ini ke Cloud Firestore yang gratis
      await _db.collection('sales_profiles').doc(cleanName).set({
        'avatarBase64': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadAndUpdateSalesAvatar(String salesName, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    await uploadAndUpdateSalesAvatarCrossPlatform(salesName, null, bytes);
  }

  Stream<List<Store>> streamStoresBySales(String salesName) {
    return _db.collection('stores').snapshots().map((snap) {
      final allStores = snap.docs.map((d) => Store.fromDoc(d)).toList();
      
      _stores.clear();
      _stores.addAll(allStores);
      
      return allStores.where((store) {
        return store.sales.trim().toUpperCase() == salesName.trim().toUpperCase();
      }).toList();
    });
  }

  void startListening() {
    _stocksSub?.cancel();
    _storesSub?.cancel();
    _historySub?.cancel();
    _listenToStocks();
    _listenToStores();
    _listenToSalesHistory();
  }

  void _listenToStocks() {
    _stocksSub = _db.collection('stocks').orderBy('name').snapshots().listen((snap) {
      _stocks
        ..clear()
        ..addAll(snap.docs.map((d) => Stock.fromDoc(d)));
      notifyListeners();
    });
  }

  void _listenToStores() {
    _storesSub = _db.collection('stores').snapshots().listen((snap) {
      _stores
        ..clear()
        ..addAll(snap.docs.map((d) => Store.fromDoc(d)));
      notifyListeners();
    });
  }

  void _listenToSalesHistory() {
    _db.collection('system_config').doc('sales_period').snapshots().listen((configSnap) {
      if (configSnap.exists) {
        final configData = configSnap.data() ?? {};
        if (configData['last_reset_monthly'] is Timestamp) {
          _waktuResetBulananTerakhir = (configData['last_reset_monthly'] as Timestamp).toDate();
        }
        if (configData['last_reset_daily'] is Timestamp) {
          _waktuResetHarianTerakhir = (configData['last_reset_daily'] as Timestamp).toDate();
        }
      }

      // TARIK SEMUA TANPA FILTER TANGGAL MAUPUN WHERE
      _db.collection('history_penjualan').snapshots().listen((snap) {
        _history
          ..clear()
          ..addAll(snap.docs.map((d) => SalesHistory.fromDoc(d)));
        
        // Urutkan manual lewat Dart biar ga perlu Firestore Index
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        notifyListeners();
      });
    });
  }

  Future<void> completeDelivery(Store store) async {
    try {
      await _db.runTransaction((transaction) async {
        List<Map<String, dynamic>> writeQueue = [];

        for (var barang in store.muatan) {
          final String namaBarang = barang['name']?.toString() ?? '';
          final int qtyDiambil = (barang['qty'] is int) ? barang['qty'] as int : int.tryParse('${barang['qty']}') ?? 0;

          if (namaBarang.isEmpty || qtyDiambil <= 0) continue;

          final stockQuery = await _db.collection('stocks').where('name', isEqualTo: namaBarang).limit(1).get();

          if (stockQuery.docs.isNotEmpty) {
            final stockRef = stockQuery.docs.first.reference;
            final freshStockDoc = await transaction.get(stockRef);
            final freshStockData = freshStockDoc.data() as Map<String, dynamic>? ?? {};
            final int currentQty = freshStockData['quantity'] is int ? freshStockData['quantity'] as int : 0;

            int finalQty = currentQty - qtyDiambil;
            if (finalQty < 0) finalQty = 0;

            writeQueue.add({'ref': stockRef, 'quantity': finalQty});
          }
        }

        for (var action in writeQueue) {
          transaction.update(action['ref'], {
            'quantity': action['quantity'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final storeRef = _db.collection('stores').doc(store.id);
        transaction.update(storeRef, {
          'status': 'TERKIRIM',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStoreMuatan(String storeId, List<Map<String, dynamic>> newMuatan) async {
    await _db.collection('stores').doc(storeId).update({'muatan': newMuatan});
    notifyListeners();
  }

  Future<void> resetHarianSemuaToko() async {
    final snapshot = await _db.collection('stores').get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String statusValue = data['status']?.toString().toUpperCase() ?? 'PENDING';
      final String salesName = data['sales']?.toString() ?? 'SYAKUR';
      final List<dynamic> muatanList = data['muatan'] is List ? data['muatan'] as List : [];

      if (statusValue == 'TERKIRIM') {
        if (muatanList.isNotEmpty) {
          final historyRef = _db.collection('history_penjualan').doc();
          batch.set(historyRef, {
            'sales': salesName.trim().toUpperCase(),
            'muatan': muatanList,
            'timestamp': FieldValue.serverTimestamp(),
            'storeName': data['name'] ?? '',
          });
        }

        batch.update(doc.reference, {
          'status': 'PENDING', 
          'muatan': [], 
          'resetAt': FieldValue.serverTimestamp()
        });
      } else {
        batch.update(doc.reference, {
          'status': 'PENDING', 
          'resetAt': FieldValue.serverTimestamp()
        });
      }
    }

    batch.set(
      _db.collection('system_config').doc('sales_period'),
      {'last_reset_daily': Timestamp.now()},
      SetOptions(merge: true),
    );

    await batch.commit();
    _waktuResetHarianTerakhir = DateTime.now();
    notifyListeners();
  }

  Future<void> resetBulananSemuaPenjualan() async {
    try {
      final batch = _db.batch();
      
      batch.set(
        _db.collection('system_config').doc('sales_period'),
        {
          'last_reset_monthly': Timestamp.now(),
          'last_reset_daily': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _waktuResetBulananTerakhir = DateTime.now();
      _waktuResetHarianTerakhir = DateTime.now();
      notifyListeners();
      
    } catch (e) {
      print("Error reset bulanan: $e");
      rethrow;
    }
  }

  Future<void> addStore({required String name, required String address, required String sales}) async {
    await _db.collection('stores').add({
      'name': name.trim(),
      'address': address.trim(),
      'sales': sales.trim().toUpperCase(),
      'status': 'PENDING',
      'muatan': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStore(String storeId) async {
    await _db.collection('stores').doc(storeId).delete();
    notifyListeners();
  }

  Future<void> addStock({required String name, required int quantity, required String unit}) async {
    await _db.collection('stocks').add({
      'name': name.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStockQuantity(String stockId, int newQuantity) async {
    try {
      await _db.collection('stocks').doc(stockId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      print("Error update kuantitas stok: $e");
      rethrow;
    }
  }

  int getSalesMonthlyAchieved(String salesName) {
    int totalTerjual = 0;
    final sekarang = DateTime.now();

    // Hitung awal periode berjalan berdasarkan siklus tanggal 25
    DateTime awalPeriode;
    if (sekarang.day >= 25) {
      awalPeriode = DateTime(sekarang.year, sekarang.month, 25);
    } else {
      awalPeriode = DateTime(sekarang.year, sekarang.month - 1, 25);
    }

    // 1. Hitung dari Koleksi history_penjualan
    for (var record in _history) {
      if (record.sales.trim().toUpperCase() == salesName.trim().toUpperCase()) {
        if (record.timestamp.isAfter(awalPeriode) || record.timestamp.isAtSameMomentAs(awalPeriode)) {
          
          if (_waktuResetBulananTerakhir != null && record.timestamp.isBefore(_waktuResetBulananTerakhir!)) {
            continue;
          }

          for (var item in record.muatan) {
            final int qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0;
            totalTerjual += qty;
          }
        }
      }
    }
    
    // 2. Hitung dari Toko Aktif Berstatus TERKIRIM
    for (var store in _stores) {
      if (store.sales.trim().toUpperCase() == salesName.trim().toUpperCase() &&
          store.status.toUpperCase() == 'TERKIRIM') {
        
        DateTime waktuToko = store.createdAt ?? sekarang;

        if (waktuToko.isAfter(awalPeriode) || waktuToko.isAtSameMomentAs(awalPeriode)) {
          if (_waktuResetBulananTerakhir != null && store.createdAt != null && store.createdAt!.isBefore(_waktuResetBulananTerakhir!)) {
            continue;
          }

          for (var item in store.muatan) {
            final int qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0;
            totalTerjual += qty;
          }
        }
      }
    }
    return totalTerjual;
  }

  @override
  void dispose() {
    _stocksSub?.cancel();
    _storesSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}