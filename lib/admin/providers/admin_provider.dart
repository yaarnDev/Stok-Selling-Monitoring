import 'dart:async';
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
  final String sales;
  final List<dynamic> muatan;
  final DateTime timestamp;

  SalesHistory({required this.sales, required this.muatan, required this.timestamp});

  factory SalesHistory.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SalesHistory(
      sales: data['sales']?.toString() ?? '',
      muatan: data['muatan'] is List ? data['muatan'] as List : [],
      timestamp: (data['timestamp'] is Timestamp) ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Stock> _stocks = [];
  final List<Store> _stores = [];
  final List<SalesHistory> _history = [];

  // PISAHKAN DUA KUNCI BARU:
  DateTime? _waktuResetHarianTerakhir;
  DateTime? _waktuResetBulananTerakhir;

  final Map<String, int> salesTargets = {
    'SYAKUR': 20000,
    'FAISOL': 5000,
    'MULYADI': 5000,
    'LUAY': 5000,
  };

  StreamSubscription<QuerySnapshot>? _stocksSub;
  StreamSubscription<QuerySnapshot>? _storesSub;
  StreamSubscription<QuerySnapshot>? _historySub;

  AdminProvider();

  List<Stock> get stocks => List.unmodifiable(_stocks);
  List<Store> get stores => List.unmodifiable(_stores);

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
    final sekarang = DateTime.now();
    final awalBulan = DateTime(sekarang.year, sekarang.month, 1);

    // Ambil info penanda filter reset harian & bulanan dari Firebase secara real-time
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

      _db.collection('history_penjualan')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(awalBulan))
          .snapshots().listen((snap) {
        _history
          ..clear()
          ..addAll(snap.docs.map((d) => SalesHistory.fromDoc(d)));
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

  // === FIX LOGIKA 1: RESET HARIAN (HANYA MERISET DATA HARI INI KE CARD BAWAH) ===
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

    // Catat tanggal harian terakhir ke config Firebase
    batch.set(
      _db.collection('system_config').doc('sales_period'),
      {'last_reset_daily': Timestamp.now()},
      SetOptions(merge: true),
    );

    await batch.commit();
    _waktuResetHarianTerakhir = DateTime.now();
    notifyListeners();
  }

  // === FIX LOGIKA 2: RESET BULANAN (MURNI UNTUK CAPAIAN TARGET UTAMA ATAS) ===
  Future<void> resetBulananSemuaPenjualan() async {
    try {
      final batch = _db.batch();
      
      batch.set(
        _db.collection('system_config').doc('sales_period'),
        {
          'last_reset_monthly': Timestamp.now(),
          'last_reset_daily': Timestamp.now(), // Saat reset bulanan, otomatis harian juga bersih
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

  // === FIX LOGIKA 3: RUMUS HITUNG BULANAN (TIDAK AKAN IKUT TERPOTONG RESET HARIAN) ===
  int getSalesMonthlyAchieved(String salesName) {
    int totalTerjual = 0;
    final sekarang = DateTime.now();

    // 1. Ambil data akumulasi dari backup history penjualan bulanan
    for (var record in _history) {
      if (record.sales.trim().toUpperCase() == salesName.trim().toUpperCase()) {
        if (record.timestamp.month == sekarang.month && record.timestamp.year == sekarang.year) {
          
          // KUNCI AMAN: History hanya dibuang kalau dia dibuat SEBELUM tombol reset bulanan ditekan
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
    
    // 2. Tambahkan data toko aktif hari ini yang statusnya TERKIRIM
    for (var store in _stores) {
      if (store.sales.trim().toUpperCase() == salesName.trim().toUpperCase() &&
          store.status.toUpperCase() == 'TERKIRIM') {
        
        // KUNCI AMAN: Toko hari ini juga hanya dibuang kalau dia dibuat sebelum tombol bulanan ditekan
        if (_waktuResetBulananTerakhir != null && store.createdAt != null && store.createdAt!.isBefore(_waktuResetBulananTerakhir!)) {
          continue;
        }

        for (var item in store.muatan) {
          final int qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 0;
          totalTerjual += qty;
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